defmodule ExJsonSchema.Validator.Dependencies do
  alias ExJsonSchema.Schema
  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error

  @spec validate(Root.t(), Schema.resolved(), ExJsonSchema.data()) ::
          Validator.errors() | no_return
  def validate(root, dependencies, data) when is_map(data) do
    dependencies
    |> Enum.filter(&Map.has_key?(data, elem(&1, 0)))
    |> Enum.flat_map(fn {property, dependency} ->
      validate_dependency(root, property, dependency, data)
    end)
  end

  def validate(_, _, _), do: []

  defp validate_dependency(root, _, schema, data) when is_map(schema) do
    Validator.validation_errors(root, schema, data, "")
  end

  defp validate_dependency(_, property, dependencies, data) do
    case Enum.filter(List.wrap(dependencies), &(!Map.has_key?(data, &1))) do
      [] ->
        []

      missing ->
        [%Error{error: %Error.Dependencies{property: property, missing: missing}, path: ""}]
    end
  end
end
