defmodule ExJsonSchema.Validator.Type do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"type"` attributes.

  See:

  """

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(
          root :: Root.t(),
          schema :: ExJsonSchema.data(),
          property :: {String.t(), ExJsonSchema.data()},
          data :: ExJsonSchema.data()
        ) :: Validator.errors_with_list_paths()
  def validate(_, _, {"type", type}, data) do
    do_validate(type, data)
  end

  def validate(_, _, _, _) do
    []
  end

  @spec do_validate(type :: ExJsonSchema.data(), data :: ExJsonSchema.data()) ::
          Validator.errors_with_list_paths()
  defp do_validate(type, data) do
    if valid?(type, data) do
      []
    else
      [
        {"Type mismatch. Expected #{type |> type_name} but got #{data |> data_type |> type_name}.",
         []}
      ]
    end
  end

  @spec valid?(String.t() | [String.t()], ExJsonSchema.data()) :: boolean
  defp valid?("number", data), do: is_number(data)
  defp valid?("array", data), do: is_list(data)
  defp valid?("object", data), do: is_map(data)
  defp valid?("null", data), do: is_nil(data)
  defp valid?("boolean", data), do: is_boolean(data)
  defp valid?("string", data), do: is_binary(data)

  defp valid?("integer", data) do
    is_integer(data) or (is_float(data) and Float.round(data) == data)
  end

  defp valid?(type, data) when is_list(type) do
    Enum.any?(type, &valid?(&1, data))
  end

  @spec data_type(ExJsonSchema.data()) :: String.t()
  defp data_type(nil), do: "null"
  defp data_type(data) when is_binary(data), do: "string"
  defp data_type(data) when is_boolean(data), do: "boolean"
  defp data_type(data) when is_integer(data), do: "integer"
  defp data_type(data) when is_list(data), do: "array"
  defp data_type(data) when is_map(data), do: "object"
  defp data_type(data) when is_number(data), do: "number"

  @spec type_name(String.t()) :: String.t()
  defp type_name(type) do
    type
    |> List.wrap()
    |> Enum.map_join(", ", &String.capitalize/1)
  end
end
