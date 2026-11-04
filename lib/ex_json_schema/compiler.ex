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
      {:ok, compiled}
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

  defp fetch_location(%Resource{locations: locations}, fragment) when fragment in [nil, ""],
    do: Map.fetch(locations, "")

  defp fetch_location(%Resource{locations: locations}, "/" <> _rest = pointer),
    do: Map.fetch(locations, pointer)

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

  defp reference_error(reference, base_uri) do
    %ReferenceError{
      reference: reference,
      base_uri: base_uri,
      message: "schema reference #{reference} was not found from #{base_uri}"
    }
  end
end
