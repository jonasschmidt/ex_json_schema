defmodule ExJsonSchema.Validator.Dependencies do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths

  def validate(root, _, {"dependencies", dependencies}, data) do
    IO.inspect dependencies
    do_validate(root, dependencies, data)
  end

  def validate(_, _, _, _) do
    []
  end

  def do_validate(_, _, data = %{}) when map_size(data) == 0 do
    []
  end

  def do_validate(root, dependencies, data) when is_map(data) do
    dependencies
    |> Enum.filter(&Map.has_key?(data, elem(&1, 0)))
    |> Enum.flat_map(fn {property, dependency} ->
      validate_dependency(root, property, dependency, data)
    end)
  end

  def do_validate(_, _, _) do
    []
  end

  defp validate_dependency(_, _, true, _) do
    []
  end

  defp validate_dependency(_, _, _, data = %{}) when map_size(data) == 0 do
    []
  end

  # defp validate_dependency(root, _, schema, data) when is_map(schema) do
  #   IO.inspect schema
  #   Validator.validate(root, schema, data)
  # end

  defp validate_dependency(_, property, dependencies, data) do
    dependencies
    |> List.wrap()
    |> Enum.flat_map(fn dependency ->
      if Map.has_key?(data, dependency) do
        []
      else
        [{"Property #{property} depends on #{dependency} to be present but it was not.", []}]
      end
    end)
  end
end
