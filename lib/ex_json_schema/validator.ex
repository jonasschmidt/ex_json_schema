defmodule ExJsonSchema.Validator do
  defmodule Properties do
    defmodule Array do
      def valid?(schema, json) do
        is_list(json) and Enum.all?(schema, &aspect_valid?(&1, json))
      end

      defp aspect_valid?({"items", schema}, items) do
        Enum.all?(items, &ExJsonSchema.Validator.Properties.property_valid?(schema, &1))
      end

      defp aspect_valid?({"minItems", min_items}, items) do
        Enum.count(items) >= min_items
      end

      defp aspect_valid?({"maxItems", max_items}, items) do
        Enum.count(items) <= max_items
      end

      defp aspect_valid?(_, _), do: true
    end

    def valid?(properties = %{}, json) do
      Enum.all?(properties, fn {name, property} -> property_valid?(property, json[name]) end)
    end

    def property_valid?(property = %{}, json) do
      Enum.all?(property, &aspect_valid?(property, &1, json))
    end

    defp aspect_valid?(_, _, nil), do: true

    defp aspect_valid?(property, {"type", type}, json) do
      case type do
        "string" -> is_binary(json)
        "integer" -> is_integer(json)
        "number" -> is_number(json)
        "array" -> Array.valid?(property, json)
      end
    end

    defp aspect_valid?(property, {"minimum", minimum}, json) do
      case property["exclusiveMinimum"] do
        true -> json > minimum
        _ -> json >= minimum
      end
    end

    defp aspect_valid?(property, {"maximum", maximum}, json) do
      case property["exclusiveMaximum"] do
        true -> json < maximum
        _ -> json <= maximum
      end
    end

    defp aspect_valid?(_, _, _), do: true
  end

  defmodule Required do
    def valid?(required, json) do
      Enum.all?(List.wrap(required), &Map.has_key?(json, &1))
    end
  end

  defmodule Dependencies do
    def valid?(dependencies, json) do
      Enum.all?(dependencies, fn {property, dependency} ->
        !Map.has_key?(json, property) or dependency_valid?(dependency, json)
      end)
    end

    defp dependency_valid?(schema, json) when is_map(schema) do
      ExJsonSchema.Validator.valid?(schema, json)
    end

    defp dependency_valid?(properties, json) do
      Enum.all?(List.wrap(properties), &Map.has_key?(json, &1))
    end
  end

  def valid?(schema = %{}, json) do
    Enum.all?(schema, &aspect_valid?(&1, json))
  end

  defp aspect_valid?({"properties", properties}, json) do
    Properties.valid?(properties, json)
  end

  defp aspect_valid?({"required", required}, json) do
    Required.valid?(required, json)
  end

  defp aspect_valid?({"dependencies", dependencies}, json) do
    Dependencies.valid?(dependencies, json)
  end

  defp aspect_valid?({_, _}, _json), do: true
end
