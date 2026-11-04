defmodule ExJsonSchema.Compiler.Scanner do
  @moduledoc false

  # Walks a schema document to discover resources, anchors, references,
  # locations, and per-location evaluation plans.

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.Compiler.Dialect
  alias ExJsonSchema.Compiler.EvaluationPlan
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Pointer
  alias ExJsonSchema.Compiler.Reference
  alias ExJsonSchema.Compiler.Registry
  alias ExJsonSchema.Compiler.Resource
  alias ExJsonSchema.Compiler.URI, as: SchemaURI

  @single_schema_keywords ~w[
    additionalItems additionalProperties contains contentSchema else if items not
    propertyNames then unevaluatedItems unevaluatedProperties
  ]
  @schema_array_keywords ~w[allOf anyOf oneOf prefixItems]
  @schema_map_keywords ~w[$defs definitions dependentSchemas patternProperties properties]

  @type result :: %{
          resources: %{String.t() => Resource.t()},
          aliases: %{String.t() => String.t()},
          entrypoint: Location.t()
        }

  @spec scan(ExJsonSchema.data(), String.t() | nil, Dialect.t(), %{String.t() => Dialect.t()}) ::
          {:ok, result()} | {:error, CompileError.t()}
  def scan(schema, retrieval_uri, inherited_dialect, custom_dialects \\ %{})

  def scan(schema, retrieval_uri, inherited_dialect, custom_dialects)
      when (is_map(schema) or is_boolean(schema)) and
             (is_binary(retrieval_uri) or is_nil(retrieval_uri)) do
    retrieval_uri = normalize_retrieval_uri(retrieval_uri)

    with {:ok, dialect} <- dialect(schema, inherited_dialect, custom_dialects),
         {:ok, identifier_uri, legacy_anchor} <-
           resource_identifier(schema, retrieval_uri, dialect),
         canonical_uri <-
           SchemaURI.without_fragment(identifier_uri || retrieval_uri),
         resource <- new_resource(schema, retrieval_uri, canonical_uri, dialect),
         state <-
           put_resource(
             %{
               resources: %{},
               aliases: %{},
               custom_dialects: custom_dialects,
               evaluation_plan_cache: %{}
             },
             resource
           ),
         paths <- [{canonical_uri, []}],
         {:ok, state} <-
           walk(schema, dialect, canonical_uri, canonical_uri, paths, legacy_anchor, state) do
      {:ok,
       state
       |> Map.delete(:custom_dialects)
       |> Map.delete(:evaluation_plan_cache)
       |> Map.put(:entrypoint, Location.root(canonical_uri))}
    end
  end

  def scan(schema, _retrieval_uri, _dialect, _custom_dialects) do
    {:error,
     %CompileError{
       reason: :invalid_schema,
       message: "a JSON Schema must be an object or boolean",
       details: schema
     }}
  end

  @spec index_reference_target(
          result(),
          String.t(),
          String.t(),
          %{String.t() => Dialect.t()}
        ) ::
          {:ok, result(), [{String.t(), String.t()}]}
          | :not_schema
          | {:error, CompileError.t()}
  def index_reference_target(graph, resource_uri, pointer, custom_dialects \\ %{})

  def index_reference_target(graph, resource_uri, "/" <> _rest = pointer, custom_dialects) do
    canonical_uri = Map.get(graph.aliases, resource_uri, resource_uri)

    with {:ok,
          %Resource{
            schema: resource_schema,
            locations: locations
          } = resource} <-
           Map.fetch(graph.resources, canonical_uri) do
      if Map.has_key?(locations, pointer) do
        {:ok, graph, []}
      else
        index_reference_target(
          graph,
          resource,
          canonical_uri,
          pointer,
          resource_schema,
          custom_dialects
        )
      end
    else
      :error -> :not_schema
    end
  end

  def index_reference_target(_graph, _resource_uri, _pointer, _custom_dialects),
    do: :not_schema

  defp index_reference_target(
         graph,
         resource,
         canonical_uri,
         pointer,
         resource_schema,
         custom_dialects
       ) do
    with {:ok, segments} <- Pointer.decode(pointer),
         {:ok, schema, normalized_segments} <-
           fetch_pointer(resource_schema, segments),
         true <- is_map(schema) or is_boolean(schema) do
      if indexed?(resource, normalized_segments) do
        {:ok, graph, []}
      else
        walk_reference_target(
          graph,
          canonical_uri,
          schema,
          normalized_segments,
          resource,
          custom_dialects
        )
      end
    else
      _not_a_schema -> :not_schema
    end
  end

  defp walk_reference_target(
         graph,
         canonical_uri,
         schema,
         normalized_segments,
         resource,
         custom_dialects
       ) do
    with {:ok, location, ancestor_length, target_base_uri} <-
           nearest_indexed_location(resource, normalized_segments),
         %Location{resource: current_resource, pointer: current_pointer} <- location,
         %Resource{dialect: dialect} <- Map.fetch!(graph.resources, current_resource) do
      remainder = Enum.drop(normalized_segments, ancestor_length)
      current_path = current_pointer ++ remainder

      paths =
        if current_resource == canonical_uri do
          [{canonical_uri, normalized_segments}]
        else
          [
            {canonical_uri, normalized_segments},
            {current_resource, current_path}
          ]
        end

      state =
        graph
        |> Map.put(:custom_dialects, custom_dialects)
        |> Map.put(:evaluation_plan_cache, %{})
        |> Map.put(:discovered_references, [])

      case walk(schema, dialect, target_base_uri, current_resource, paths, nil, state) do
        {:ok, %{discovered_references: references} = state} ->
          graph =
            Map.drop(state, [
              :custom_dialects,
              :evaluation_plan_cache,
              :discovered_references
            ])

          {:ok, graph, Enum.reverse(references)}

        {:error, error} ->
          {:error, error}
      end
    else
      _missing_ancestor -> :not_schema
    end
  end

  defp fetch_pointer(value, segments), do: fetch_pointer(value, segments, [])

  defp fetch_pointer(value, [], normalized), do: {:ok, value, Enum.reverse(normalized)}

  defp fetch_pointer(value, [segment | rest], normalized) when is_map(value) do
    case Map.fetch(value, segment) do
      {:ok, child} -> fetch_pointer(child, rest, [segment | normalized])
      :error -> :error
    end
  end

  defp fetch_pointer(value, [segment | rest], normalized) when is_list(value) do
    with {:ok, index} <- array_index(segment),
         {:ok, child} <- Enum.fetch(value, index) do
      fetch_pointer(child, rest, [index | normalized])
    else
      _invalid_or_missing_index -> :error
    end
  end

  defp fetch_pointer(_value, _segments, _normalized), do: :error

  defp array_index("0"), do: {:ok, 0}

  defp array_index(<<first, rest::binary>> = segment) when first in ?1..?9 do
    if rest == "" or Regex.match?(~r/\A[0-9]+\z/, rest) do
      {:ok, String.to_integer(segment)}
    else
      :error
    end
  end

  defp array_index(_segment), do: :error

  defp indexed?(%Resource{location_index: location_index}, segments),
    do: Map.has_key?(location_index, segments)

  defp nearest_indexed_location(
         %Resource{
           location_index: location_index,
           base_uri_overrides: base_uri_overrides
         },
         segments
       ) do
    length = length(segments)

    length..0//-1
    |> Enum.find_value(fn prefix_length ->
      prefix = Enum.take(segments, prefix_length)

      case Map.fetch(location_index, prefix) do
        {:ok, %Location{resource: resource_uri} = location} ->
          base_uri = Map.get(base_uri_overrides, prefix, resource_uri)
          {:ok, location, prefix_length, base_uri}

        :error ->
          nil
      end
    end)
    |> case do
      nil -> :error
      result -> result
    end
  end

  defp walk(
         schema,
         inherited_dialect,
         base_uri,
         current_resource,
         paths,
         inherited_anchor,
         state
       )

  defp walk(
         schema,
         inherited_dialect,
         base_uri,
         current_resource,
         paths,
         inherited_anchor,
         state
       )
       when is_map(schema) do
    with {:ok, dialect} <- dialect(schema, inherited_dialect, state.custom_dialects),
         {:ok, identifier_uri, identifier_anchor} <-
           resource_identifier(schema, base_uri, dialect),
         {:ok, resource_uri, paths, state} <-
           maybe_enter_resource(
             schema,
             dialect,
             identifier_uri,
             identifier_anchor,
             current_resource,
             paths,
             state
           ) do
      location = %Location{resource: resource_uri, pointer: current_pointer(paths, resource_uri)}
      base_uri = identifier_uri || base_uri

      state =
        state
        |> index_schema(paths, location, schema, base_uri)
        |> put_anchor(resource_uri, inherited_anchor, location, false)
        |> put_anchor(resource_uri, identifier_anchor, location, false)
        |> put_anchor(resource_uri, Map.get(schema, "$anchor"), location, false)
        |> put_anchor(resource_uri, Map.get(schema, "$dynamicAnchor"), location, true)

      state = put_references(state, resource_uri, location, base_uri, dialect, schema)

      Enum.reduce_while(children(schema), {:ok, state}, fn {relative_path, child}, {:ok, state} ->
        child_paths =
          Enum.map(paths, fn {uri, pointer} -> {uri, pointer ++ relative_path} end)

        case walk(
               child,
               dialect,
               base_uri,
               resource_uri,
               child_paths,
               nil,
               state
             ) do
          {:ok, state} -> {:cont, {:ok, state}}
          {:error, error} -> {:halt, {:error, error}}
        end
      end)
    end
  end

  defp walk(
         schema,
         _dialect,
         base_uri,
         current_resource,
         paths,
         inherited_anchor,
         state
       )
       when is_boolean(schema) do
    location = %Location{resource: current_resource, pointer: current_pointer(paths, current_resource)}

    state =
      state
      |> index_schema(paths, location, schema, base_uri)
      |> put_anchor(current_resource, inherited_anchor, location, false)

    {:ok, state}
  end

  defp maybe_enter_resource(
         schema,
         dialect,
         identifier_uri,
         identifier_anchor,
         current_resource,
         paths,
         state
       ) do
    resource_uri = identifier_uri && SchemaURI.without_fragment(identifier_uri)

    if resource_uri && is_nil(identifier_anchor) && resource_uri != current_resource do
      {origin_resource, origin_pointer} = hd(paths)

      %Resource{origin_location: origin_location} =
        resource =
        schema
        |> new_resource(resource_uri, resource_uri, dialect)
        |> Map.put(:origin_location, %Location{
          resource: origin_resource,
          pointer: origin_pointer
        })

      case Map.fetch(state.resources, resource_uri) do
        {:ok, %Resource{schema: ^schema, origin_location: ^origin_location}} ->
          {:ok, resource_uri, paths ++ [{resource_uri, []}], state}

        {:ok, _existing_resource} ->
          {:error,
           %CompileError{
             reason: :invalid_schema,
             uri: resource_uri,
             message: "duplicate schema resource identifier: #{resource_uri}",
             details: %{identifier: resource_uri}
           }}

        :error ->
          state = put_resource(state, resource)
          {:ok, resource_uri, paths ++ [{resource_uri, []}], state}
      end
    else
      {:ok, current_resource, paths, state}
    end
  end

  defp dialect(schema, inherited, _custom_dialects) when is_boolean(schema),
    do: {:ok, inherited}

  defp dialect(schema, inherited, custom_dialects) do
    case Map.fetch(schema, "$schema") do
      :error ->
        {:ok, inherited}

      {:ok, uri} when is_binary(uri) ->
        case Registry.dialect(uri) do
          {:ok, dialect} ->
            {:ok, dialect}

          :error ->
            case Map.fetch(custom_dialects, normalize_retrieval_uri(uri)) do
              {:ok, dialect} ->
                {:ok, dialect}

              :error ->
                {:error,
                 %CompileError{
                   reason: :unsupported_dialect,
                   uri: uri,
                   message: "unsupported JSON Schema dialect: #{uri}",
                   details: %{dialect: uri}
                 }}
            end
        end

      {:ok, value} ->
        {:error,
         %CompileError{
           reason: :invalid_schema,
           message: "$schema must be a string",
           details: %{"$schema" => value}
         }}
    end
  end

  defp resource_identifier(schema, base_uri, %Dialect{version: version} = dialect)
       when is_map(schema) do
    if version in [4, 6, 7] and is_binary(schema["$ref"]) do
      {:ok, nil, nil}
    else
      do_resource_identifier(schema, base_uri, dialect)
    end
  end

  defp resource_identifier(_schema, _base_uri, _dialect), do: {:ok, nil, nil}

  defp do_resource_identifier(schema, base_uri, %Dialect{version: version}) do
    keyword = if version == 4, do: "id", else: "$id"

    case Map.get(schema, keyword) do
      nil ->
        {:ok, nil, nil}

      identifier when is_binary(identifier) ->
        case SchemaURI.resolve(base_uri, identifier) do
          {:ok, resolved} ->
            with {:ok, _resource, fragment} <- SchemaURI.split_fragment(resolved) do
              anchor = if fragment in [nil, ""], do: nil, else: fragment
              {:ok, resolved, anchor}
            else
              :error -> invalid_identifier(keyword, identifier)
            end

          :error ->
            invalid_identifier(keyword, identifier)
        end

      value ->
        invalid_identifier(keyword, value)
    end
  end

  defp invalid_identifier(keyword, value) do
    {:error,
     %CompileError{
       reason: :invalid_schema,
       message: "#{keyword} must be a valid URI reference",
       details: %{keyword => value}
     }}
  end

  defp new_resource(
         schema,
         retrieval_uri,
         canonical_uri,
         %Dialect{vocabularies: vocabularies} = dialect
       ) do
    aliases =
      [retrieval_uri, canonical_uri]
      |> Enum.reject(&(&1 in [nil, ""]))
      |> MapSet.new()

    %Resource{
      schema: schema,
      retrieval_uri: retrieval_uri || "",
      canonical_uri: canonical_uri || "",
      aliases: aliases,
      origin_location: Location.root(canonical_uri),
      dialect: dialect,
      vocabularies: vocabularies
    }
  end

  defp put_resource(
         state,
         %Resource{aliases: resource_aliases, canonical_uri: canonical_uri} = resource
       ) do
    aliases =
      Enum.reduce(resource_aliases, state.aliases, fn alias_uri, aliases ->
        Map.put(aliases, alias_uri, canonical_uri)
      end)

    %{
      state
      | resources: Map.put(state.resources, canonical_uri, resource),
        aliases: aliases
    }
  end

  defp index_schema(
         state,
         paths,
         %Location{resource: location_resource, pointer: location_pointer} = location,
         schema,
         base_uri
       ) do
    %Resource{
      dialect: %Dialect{id: dialect_id} = dialect,
      vocabularies: vocabularies
    } = Map.fetch!(state.resources, location_resource)

    cache_key = {dialect_id, vocabularies, schema}

    {plan, state} =
      case Map.fetch(state.evaluation_plan_cache, cache_key) do
        {:ok, plan} ->
          {plan, state}

        :error ->
          plan = EvaluationPlan.new(schema, dialect, vocabularies)
          {plan, put_in(state.evaluation_plan_cache[cache_key], plan)}
      end

    Enum.reduce(paths, state, fn {resource_uri, segments}, state ->
      pointer = Pointer.encode(segments)

      update_resource(state, resource_uri, fn
        %Resource{
          locations: locations,
          location_index: location_index,
          base_uri_overrides: base_uri_overrides,
          evaluation_plans: evaluation_plans
        } = resource ->
          base_uri_overrides =
            if base_uri == location_resource do
              base_uri_overrides
            else
              Map.put(base_uri_overrides, segments, base_uri)
            end

          resource = %Resource{
            resource
            | locations: Map.put(locations, pointer, location),
              location_index: Map.put(location_index, segments, location),
              base_uri_overrides: base_uri_overrides
          }

          if resource_uri == location_resource do
            %Resource{
              resource
              | evaluation_plans: Map.put(evaluation_plans, location_pointer, plan)
            }
          else
            resource
          end
      end)
    end)
  end

  defp put_anchor(state, _resource_uri, anchor, _location, _dynamic?)
       when anchor in [nil, ""],
       do: state

  defp put_anchor(state, resource_uri, anchor, location, dynamic?) when is_binary(anchor) do
    update_resource(state, resource_uri, fn
      %Resource{
        anchors: anchors,
        dynamic_anchors: resource_dynamic_anchors
      } = resource ->
        dynamic_anchors =
          if dynamic?,
            do: Map.put(resource_dynamic_anchors, anchor, location),
            else: resource_dynamic_anchors

        %Resource{
          resource
          | anchors: Map.put(anchors, anchor, location),
            dynamic_anchors: dynamic_anchors
        }
    end)
  end

  defp update_resource(state, uri, update) do
    %{state | resources: Map.update!(state.resources, uri, update)}
  end

  defp put_references(
         state,
         resource_uri,
         location,
         base_uri,
         %Dialect{version: version},
         schema
       ) do
    references =
      [
        {:ref, "$ref", Map.get(schema, "$ref")},
        {:dynamic_ref, "$dynamicRef", Map.get(schema, "$dynamicRef")}
      ]
      |> Enum.filter(fn
        {:dynamic_ref, _keyword, value} ->
          version == :"2020-12" and is_binary(value)

        {:ref, _keyword, value} ->
          is_binary(value)
      end)

    Enum.reduce(references, state, fn {kind, keyword, value}, state ->
      %Location{pointer: source_pointer} = source = Location.child(location, keyword)
      key = Pointer.encode(source_pointer)

      reference = %Reference{
        kind: kind,
        value: value,
        base_uri: base_uri,
        source: source
      }

      %Resource{references: existing_references} =
        Map.fetch!(state.resources, resource_uri)

      state =
        update_resource(state, resource_uri, fn
          %Resource{references: resource_references} = resource ->
            %Resource{resource | references: Map.put(resource_references, key, reference)}
        end)

      if Map.has_key?(existing_references, key) do
        state
      else
        case state do
          %{discovered_references: discovered_references} ->
            %{state | discovered_references: [{resource_uri, key} | discovered_references]}

          _state_without_discovery_tracking ->
            state
        end
      end
    end)
  end

  defp current_pointer(paths, resource_uri) do
    paths
    |> Enum.reverse()
    |> Enum.find_value([], fn
      {^resource_uri, pointer} -> pointer
      _path -> nil
    end)
  end

  defp children(schema) do
    Enum.flat_map(schema, fn {keyword, value} ->
      children_for_keyword(keyword, value)
    end)
  end

  defp children_for_keyword(keyword, child)
       when keyword in @single_schema_keywords and (is_map(child) or is_boolean(child)),
       do: [{[keyword], child}]

  defp children_for_keyword(keyword, children)
       when keyword in @schema_array_keywords and is_list(children) do
    for {child, index} <- Enum.with_index(children),
        is_map(child) or is_boolean(child),
        do: {[keyword, index], child}
  end

  defp children_for_keyword("items", children) when is_list(children) do
    for {child, index} <- Enum.with_index(children),
        is_map(child) or is_boolean(child),
        do: {["items", index], child}
  end

  defp children_for_keyword(keyword, children)
       when keyword in @schema_map_keywords and is_map(children) do
    for {name, child} <- children,
        is_map(child) or is_boolean(child),
        do: {[keyword, name], child}
  end

  defp children_for_keyword("dependencies", children) when is_map(children) do
    for {name, child} <- children,
        is_map(child) or is_boolean(child),
        do: {["dependencies", name], child}
  end

  defp children_for_keyword(_keyword, _value), do: []

  defp normalize_retrieval_uri(nil), do: ""
  defp normalize_retrieval_uri(uri), do: SchemaURI.without_fragment(uri)
end
