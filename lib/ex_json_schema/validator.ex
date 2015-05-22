defmodule ExJsonSchema.Validator do
  defmodule Dependencies do
    def valid?(root, dependencies, data) when is_map(data) do
      Enum.all?(dependencies, fn {property, dependency} ->
        !Map.has_key?(data, property) or dependency_valid?(root, dependency, data)
      end)
    end

    def valid?(_, _, _), do: true

    defp dependency_valid?(root, schema, data) when is_map(schema) do
      ExJsonSchema.Validator.valid?(root, schema, data)
    end

    defp dependency_valid?(_, properties, data) do
      Enum.all?(List.wrap(properties), &Map.has_key?(data, &1))
    end
  end

  alias ExJsonSchema.Schema.Root, as: Root

  def valid?(root = %Root{}, data), do: valid?(root, root.schema, data)

  def valid?(root = %{}, data), do: valid?(%Root{schema: root}, root, data)

  def valid?(_, schema = %{}, _) when map_size(schema) == 0, do: true

  def valid?(root, schema = %{}, data) do
    Enum.all?(schema, &aspect_valid?(root, schema, &1, data))
  end

  def valid?(_, _, _), do: false

  defp aspect_valid?(root, _, {"$ref", ref}, data) do
    {root, schema} = ref.(root)
    valid?(root, schema, data)
  end

  defp aspect_valid?(root, _, {"allOf", all_of}, data) do
    Enum.all? all_of, &valid?(root, &1, data)
  end

  defp aspect_valid?(root, _, {"anyOf", any_of}, data) do
    Enum.any? any_of, &valid?(root, &1, data)
  end

  defp aspect_valid?(root, _, {"oneOf", one_of}, data) do
    Enum.reduce(one_of, 0, &(&2 + if valid?(root, &1, data), do: 1, else: 0)) == 1
  end

  defp aspect_valid?(root, _, {"not", not_schema}, data) do
    not valid?(root, not_schema, data)
  end

  defp aspect_valid?(root, schema, {"properties", _}, data = %{}) do
    all_properties_valid?(root, schema, data)
  end

  defp aspect_valid?(root, schema, {"patternProperties", _}, data = %{}) do
    all_properties_valid?(root, schema, data)
  end

  defp aspect_valid?(root, schema, {"additionalProperties", _}, data = %{}) do
    all_properties_valid?(root, schema, data)
  end

  defp aspect_valid?(_, _, {"type", type}, data) when is_list(type) do
    Enum.any? type, &type_valid?(&1, data)
  end

  defp aspect_valid?(_, _, {"type", type}, data) do
    type_valid?(type, data)
  end

  defp aspect_valid?(_, _, {"required", required}, data) do
    Enum.all? List.wrap(required), &Map.has_key?(data, &1)
  end

  defp aspect_valid?(root, _, {"dependencies", dependencies}, data) do
    Dependencies.valid?(root, dependencies, data)
  end

  defp aspect_valid?(_, _, {"enum", enum}, data) do
    Enum.any? enum, &(&1 === data)
  end

  defp aspect_valid?(root, schema, {"items", _}, items) do
    schema = Map.merge(%{"additionalItems" => true}, schema)
    items_valid?(root, schema, items)
  end

  defp aspect_valid?(root, schema, {"additionalItems", _}, items) do
    schema = Map.merge(%{"items" => %{}}, schema)
    items_valid?(root, schema, items)
  end

  defp aspect_valid?(_, _, {"minItems", min_items}, items) when is_list(items) do
    Enum.count(items) >= min_items
  end

  defp aspect_valid?(_, _, {"maxItems", max_items}, items) when is_list(items) do
    Enum.count(items) <= max_items
  end

  defp aspect_valid?(_, _, {"uniqueItems", true}, items) when is_list(items) do
    Enum.uniq(items) == items
  end

  defp aspect_valid?(_, _, {"minLength", min_length}, data) when is_binary(data) do
    String.length(data) >= min_length
  end

  defp aspect_valid?(_, _, {"maxLength", max_length}, data) when is_binary(data) do
    String.length(data) <= max_length
  end

  defp aspect_valid?(_, schema, {"minimum", minimum}, data) when is_number(data) do
    case schema["exclusiveMinimum"] do
      true -> data > minimum
      _ -> data >= minimum
    end
  end

  defp aspect_valid?(_, schema, {"maximum", maximum}, data) when is_number(data) do
    case schema["exclusiveMaximum"] do
      true -> data < maximum
      _ -> data <= maximum
    end
  end

  defp aspect_valid?(_, _, {"minProperties", min_properties}, data) when is_map(data) do
    Map.size(data) >= min_properties
  end

  defp aspect_valid?(_, _, {"maxProperties", max_properties}, data) when is_map(data) do
    Map.size(data) <= max_properties
  end

  defp aspect_valid?(_, _, {"multipleOf", multiple_of}, data) when is_number(data) do
    factor = data / multiple_of
    Float.floor(factor) == factor
  end

  defp aspect_valid?(_, _, {"pattern", pattern}, data) when is_binary(data) do
    pattern |> Regex.compile! |> Regex.match?(data)
  end

  defp aspect_valid?(_, _, _, _), do: true

  defp type_valid?(type, data) do
    case type do
      "null" -> is_nil(data)
      "boolean" -> is_boolean(data)
      "string" -> is_binary(data)
      "integer" -> is_integer(data)
      "number" -> is_number(data)
      "array" -> is_list(data)
      "object" -> is_map(data)
    end
  end

  defp all_properties_valid?(root, schema, properties) do
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
      {name, valid?(root, property_schema, properties[name])}
    end
  end

  defp validate_pattern_properties(_, nil, _), do: []

  defp validate_pattern_properties(root, schema, properties) do
    Enum.flat_map(schema, &validate_pattern_property(root, &1, properties))
  end

  defp validate_pattern_property(root, {pattern, schema}, properties) do
    properties_matching(properties, pattern)
    |> Enum.map fn {name, property} ->
      {name, valid?(root, schema, property)}
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
    Enum.all? properties, &valid?(root, schema, elem(&1, 1))
  end

  defp additional_properties_valid?(_, false, properties) when map_size(properties) > 0, do: false

  defp additional_properties_valid?(_, _, _), do: true

  defp items_valid?(root, %{"items" => schema = %{}}, items) when is_list(items) do
    Enum.all? items, &valid?(root, schema, &1)
  end

  defp items_valid?(root, %{"items" => schemata, "additionalItems" => additional_items}, items) when is_list(items) and is_list(schemata) do
    items
    |> Enum.with_index
    |> Enum.all? fn {item, index} ->
      schema = Enum.at(schemata, index, additional_items_schema(additional_items))
      valid?(root, schema, item)
    end
  end

  defp items_valid?(_, _, _), do: true

  defp additional_items_schema(schema = %{}), do: schema
  defp additional_items_schema(true), do: %{}
  defp additional_items_schema(_), do: nil
end
