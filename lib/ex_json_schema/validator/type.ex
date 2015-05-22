defmodule ExJsonSchema.Validator.Type do
  def valid?(type, data) when is_list(type) do
    Enum.any? type, &valid?(&1, data)
  end

  def valid?(type, data) do
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
end
