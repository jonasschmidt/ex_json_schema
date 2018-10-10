defmodule ExJsonSchema.Validator.Type do
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error

  @spec validate(String.t(), ExJsonSchema.data()) :: Validator.errors()
  def validate(type, data) do
    case valid?(type, data) do
      true ->
        []

      false ->
        [
          %Error{
            error: %Error.Type{expected: List.wrap(type), actual: data |> data_type},
            path: ""
          }
        ]
    end
  end

  defp valid?(type, data) when is_list(type) do
    Enum.any?(type, &valid?(&1, data))
  end

  defp valid?(type, data) do
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

  defp data_type(data) do
    cond do
      is_nil(data) -> "null"
      is_boolean(data) -> "boolean"
      is_binary(data) -> "string"
      is_integer(data) -> "integer"
      is_number(data) -> "number"
      is_list(data) -> "array"
      is_map(data) -> "object"
      true -> "unknown"
    end
  end
end
