defmodule ExJsonSchema.Validator.Dependencies do
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, _, {"dependencies", dependencies}, data, path) do
    do_validate(root, dependencies, data, path)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(root, dependencies, data = %{}, path) do
    dependencies
    |> Enum.filter(&Map.has_key?(data, elem(&1, 0)))
    |> Enum.map(fn {property, dependency_schema} ->
      validate_dependency(root, property, dependency_schema, data, path)
    end)
    |> Enum.reduce(Result.new(), &Result.merge/2)
  end

  defp do_validate(_, _, _, _) do
    Result.new()
  end

  defp validate_dependency(_, _, true, _, _) do
    Result.new()
  end

  defp validate_dependency(_, _, _, data = %{}, _) when map_size(data) == 0 do
    Result.new()
  end

  defp validate_dependency(root, _, schema, data, path) when is_map(schema) or is_boolean(schema) do
    Validator.validation_result(root, schema, data, path)
  end

  defp validate_dependency(_, property, dependencies, data, _) when is_map(dependencies) or is_list(dependencies) do
    case Enum.filter(List.wrap(dependencies), &(!Map.has_key?(data, &1))) do
      [] ->
        Result.new()

      missing ->
        Result.with_errors([%Error{error: %Error.Dependencies{property: property, missing: missing}}])
    end
  end
end
