defmodule ExJsonSchema.Validator.Dependencies do
  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(
          root :: Root.t(),
          schema :: ExJsonSchema.data(),
          property :: {String.t(), ExJsonSchema.data()},
          data :: ExJsonSchema.data()
        ) :: Validator.errors() | no_return
  def validate(root, _, {"dependencies", dependencies}, data) do
    do_validate(root, dependencies, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(root, dependencies, data = %{}) do
    dependencies
    |> Enum.filter(&Map.has_key?(data, elem(&1, 0)))
    |> Enum.flat_map(fn {property, dependency_schema} ->
      validate_dependency(root, property, dependency_schema, data)
    end)
  end

  defp do_validate(_, _, _) do
    []
  end

  defp validate_dependency(_, _, true, _) do
    []
  end

  defp validate_dependency(_, _, _, data = %{}) when map_size(data) == 0 do
    []
  end

  defp validate_dependency(_, property, false, data) do
    if Map.has_key?(data, property) do
      # "Expected data not to have property #{property} but it did."
      [%Error{error: %Error.Dependencies{property: property, missing: nil}, path: ""}]
    else
      []
    end
  end

  defp validate_dependency(root, _, schema = %{}, data) do
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
