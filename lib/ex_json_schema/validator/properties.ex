defmodule NExJsonSchema.Validator.Properties do
  alias NExJsonSchema.Schema
  alias NExJsonSchema.Validator

  @spec validate(Root.t(), Schema.resolved(), NExJsonSchema.json()) :: Validator.errors_with_list_paths()
  def validate(root, schema, properties = %{}) do
    validated_known_properties = validate_known_properties(root, schema, properties)

    validation_errors(validated_known_properties) ++
      validate_additional_properties(
        root,
        schema["additionalProperties"],
        unvalidated_properties(properties, validated_known_properties)
      )
  end

  @spec validate(Root.t(), Schema.resolved(), NExJsonSchema.data()) :: []
  def validate(_, _, _), do: []

  defp validate_known_properties(root, schema, properties) do
    validate_named_properties(root, schema["properties"], properties) ++
      validate_pattern_properties(root, schema["patternProperties"], properties)
  end

  defp validate_named_properties(root, schema, properties) do
    schema
    |> Enum.filter(&Map.has_key?(properties, elem(&1, 0)))
    |> Enum.map(fn {name, property_schema} ->
      {name, Validator.validate(root, property_schema, properties[name], [name])}
    end)
  end

  defp validate_pattern_properties(_, nil, _), do: []

  defp validate_pattern_properties(root, schema, properties) do
    Enum.flat_map(schema, &validate_pattern_property(root, &1, properties))
  end

  defp validate_pattern_property(root, {pattern, schema}, properties) do
    properties_matching(properties, pattern)
    |> Enum.map(fn {name, property} ->
      {name, Validator.validate(root, schema, property, [name])}
    end)
  end

  defp validate_additional_properties(root, schema, properties) when is_map(schema) do
    Enum.flat_map(properties, fn {name, property} -> Validator.validate(root, schema, property, [name]) end)
  end

  defp validate_additional_properties(_, false, properties) when map_size(properties) > 0 do
    Enum.map(properties, fn {name, _} ->
      {Validator.format_error(
         :schema,
         "schema does not allow additional properties",
         properties: properties
       ), [name]}
    end)
  end

  defp validate_additional_properties(_, _, _), do: []

  defp validation_errors(validated_properties) do
    validated_properties |> Dict.values() |> List.flatten()
  end

  defp properties_matching(properties, pattern) do
    regex = Regex.compile!(pattern)
    Enum.filter(properties, &Regex.match?(regex, elem(&1, 0)))
  end

  defp unvalidated_properties(properties, validated_properties) do
    unvalidated =
      properties
      |> keys_as_set()
      |> Set.difference(keys_as_set(validated_properties))
      |> Enum.to_list()

    Map.take(properties, unvalidated)
  end

  defp keys_as_set(properties) do
    properties |> Dict.keys() |> Enum.into(HashSet.new())
  end
end
