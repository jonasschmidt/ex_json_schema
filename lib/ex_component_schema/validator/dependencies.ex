defmodule ExComponentSchema.Validator.Dependencies do
  alias ExComponentSchema.Validator
  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(root, _, {"dependencies", dependencies}, data, path) do
    do_validate(root, dependencies, data, path)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(root, dependencies, data = %{}, path) do
    dependencies
    |> Enum.filter(&Map.has_key?(data, elem(&1, 0)))
    |> Enum.flat_map(fn {property, dependency_schema} ->
      validate_dependency(root, property, dependency_schema, data, path)
    end)
  end

  defp do_validate(_, _, _, _) do
    []
  end

  defp validate_dependency(_, _, true, _, _) do
    []
  end

  defp validate_dependency(_, _, _, data = %{}, _) when map_size(data) == 0 do
    []
  end

  defp validate_dependency(root, _, schema, data, path)
       when is_map(schema) or is_boolean(schema) do
    Validator.validation_errors(root, schema, data, path)
  end

  defp validate_dependency(_, property, dependencies, data, _)
       when is_map(dependencies) or is_list(dependencies) do
    case Enum.filter(List.wrap(dependencies), &(!Map.has_key?(data, &1))) do
      [] ->
        []

      missing ->
        [%Error{error: %Error.Dependencies{property: property, missing: missing}}]
    end
  end
end
