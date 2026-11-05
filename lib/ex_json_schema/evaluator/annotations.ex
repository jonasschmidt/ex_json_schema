defmodule ExJsonSchema.Evaluator.Annotations do
  @moduledoc false

  # Collects annotations from successful result branches by instance and
  # schema location.

  alias ExJsonSchema.Compiler.Pointer
  alias ExJsonSchema.Compiler.URI, as: SchemaURI
  alias ExJsonSchema.Evaluator.Result

  @type collected :: %{
          optional({String.t(), String.t()}) => %{String.t() => ExJsonSchema.data()}
        }

  @spec collect(Result.t()) :: collected()
  def collect(%Result{valid: false}), do: %{}

  def collect(%Result{} = result) do
    result
    |> nodes()
    |> Enum.filter(fn %Result{annotation?: annotation?} -> annotation? end)
    |> Enum.reduce(%{}, fn
      %Result{
        instance_location: instance_location,
        keyword: keyword,
        annotation: annotation
      } = node,
      annotations ->
        schema_location = annotation_schema_location(node)
        key = {instance_location, keyword}

        Map.update(
          annotations,
          key,
          %{schema_location => annotation},
          &Map.put(&1, schema_location, annotation)
        )
    end)
  end

  defp nodes(%Result{children: children}) do
    Enum.flat_map(children, fn %Result{valid: valid} = child ->
      if valid, do: [child | nodes(child)], else: []
    end)
  end

  defp annotation_schema_location(%Result{schema_keyword_location: schema_keyword_location}) do
    segments =
      case Pointer.decode(schema_keyword_location) do
        {:ok, segments} -> Enum.drop(segments, -1)
        :error -> []
      end

    case Pointer.encode(segments) do
      "" -> "#"
      pointer -> SchemaURI.with_fragment("", pointer)
    end
  end
end
