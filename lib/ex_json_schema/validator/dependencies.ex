defmodule ExJsonSchema.Validator.Dependencies do
  alias ExJsonSchema.Validator, as: Validator

  def valid?(root, dependencies, data) when is_map(data) do
    Enum.all?(dependencies, fn {property, dependency} ->
      !Map.has_key?(data, property) or dependency_valid?(root, dependency, data)
    end)
  end

  def valid?(_, _, _), do: true

  defp dependency_valid?(root, schema, data) when is_map(schema) do
    Validator.valid?(root, schema, data)
  end

  defp dependency_valid?(_, properties, data) do
    Enum.all?(List.wrap(properties), &Map.has_key?(data, &1))
  end
end
