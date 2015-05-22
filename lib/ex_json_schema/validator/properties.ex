defmodule ExJsonSchema.Validator.Properties do
  alias ExJsonSchema.Validator, as: Validator

  def valid?(root, schema, properties) do
    validated_properties = validate_known_properties(root, schema, properties)

    all_validated_properties_valid?(validated_properties)
    and
    additional_properties_valid?(
      root,
      schema["additionalProperties"],
      unvalidated_properties(properties, validated_properties))
  end

  defp validate_known_properties(root, schema, properties) do
    validate_named_properties(root, schema["properties"], properties) ++
      validate_pattern_properties(root, schema["patternProperties"], properties)
  end

  defp validate_named_properties(_, nil, _), do: []

  defp validate_named_properties(root, schema, properties) do
    schema
    |> Enum.filter(&Map.has_key?(properties, elem(&1, 0)))
    |> Enum.map fn {name, property_schema} ->
      {name, Validator.valid?(root, property_schema, properties[name])}
    end
  end

  defp validate_pattern_properties(_, nil, _), do: []

  defp validate_pattern_properties(root, schema, properties) do
    Enum.flat_map(schema, &validate_pattern_property(root, &1, properties))
  end

  defp validate_pattern_property(root, {pattern, schema}, properties) do
    properties_matching(properties, pattern)
    |> Enum.map fn {name, property} ->
      {name, Validator.valid?(root, schema, property)}
    end
  end

  defp properties_matching(properties, pattern) do
    regex = Regex.compile!(pattern)
    Enum.filter properties, &Regex.match?(regex, elem(&1, 0))
  end

  defp all_validated_properties_valid?(validated_properties) do
    validated_properties |> Dict.values |> Enum.all?
  end

  defp unvalidated_properties(properties, validated_properties) do
    unvalidated = Set.difference(keys_as_set(properties), keys_as_set(validated_properties))
    Map.take(properties, unvalidated)
  end

  defp keys_as_set(properties) do
    properties |> Dict.keys |> Enum.into(HashSet.new)
  end

  defp additional_properties_valid?(root, schema, properties) when is_map(schema) do
    Enum.all? properties, &Validator.valid?(root, schema, elem(&1, 1))
  end

  defp additional_properties_valid?(_, false, properties) when map_size(properties) > 0, do: false

  defp additional_properties_valid?(_, _, _), do: true
end
