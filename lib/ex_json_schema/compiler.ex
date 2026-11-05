defmodule ExJsonSchema.Compiler do
  @moduledoc false

  # Coordinates schema loading, reference resolution, meta-schema validation,
  # and creation of reusable compiled handles.

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.CompiledSchema
  alias ExJsonSchema.ReferenceError
  alias ExJsonSchema.Compiler.Dialect
  alias ExJsonSchema.Compiler.EvaluationPlan
  alias ExJsonSchema.Compiler.Loader
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Options
  alias ExJsonSchema.Compiler.Pointer
  alias ExJsonSchema.Compiler.Resource
  alias ExJsonSchema.Compiler.URI, as: SchemaURI
  alias ExJsonSchema.Evaluator

  @spec compile(ExJsonSchema.data(), keyword()) ::
          {:ok, CompiledSchema.t()} | {:error, CompileError.t()}
  def compile(schema, options \\ []) do
    defaults = Options.application_defaults()

    with :ok <- validate_decoded_schema(schema),
         {:ok, options} <- Options.parse(options, defaults) do
      compile_validated(schema, options)
    end
  end

  @spec compile!(ExJsonSchema.data(), keyword()) :: CompiledSchema.t() | no_return()
  def compile!(schema, options \\ []) do
    case compile(schema, options) do
      {:ok, compiled} -> compiled
      {:error, error} -> raise error
    end
  end

  @spec fetch_schema(CompiledSchema.t(), String.t()) ::
          {:ok, CompiledSchema.t()} | {:error, ReferenceError.t()}
  def fetch_schema(compiled, reference) when is_binary(reference) do
    reference = if String.starts_with?(reference, "/"), do: "#" <> reference, else: reference
    %Location{resource: base_uri} = CompiledSchema.entrypoint(compiled)

    with {:ok, resolved} <- SchemaURI.resolve(base_uri, reference),
         {:ok, resource_uri, fragment} <- SchemaURI.split_fragment(resolved),
         {:ok, resource} <- fetch_resource(compiled, resource_uri),
         {:ok, location} <- fetch_location(resource, fragment) do
      {:ok, CompiledSchema.with_entrypoint(compiled, location)}
    else
      :error -> {:error, reference_error(reference, base_uri)}
    end
  end

  @spec fetch_schema!(CompiledSchema.t(), String.t()) :: CompiledSchema.t() | no_return()
  def fetch_schema!(compiled, reference) do
    case fetch_schema(compiled, reference) do
      {:ok, scoped} -> scoped
      {:error, error} -> raise error
    end
  end

  defp compile_validated(schema, options) do
    with {:ok, graph} <- Loader.load(schema, options),
         compiled <- build_compiled_schema(graph, options),
         :ok <- validate_graph(compiled, options) do
      {:ok, compact_runtime_dialects(compiled)}
    end
  end

  defp compile_with_options(schema, options) do
    with :ok <- validate_decoded_schema(schema) do
      compile_validated(schema, options)
    end
  end

  defp build_compiled_schema(
         graph,
         %Options{formats: formats, content_decoder: content_decoder}
       ) do
    CompiledSchema.new(
      resources: graph.resources,
      aliases: graph.aliases,
      entrypoint: graph.entrypoint,
      formats: formats,
      content_decoder: content_decoder,
      annotations?: annotations?(graph.resources),
      track_evaluated?: track_evaluated?(graph.resources)
    )
  end

  defp compact_runtime_dialects(compiled) do
    resources =
      compiled
      |> CompiledSchema.resources()
      |> Map.new(fn
        {uri,
         %Resource{
           dialect: dialect,
           location_index: location_index,
           evaluation_plans: evaluation_plans
         } = resource} ->
          {nodes, plan_table} =
            compact_nodes(location_index, evaluation_plans, uri)

          resource = %Resource{
            resource
            | retrieval_uri: "",
              aliases: MapSet.new(),
              dialect: Dialect.runtime(dialect),
              locations: %{},
              location_index: %{},
              base_uri_overrides: %{},
              evaluation_plans: %{},
              nodes: nodes,
              plan_table: plan_table
          }

          {uri, resource}
      end)

    CompiledSchema.with_resources(compiled, resources)
  end

  defp compact_nodes(location_index, evaluation_plans, resource_uri) do
    {nodes, {_plan_indexes, reversed_plans}} =
      Enum.map_reduce(
        location_index,
        {%{}, []},
        fn {pointer, location}, {plan_indexes, reversed_plans} ->
          location =
            case location do
              %Location{resource: ^resource_uri, pointer: ^pointer} -> nil
              %Location{} -> location
            end

          {plan_index, plan_indexes, reversed_plans} =
            intern_plan(
              Map.get(evaluation_plans, pointer),
              plan_indexes,
              reversed_plans
            )

          {{pointer, {location, plan_index}}, {plan_indexes, reversed_plans}}
        end
      )

    {Map.new(nodes), reversed_plans |> Enum.reverse() |> List.to_tuple()}
  end

  defp intern_plan(nil, indexes, reversed_plans),
    do: {nil, indexes, reversed_plans}

  defp intern_plan(%EvaluationPlan{} = plan, indexes, reversed_plans) do
    case Map.fetch(indexes, plan) do
      {:ok, index} ->
        {index, indexes, reversed_plans}

      :error ->
        index = map_size(indexes)
        {index, Map.put(indexes, plan, index), [plan | reversed_plans]}
    end
  end

  defp annotations?(resources) do
    Enum.any?(resources, fn {_uri, %Resource{evaluation_plans: plans}} ->
      Enum.any?(plans, fn {_pointer, %EvaluationPlan{annotations?: annotations?}} ->
        annotations?
      end)
    end)
  end

  defp track_evaluated?(resources) do
    Enum.any?(resources, fn {_uri, %Resource{evaluation_plans: plans}} ->
      Enum.any?(plans, fn {_pointer, %EvaluationPlan{unevaluated: unevaluated}} ->
        unevaluated != []
      end)
    end)
  end

  defp validate_graph(_compiled, %Options{validate_schema: false}), do: :ok

  defp validate_graph(compiled, %Options{validate_schema: true} = options) do
    compiled
    |> CompiledSchema.resources()
    |> Enum.reduce_while({:ok, %{}}, fn
      {_uri, %Resource{dialect: %Dialect{id: dialect_id, metaschema: metaschema}} = resource}, {:ok, metaschemas} ->
        case Map.fetch(metaschemas, dialect_id) do
          {:ok, metaschema} ->
            validate_resource(resource, metaschema, metaschemas)

          :error ->
            metaschema_options = %Options{
              options
              | retrieval_uri: nil,
                validate_schema: false
            }

            case compile_with_options(metaschema, metaschema_options) do
              {:ok, metaschema} ->
                validate_resource(
                  resource,
                  metaschema,
                  Map.put(metaschemas, dialect_id, metaschema)
                )

              {:error, error} ->
                {:halt, {:error, error}}
            end
        end
    end)
    |> case do
      {:ok, _metaschemas} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  defp validate_resource(
         %Resource{
           schema: schema,
           canonical_uri: canonical_uri,
           dialect: %Dialect{id: dialect_id}
         },
         metaschema,
         metaschemas
       ) do
    if Evaluator.valid?(schema, metaschema) do
      {:cont, {:ok, metaschemas}}
    else
      output = Evaluator.validate(schema, metaschema, output: :basic)

      {:halt,
       {:error,
        %CompileError{
          reason: :invalid_schema,
          uri: canonical_uri,
          details: %{dialect: dialect_id},
          output: output,
          message: "schema did not pass validation against its meta-schema"
        }}}
    end
  end

  defp validate_decoded_schema(schema) when is_boolean(schema), do: :ok

  defp validate_decoded_schema(schema) when is_map(schema) do
    case invalid_json_member(schema) do
      nil ->
        :ok

      invalid ->
        {:error,
         %CompileError{
           reason: :invalid_schema,
           details: invalid,
           message: "schema must be a decoded JSON value with string object keys"
         }}
    end
  end

  defp validate_decoded_schema(schema) do
    {:error,
     %CompileError{
       reason: :invalid_schema,
       details: schema,
       message: "a JSON Schema must be an object or boolean"
     }}
  end

  defp invalid_json_member(value) when is_map(value) do
    Enum.find_value(value, fn
      {key, _value} when not is_binary(key) -> {:invalid_key, key}
      {_key, child} -> invalid_json_member(child)
    end)
  end

  defp invalid_json_member(values) when is_list(values) do
    Enum.find_value(values, &invalid_json_member/1)
  end

  defp invalid_json_member(value)
       when is_nil(value) or is_boolean(value) or is_binary(value) or is_number(value),
       do: nil

  defp invalid_json_member(value), do: {:invalid_value, value}

  defp fetch_resource(compiled, uri) do
    canonical = Map.get(CompiledSchema.aliases(compiled), uri, uri)
    Map.fetch(CompiledSchema.resources(compiled), canonical)
  end

  defp fetch_location(%Resource{} = resource, fragment)
       when fragment in [nil, ""],
       do: Resource.fetch_location(resource, [])

  defp fetch_location(
         %Resource{schema: schema} = resource,
         "/" <> _rest = pointer
       ) do
    with {:ok, segments} <- Pointer.decode(pointer),
         {:ok, normalized} <- normalize_pointer(schema, segments) do
      Resource.fetch_location(resource, normalized)
    end
  end

  defp fetch_location(
         %Resource{anchors: anchors, dynamic_anchors: dynamic_anchors},
         anchor
       )
       when is_binary(anchor) do
    case Map.fetch(anchors, anchor) do
      {:ok, location} -> {:ok, location}
      :error -> Map.fetch(dynamic_anchors, anchor)
    end
  end

  defp normalize_pointer(schema, segments), do: normalize_pointer(schema, segments, [])

  defp normalize_pointer(_schema, [], normalized), do: {:ok, Enum.reverse(normalized)}

  defp normalize_pointer(schema, [segment | rest], normalized) when is_map(schema) do
    case Map.fetch(schema, segment) do
      {:ok, child} -> normalize_pointer(child, rest, [segment | normalized])
      :error -> :error
    end
  end

  defp normalize_pointer(schema, [segment | rest], normalized) when is_list(schema) do
    with {:ok, index} <- array_index(segment),
         {:ok, child} <- Enum.fetch(schema, index) do
      normalize_pointer(child, rest, [index | normalized])
    else
      _invalid_or_missing_index -> :error
    end
  end

  defp normalize_pointer(_schema, _segments, _normalized), do: :error

  defp array_index("0"), do: {:ok, 0}

  defp array_index(<<first, rest::binary>> = segment) when first in ?1..?9 do
    if rest == "" or Regex.match?(~r/\A[0-9]+\z/, rest) do
      {:ok, String.to_integer(segment)}
    else
      :error
    end
  end

  defp array_index(_segment), do: :error

  defp reference_error(reference, base_uri) do
    %ReferenceError{
      reference: reference,
      base_uri: base_uri,
      message: "schema reference #{reference} was not found from #{base_uri}"
    }
  end
end
