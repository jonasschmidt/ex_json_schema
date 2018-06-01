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
      [{"Expected data not to have property #{property} but it did.", []}]
    else
      []
    end
  end

  defp validate_dependency(root, _, schema = %{}, data) do
    Validator.validate(root, schema, data)
  end

  defp validate_dependency(_, property, dependencies, data) do
    Enum.flat_map(List.wrap(dependencies), fn dependency ->
      case Map.has_key?(data, dependency) do
        true ->
          []

        false ->
          [{"Property #{property} depends on #{dependency} to be present but it was not.", []}]
      end
    end)
  end
end
