defmodule ExJsonSchema.Validator do
  defmodule Dependencies do
    def valid?(dependencies, data) when is_map(data) do
      Enum.all?(dependencies, fn {property, dependency} ->
        !Map.has_key?(data, property) or dependency_valid?(dependency, data)
      end)
    end

    def valid?(_, _), do: true

    defp dependency_valid?(schema, data) when is_map(schema) do
      ExJsonSchema.Validator.valid?(schema, data)
    end

    defp dependency_valid?(properties, data) do
      Enum.all?(List.wrap(properties), &Map.has_key?(data, &1))
    end
  end

  def valid?(schema = %{}, data) do
    Enum.all?(schema, &aspect_valid?(schema, &1, data))
  end

  defp property_valid?(_, nil), do: true

  defp property_valid?(property = %{}, data) do
    Enum.all?(property, &aspect_valid?(property, &1, data))
  end

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

  defp aspect_valid?(_, {"allOf", all_of}, data) do
    Enum.all? all_of, &valid?(&1, data)
  end

  defp aspect_valid?(_, {"anyOf", any_of}, data) do
    Enum.any? any_of, &valid?(&1, data)
  end

  defp aspect_valid?(_, {"oneOf", one_of}, data) do
    Enum.reduce(one_of, 0, &(&2 + if valid?(&1, data), do: 1, else: 0)) == 1
  end

  defp aspect_valid?(_, {"not", not_schema}, data) do
    not valid?(not_schema, data)
  end

  defp aspect_valid?(_, {"properties", properties}, data = %{}) do
    Enum.all? properties, fn {name, property} -> property_valid?(property, data[name]) end
  end

  defp aspect_valid?(_, {"type", type}, data) when is_list(type) do
    Enum.any? type, &type_valid?(&1, data)
  end

  defp aspect_valid?(_, {"type", type}, data) do
    type_valid?(type, data)
  end

  defp aspect_valid?(_, {"required", required}, data) do
    Enum.all? List.wrap(required), &Map.has_key?(data, &1)
  end

  defp aspect_valid?(_, {"dependencies", dependencies}, data) do
    Dependencies.valid?(dependencies, data)
  end

  defp aspect_valid?(_, {"enum", enum}, data) do
    Enum.any? enum, &(&1 === data)
  end

  defp aspect_valid?(_, {"items", schema}, items) when is_list(items) and is_map(schema) do
    Enum.all? items, &property_valid?(schema, &1)
  end

  defp aspect_valid?(_, {"items", schemata}, items) when is_list(items) and is_list(schemata) do
    Enum.all? List.zip([items, schemata]), fn {item, schema} ->
      property_valid?(schema, item)
    end
  end

  defp aspect_valid?(_, {"minItems", min_items}, items) when is_list(items) do
    Enum.count(items) >= min_items
  end

  defp aspect_valid?(_, {"maxItems", max_items}, items) when is_list(items) do
    Enum.count(items) <= max_items
  end

  defp aspect_valid?(_, {"uniqueItems", true}, items) when is_list(items) do
    Enum.uniq(items) == items
  end

  defp aspect_valid?(_, {"minLength", min_length}, data) when is_binary(data) do
    String.length(data) >= min_length
  end

  defp aspect_valid?(_, {"maxLength", max_length}, data) when is_binary(data) do
    String.length(data) <= max_length
  end

  defp aspect_valid?(schema, {"minimum", minimum}, data) when is_number(data) do
    case schema["exclusiveMinimum"] do
      true -> data > minimum
      _ -> data >= minimum
    end
  end

  defp aspect_valid?(schema, {"maximum", maximum}, data) when is_number(data) do
    case schema["exclusiveMaximum"] do
      true -> data < maximum
      _ -> data <= maximum
    end
  end

  defp aspect_valid?(_, {"minProperties", min_properties}, data) when is_map(data) do
    Map.size(data) >= min_properties
  end

  defp aspect_valid?(_, {"maxProperties", max_properties}, data) when is_map(data) do
    Map.size(data) <= max_properties
  end

  defp aspect_valid?(_, {"multipleOf", multiple_of}, data) when is_number(data) do
    factor = data / multiple_of
    Float.floor(factor) == factor
  end

  defp aspect_valid?(_, {"pattern", pattern}, data) when is_binary(data) do
    pattern |> Regex.compile! |> Regex.match?(data)
  end

  defp aspect_valid?(_, {_, _}, _json), do: true
end
