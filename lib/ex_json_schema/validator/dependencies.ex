defmodule ExJsonSchema.Validator.Dependencies do
  alias ExJsonSchema.{Schema, Validator}
  alias ExJsonSchema.Schema.Root

  @spec validate(Root.t, Schema.resolved, ExJsonSchema.data) :: Validator.errors_with_list_paths
  def validate(root, dependencies, data) when is_map(data) do
    dependencies
    |> Enum.filter(&Map.has_key?(data, elem(&1, 0)))
    |> Enum.flat_map(fn {property, dependency} ->
      validate_dependency(root, property, dependency, data)
    end)
  end

  def validate(_, _, _), do: []

  defp validate_dependency(root, _, schema, data) when is_map(schema) do
    Validator.validate(root, schema, data)
  end

  defp validate_dependency(_, property, dependencies, data) do
    Enum.flat_map List.wrap(dependencies), fn dependency ->
      case Map.has_key?(data, dependency) do
        true -> []
        false -> [{"Property #{property} depends on #{dependency} to be present but it was not.", []}]
      end
    end
  end
end
