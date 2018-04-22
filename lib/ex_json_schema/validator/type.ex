defmodule ExJsonSchema.Validator.Type do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths
  def validate(_, _, {"type", type}, data) do
    do_validate(type, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(type, data) do
    if valid?(type, data) do
      []
    else
      [{"Type mismatch. Expected #{type |> type_name} but got #{data |> data_type |> type_name}.", []}]
    end
  end

  defp valid?(type, data) when is_list(type) do
    Enum.any?(type, &valid?(&1, data))
  end

  defp valid?("null", data) do
    is_nil(data)
  end

  defp valid?("boolean", data) do
    is_boolean(data)
  end

  defp valid?("string", data) do
    is_binary(data)
  end

  defp valid?("integer", data) do
    is_integer(data) or (is_float(data) and (Float.round(data) == data))
  end

  defp valid?("number", data) do
    is_number(data)
  end

  defp valid?("array", data) do
    is_list(data)
  end

  defp valid?("object", data) do
    is_map(data)
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
    end
  end

  defp type_name(type) do
    type
    |> List.wrap()
    |> Enum.map_join(", ", &String.capitalize/1)
  end
end
