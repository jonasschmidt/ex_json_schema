defmodule ExJsonSchema.Validator do
  alias ExJsonSchema.Validator.Properties
  alias ExJsonSchema.Validator.Items
  alias ExJsonSchema.Validator.Dependencies
  alias ExJsonSchema.Validator.Type
  alias ExJsonSchema.Schema.Root

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

  defp aspect_valid?(_, _, {"type", type}, data) do
    Type.valid?(type, data)
  end

  defp aspect_valid?(root, schema, {"properties", _}, data = %{}) do
    Properties.valid?(root, schema, data)
  end

  defp aspect_valid?(root, schema, {"items", _}, items) do
    Items.valid?(root, schema, items)
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
end
