defmodule ExJsonSchema.Validator.Dependencies do
  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(
          root :: Root.t(),
          schema :: ExJsonSchema.data(),
          property :: {String.t(), ExJsonSchema.data()},
          data :: ExJsonSchema.data()
        ) :: Validator.errors_with_list_paths()
  def validate(root, _, {"dependencies", dependencies}, data) do
    do_validate(root, dependencies, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(_, _, data = %{}) when map_size(data) == 0 do
    []
  end

  defp do_validate(_, _, data) when not is_map(data) do
    []
  end

  defp do_validate(root, dependencies, data) do
    Enum.flat_map(dependencies, fn {property, dependency_schema} ->
      validate_dependency(root, dependencies, property, dependency_schema, data)
    end)
  end

  defp validate_dependency(_, _, _, true, _) do
    []
  end

  defp validate_dependency(_, _, _, _, data = %{}) when map_size(data) == 0 do
    []
  end

  defp validate_dependency(_, _, property, false, data) do
    if Map.has_key?(data, property) do
      [{"Expected data not to have property #{property} but it did.", []}]
    else
      []
    end
  end

  defp validate_dependency(root, schema, property, dependencies, data)
       when is_list(dependencies) do
    dependencies
    |> List.wrap()
    |> Enum.flat_map(fn dependency ->
      if Map.has_key?(data, dependency) do
        Validator.validate(root, schema, Map.get(data, dependency))
      else
        [
          {"Property #{inspect(property)} depends on #{inspect(dependency)} to be present but it was not.",
           []}
        ]
      end
    end)
  end

  defp validate_dependency(root, schema, property, dependencies, data) do
    dependencies
    |> List.wrap()
    |> Enum.flat_map(fn dependency ->
      if Map.has_key?(data, dependency) do
        Validator.validate(root, schema, Map.get(data, dependency))
      else
        [
          {"Property #{inspect(property)} depends on #{inspect(dependency)} to be present but it was not.",
           []}
        ]
      end
    end)
  end
end
