defmodule ExComponentSchema.Validator.Properties do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"properties"` attributes.

  See:

  """

  alias ExComponentSchema.Validator
  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(root, schema, {"properties", _}, properties = %{}, path) do
    do_validate(root, schema, properties, path)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(root, schema, properties, path) do
    validated_known_properties = validate_known_properties(root, schema, properties, path)

    validation_errors(validated_known_properties) ++
      validate_additional_properties(
        root,
        schema["additionalProperties"],
        unvalidated_properties(properties, validated_known_properties),
        path
      )
  end

  defp validate_known_properties(root, schema, properties, path) do
    validate_named_properties(root, schema["properties"], properties, path) ++
      validate_pattern_properties(root, schema["patternProperties"], properties, path) ++
      validate_comp_property(root, schema, properties, path)
  end

  defp validate_comp_property(
         _,
         %{"type" => "component", "comp" => _},
         %{"comp" => _},
         _
       ) do
    [{"comp", []}]
  end

  defp validate_comp_property(_, _, _, _), do: []

  defp validate_named_properties(root, schema, properties, path) do
    schema
    |> Enum.filter(&Map.has_key?(properties, elem(&1, 0)))
    |> Enum.map(fn
      {name, property_schema} ->
        {name,
         Validator.validation_errors(root, property_schema, properties[name], path <> "/#{name}")}
    end)
  end

  defp validate_pattern_properties(_, nil, _, _), do: []

  defp validate_pattern_properties(root, schema, properties, path) do
    Enum.flat_map(schema, &validate_pattern_property(root, &1, properties, path))
  end

  defp validate_pattern_property(root, {pattern, schema}, properties, path) do
    properties_matching(properties, pattern)
    |> Enum.map(fn {name, property} ->
      {name, Validator.validation_errors(root, schema, property, path <> "/#{name}")}
    end)
  end

  defp validate_additional_properties(root, schema, properties, path) when is_map(schema) do
    Enum.flat_map(properties, fn {name, property} ->
      Validator.validation_errors(root, schema, property, path <> "/#{name}")
    end)
  end

  defp validate_additional_properties(_, false, properties, path) when map_size(properties) > 0 do
    Enum.map(properties, fn {name, _} ->
      %Error{error: %Error.AdditionalProperties{}, path: path <> "/#{name}"}
    end)
  end

  defp validate_additional_properties(_, _, _, _), do: []

  defp validation_errors(validated_properties) do
    validated_properties |> Keyword.values() |> List.flatten()
  end

  defp properties_matching(properties, pattern) do
    regex = Regex.compile!(pattern)
    Enum.filter(properties, &Regex.match?(regex, elem(&1, 0)))
  end

  defp unvalidated_properties(properties, validated_properties) do
    keys =
      properties
      |> keys_as_set()
      |> MapSet.difference(keys_as_set(validated_properties))
      |> Enum.to_list()

    Map.take(properties, keys)
  end

  defp keys_as_set(properties) do
    properties |> Enum.map(&elem(&1, 0)) |> Enum.into(MapSet.new())
  end
end
