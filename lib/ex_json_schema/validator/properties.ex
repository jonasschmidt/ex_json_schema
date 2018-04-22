defmodule ExJsonSchema.Validator.Properties do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths

  def validate(root, schema, {"properties", _}, data) do
    do_validate(root, schema, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(root, schema, properties = %{}) do
    validated_named_properties = validate_named_properties(root, schema["properties"], properties)
    validated_pattern_properties = validate_pattern_properties(root, schema["patternProperties"], properties)
    validated_known_properties = validated_named_properties ++ validated_pattern_properties

    remaining_properties = unvalidated_properties(properties, validated_known_properties)
    validated_additional_properties =
      validate_additional_properties(root, schema["additionalProperties"], remaining_properties)

    validation_errors(validated_known_properties) ++ validated_additional_properties
  end

  defp do_validate(_, _, _) do
    []
  end

  defp boolean_schema?(schema) do
    schema
    |> Map.values()
    |> Enum.all?(&is_boolean/1)
  end

  defp invalid_boolean_entries(schema, properties) do
    if boolean_schema?(schema) do
      properties
      |> Map.keys()
      |> Enum.reject(fn name ->
        !Map.has_key?(schema, name) or Map.get(schema, name) == true
      end)
    else
      false
    end
  end

  defp validate_named_properties(_, _, properties = %{}) when map_size(properties) == 0 do
    []
  end

  defp validate_named_properties(root, schema, properties) do
    case invalid_boolean_entries(schema, properties) do
      [] ->
        []

      false ->
        schema
        |> Enum.filter(&Map.has_key?(properties, elem(&1, 0)))
        |> Enum.map(fn {name, property_schema} ->
          {name, Validator.validate(root, property_schema, properties[name], [name])}
        end)

      invalid_entries ->
        Enum.map(invalid_entries, fn name ->
          {name , {"Cannot have a value for property #{name}", []}}
        end)
    end
  end

  defp validate_pattern_properties(_, nil, _), do: []

  defp validate_pattern_properties(root, schema, properties) do
    Enum.flat_map(schema, &validate_pattern_property(root, &1, properties))
  end

  defp validate_pattern_property(_, {pattern, false}, properties) do
    properties
    |> properties_matching(pattern)
    |> Enum.map(fn {name, _} ->
      {name, [{"Schema does not allow matching properties for #{pattern}.", [name]}]}
    end)
  end

  defp validate_pattern_property(_, {_, true}, _) do
    []
  end

  defp validate_pattern_property(root, {pattern, schema}, properties) do
    properties
    |> properties_matching(pattern)
    |> Enum.map(fn {name, property} ->
      {name, Validator.validate(root, schema, property, [name])}
    end)
  end

  defp validate_additional_properties(_, false, properties) when map_size(properties) > 0 do
    Enum.map(properties, fn {name, _} ->
      {"Schema does not allow additional properties.", [name]}
    end)
  end

  defp validate_additional_properties(root, schema, properties) when is_map(schema) do
    Enum.flat_map(properties, fn {name, property} ->
      Validator.validate(root, schema, property, [name])
    end)
  end

  defp validate_additional_properties(_, _, _), do: []

  defp validation_errors(validated_properties) do
    validated_properties
    |> Enum.map(fn {_k, v} -> v end)
    |> List.flatten()
  end

  defp properties_matching(properties, pattern) do
    regex = Regex.compile!(pattern)
    Enum.filter(properties, &Regex.match?(regex, elem(&1, 0)))
  end

  defp unvalidated_properties(properties, validated_properties) do
    unvalidated =
      properties
      |> keys_as_set()
      |> MapSet.difference(keys_as_set(validated_properties))

    Map.take(properties, unvalidated)
  end

  defp keys_as_set(properties) do
    MapSet.new(properties, fn {k, _v} -> k end)
  end
end
