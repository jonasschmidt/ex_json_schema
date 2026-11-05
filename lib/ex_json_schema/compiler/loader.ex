defmodule ExJsonSchema.Compiler.Loader do
  @moduledoc false

  # Eagerly loads every statically reachable schema resource and merges each
  # scanned document into one immutable graph.

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.Compiler.Callbacks
  alias ExJsonSchema.Compiler.DialectResolver
  alias ExJsonSchema.Compiler.Options
  alias ExJsonSchema.Compiler.Reference
  alias ExJsonSchema.Compiler.Registry
  alias ExJsonSchema.Compiler.Resource
  alias ExJsonSchema.Compiler.Scanner
  alias ExJsonSchema.Compiler.URI, as: SchemaURI

  @spec load(ExJsonSchema.data(), Options.t()) ::
          {:ok, Scanner.result()} | {:error, CompileError.t()}
  def load(schema, %Options{} = options) do
    with {:ok, dialect, %Options{retrieval_uri: retrieval_uri} = options, custom_dialects} <-
           DialectResolver.resolve(schema, options),
         {:ok, graph} <-
           Scanner.scan(schema, retrieval_uri, dialect, custom_dialects) do
      state = %{
        graph: graph,
        queued: MapSet.new(),
        queue: :queue.new(),
        blocked: MapSet.new(),
        blocked_resources: %{},
        blocked_fragments: MapSet.new(),
        fragments_changed?: false,
        options: options,
        custom_dialects: custom_dialects
      }

      state
      |> enqueue_references(graph.resources)
      |> drain_queue()
    end
  end

  defp drain_queue(%{queue: queue} = state) do
    case :queue.out(queue) do
      {:empty, _queue} ->
        continue_blocked(state)

      {{:value, reference_key}, queue} ->
        state = %{
          state
          | queue: queue,
            queued: MapSet.delete(state.queued, reference_key)
        }

        case resolve_reference(state, reference_key) do
          {:ok, state} -> drain_queue(state)
          {:error, error} -> {:error, error}
        end
    end
  end

  @dialyzer {:nowarn_function, drain_queue: 1}

  defp enqueue_references(state, resources) do
    Enum.reduce(resources, state, fn
      {resource_uri, %Resource{references: references}}, state ->
        Enum.reduce(references, state, fn {pointer, _reference}, state ->
          enqueue_reference(state, {resource_uri, pointer})
        end)
    end)
  end

  defp enqueue_reference_keys(state, reference_keys) do
    Enum.reduce(reference_keys, state, &enqueue_reference(&2, &1))
  end

  defp enqueue_reference(state, reference_key) do
    if enqueue_reference?(state, reference_key) do
      %{
        state
        | queue: :queue.in(reference_key, state.queue),
          queued: MapSet.put(state.queued, reference_key)
      }
    else
      state
    end
  end

  defp enqueue_reference?(state, {resource_uri, pointer} = reference_key) do
    %Resource{references: references} = Map.fetch!(state.graph.resources, resource_uri)
    %Reference{target: target} = Map.fetch!(references, pointer)

    is_nil(target) and not MapSet.member?(state.queued, reference_key) and
      not MapSet.member?(state.blocked, reference_key)
  end

  defp resolve_reference(state, {source_uri, pointer} = reference_key) do
    %Resource{dialect: dialect, references: references} =
      Map.fetch!(state.graph.resources, source_uri)

    %Reference{base_uri: base_uri, value: value, target: target} =
      reference = Map.fetch!(references, pointer)

    if target do
      {:ok, state}
    else
      with {:ok, resolved} <- SchemaURI.resolve(base_uri, value),
           {:ok, target_uri, fragment} <- SchemaURI.split_fragment(resolved) do
        case fetch_resource(state.graph, target_uri) do
          {:ok, canonical_uri, resource} ->
            resolve_reference_target(
              state,
              reference_key,
              reference,
              canonical_uri,
              resource,
              fragment
            )

          :error ->
            {:ok, block_resource(state, target_uri, dialect, reference_key)}
        end
      else
        :error -> invalid_reference(reference)
      end
    end
  end

  defp resolve_reference_target(
         state,
         reference_key,
         reference,
         canonical_uri,
         resource,
         fragment
       ) do
    case fetch_location(resource, fragment) do
      {:ok, target} ->
        {:ok, put_resolved_reference(state, reference_key, reference, target, fragment)}

      :error ->
        resolve_missing_target(
          state,
          reference_key,
          reference,
          canonical_uri,
          fragment
        )
    end
  end

  defp resolve_missing_target(
         state,
         reference_key,
         reference,
         canonical_uri,
         "/" <> _rest = pointer
       ) do
    case Scanner.index_reference_target(
           state.graph,
           canonical_uri,
           pointer,
           state.custom_dialects
         ) do
      {:ok, graph, discovered_references} ->
        previous_graph = state.graph

        state =
          %{state | graph: graph, fragments_changed?: true}
          |> unblock_new_resources(previous_graph, graph)
          |> enqueue_reference_keys(discovered_references)

        {:ok, _canonical_uri, resource} = fetch_resource(state.graph, canonical_uri)

        case fetch_location(resource, pointer) do
          {:ok, target} ->
            {:ok,
             put_resolved_reference(
               state,
               reference_key,
               reference,
               target,
               pointer
             )}

          :error ->
            invalid_reference(reference)
        end

      :not_schema ->
        invalid_reference(reference)

      {:error, error} ->
        {:error, error}
    end
  end

  defp resolve_missing_target(state, reference_key, _reference, _canonical_uri, _fragment) do
    {:ok, block_fragment(state, reference_key)}
  end

  defp put_resolved_reference(
         state,
         {source_uri, pointer},
         %Reference{kind: kind} = reference,
         target,
         fragment
       ) do
    dynamic_anchor =
      if kind == :dynamic_ref and is_binary(fragment) and
           not String.starts_with?(fragment, "/") do
        fragment
      end

    resolved_reference = %Reference{
      reference
      | target: target,
        dynamic_anchor: dynamic_anchor
    }

    graph = state.graph

    graph =
      update_in(graph.resources[source_uri], fn
        %Resource{references: references} = resource ->
          %Resource{
            resource
            | references: Map.put(references, pointer, resolved_reference)
          }
      end)

    %{state | graph: graph}
  end

  defp block_resource(state, uri, dialect, reference_key) do
    blocked_resources =
      Map.update(
        state.blocked_resources,
        uri,
        {dialect, MapSet.new([reference_key])},
        fn {existing_dialect, references} ->
          {existing_dialect, MapSet.put(references, reference_key)}
        end
      )

    %{
      state
      | blocked: MapSet.put(state.blocked, reference_key),
        blocked_resources: blocked_resources
    }
  end

  defp block_fragment(state, reference_key) do
    %{
      state
      | blocked: MapSet.put(state.blocked, reference_key),
        blocked_fragments: MapSet.put(state.blocked_fragments, reference_key)
    }
  end

  defp continue_blocked(state) do
    state =
      if state.fragments_changed? do
        state
        |> Map.put(:fragments_changed?, false)
        |> unblock_available_fragments()
      else
        state
      end

    cond do
      not :queue.is_empty(state.queue) ->
        drain_queue(state)

      map_size(state.blocked_resources) > 0 ->
        load_next_resource(state)

      MapSet.size(state.blocked_fragments) > 0 ->
        state.blocked_fragments
        |> Enum.min()
        |> invalid_reference(state)

      true ->
        {:ok, state.graph}
    end
  end

  defp unblock_available_fragments(state) do
    Enum.reduce(state.blocked_fragments, state, fn reference_key, state ->
      if reference_target_available?(state, reference_key) do
        state
        |> remove_blocked_fragment(reference_key)
        |> enqueue_reference(reference_key)
      else
        state
      end
    end)
  end

  defp reference_target_available?(state, {source_uri, pointer}) do
    %Resource{references: references} = Map.fetch!(state.graph.resources, source_uri)
    %Reference{base_uri: base_uri, value: value} = Map.fetch!(references, pointer)

    with {:ok, resolved} <- SchemaURI.resolve(base_uri, value),
         {:ok, target_uri, fragment} <- SchemaURI.split_fragment(resolved),
         {:ok, _canonical_uri, resource} <- fetch_resource(state.graph, target_uri),
         {:ok, _location} <- fetch_location(resource, fragment) do
      true
    else
      _unavailable -> false
    end
  end

  defp remove_blocked_resource(state, uri, references) do
    %{
      state
      | blocked: MapSet.difference(state.blocked, references),
        blocked_resources: Map.delete(state.blocked_resources, uri)
    }
  end

  defp unblock_new_resources(state, previous_graph, graph) do
    available_uris =
      Enum.reduce(graph.aliases, [], fn {uri, canonical_uri}, uris ->
        case Map.fetch(previous_graph.aliases, uri) do
          {:ok, ^canonical_uri} -> uris
          _new_or_changed_alias -> [uri | uris]
        end
      end)

    unblock_resource_uris(state, available_uris)
  end

  defp unblock_resource_uris(state, uris) do
    Enum.reduce(uris, state, fn uri, state ->
      case Map.pop(state.blocked_resources, uri) do
        {nil, _blocked_resources} ->
          state

        {{_dialect, references}, blocked_resources} ->
          %{
            state
            | blocked: MapSet.difference(state.blocked, references),
              blocked_resources: blocked_resources
          }
          |> enqueue_reference_keys(references)
      end
    end)
  end

  defp remove_blocked_fragment(state, reference_key) do
    %{
      state
      | blocked: MapSet.delete(state.blocked, reference_key),
        blocked_fragments: MapSet.delete(state.blocked_fragments, reference_key)
    }
  end

  defp load_next_resource(state) do
    {uri, {dialect, references}} = Enum.min_by(state.blocked_resources, &elem(&1, 0))

    state = remove_blocked_resource(state, uri, references)

    with {:ok, schema} <- load_schema(uri, state.options),
         {:ok, scanned} <-
           Scanner.scan(schema, uri, dialect, state.custom_dialects),
         {:ok, graph} <- merge_graphs(state.graph, scanned) do
      %{state | graph: graph}
      |> unblock_resource_uris(Map.keys(scanned.aliases))
      |> enqueue_references(scanned.resources)
      |> enqueue_reference_keys(references)
      |> drain_queue()
    end
  end

  defp fetch_resource(graph, uri) do
    canonical_uri = Map.get(graph.aliases, uri, uri)

    case Map.fetch(graph.resources, canonical_uri) do
      {:ok, resource} -> {:ok, canonical_uri, resource}
      :error -> :error
    end
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

  defp invalid_reference({source_uri, pointer}, state) do
    %Resource{references: references} = Map.fetch!(state.graph.resources, source_uri)
    reference = Map.fetch!(references, pointer)
    invalid_reference(reference)
  end

  defp invalid_reference(%Reference{base_uri: base_uri, value: value, source: source}) do
    {:error,
     %CompileError{
       reason: :invalid_reference,
       uri: base_uri,
       details: %{
         reference: value,
         source: source
       },
       message: "schema reference could not be resolved: #{value}"
     }}
  end

  defp load_schema(uri, %Options{resources: resources, resolver: resolver}) do
    normalized_resources =
      Map.new(resources, fn {resource_uri, schema} ->
        {SchemaURI.without_fragment(resource_uri), schema}
      end)

    case Map.fetch(normalized_resources, uri) do
      {:ok, schema} ->
        {:ok, schema}

      :error ->
        case Registry.meta_schema(uri) do
          {:ok, schema} -> {:ok, schema}
          :error -> load_with_resolver(resolver, uri)
        end
    end
  end

  defp load_with_resolver(nil, uri) do
    {:error,
     %CompileError{
       reason: :invalid_reference,
       uri: uri,
       details: %{reference: uri, reason: :resolver_not_configured},
       message: "schema resource could not be resolved: #{uri}"
     }}
  end

  defp load_with_resolver(resolver, uri), do: Callbacks.resolve(resolver, uri)

  defp merge_graphs(left, right) do
    with {:ok, resources} <- merge_resources(left.resources, right.resources),
         {:ok, aliases} <- merge_aliases(left.aliases, right.aliases) do
      {:ok, %{left | resources: resources, aliases: aliases}}
    end
  end

  defp merge_resources(left, right) do
    Enum.reduce_while(right, {:ok, left}, fn {uri, resource}, {:ok, resources} ->
      case Map.fetch(resources, uri) do
        :error ->
          {:cont, {:ok, Map.put(resources, uri, resource)}}

        {:ok, ^resource} ->
          {:cont, {:ok, resources}}

        {:ok, _different} ->
          {:halt, duplicate_resource(uri)}
      end
    end)
  end

  defp merge_aliases(left, right) do
    Enum.reduce_while(right, {:ok, left}, fn {alias_uri, canonical}, {:ok, aliases} ->
      case Map.fetch(aliases, alias_uri) do
        :error ->
          {:cont, {:ok, Map.put(aliases, alias_uri, canonical)}}

        {:ok, ^canonical} ->
          {:cont, {:ok, aliases}}

        {:ok, _different} ->
          {:halt, duplicate_resource(alias_uri)}
      end
    end)
  end

  defp duplicate_resource(uri) do
    {:error,
     %CompileError{
       reason: :invalid_schema,
       uri: uri,
       details: %{identifier: uri},
       message: "duplicate schema resource identifier: #{uri}"
     }}
  end
end
