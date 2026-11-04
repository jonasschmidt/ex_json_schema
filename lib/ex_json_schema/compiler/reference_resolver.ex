defmodule ExJsonSchema.Compiler.ReferenceResolver do
  @moduledoc false

  # Resolves every indexed reference against the completed resource graph
  # before validation begins.

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Reference
  alias ExJsonSchema.Compiler.Resource
  alias ExJsonSchema.Compiler.Scanner
  alias ExJsonSchema.Compiler.URI, as: SchemaURI

  @spec resolve(Scanner.result()) ::
          {:ok, Scanner.result()} | {:error, CompileError.t()}
  def resolve(graph) do
    Enum.reduce_while(graph.resources, {:ok, graph.resources}, fn {uri, resource}, {:ok, resources} ->
      case resolve_resource(resource, graph) do
        {:ok, resource} -> {:cont, {:ok, Map.put(resources, uri, resource)}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, resources} -> {:ok, %{graph | resources: resources}}
      {:error, error} -> {:error, error}
    end
  end

  defp resolve_resource(%Resource{references: resource_references} = resource, graph) do
    Enum.reduce_while(resource_references, {:ok, %{}}, fn
      {pointer, reference}, {:ok, references} ->
        case resolve_reference(reference, graph) do
          {:ok, reference} ->
            {:cont, {:ok, Map.put(references, pointer, reference)}}

          {:error, error} ->
            {:halt, {:error, error}}
        end
    end)
    |> case do
      {:ok, references} -> {:ok, %Resource{resource | references: references}}
      {:error, error} -> {:error, error}
    end
  end

  defp resolve_reference(
         %Reference{target: %Location{}} = reference,
         _graph
       ),
       do: {:ok, reference}

  defp resolve_reference(
         %Reference{base_uri: base_uri, value: value, kind: kind} = reference,
         graph
       ) do
    with {:ok, resolved} <- SchemaURI.resolve(base_uri, value),
         {:ok, resource_uri, fragment} <- SchemaURI.split_fragment(resolved),
         {:ok, target_resource} <- fetch_resource(graph, resource_uri),
         {:ok, target} <- fetch_location(target_resource, fragment) do
      dynamic_anchor =
        if kind == :dynamic_ref and is_binary(fragment) and
             not String.starts_with?(fragment, "/") do
          fragment
        end

      {:ok, %Reference{reference | target: target, dynamic_anchor: dynamic_anchor}}
    else
      :error -> invalid_reference(reference)
    end
  end

  defp fetch_resource(graph, uri) do
    canonical = Map.get(graph.aliases, uri, uri)
    Map.fetch(graph.resources, canonical)
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
end
