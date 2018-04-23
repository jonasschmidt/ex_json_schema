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
  def validate(%{version: version}, _, {"type", type}, data) do
    do_validate(version, type, data)
  end

  def validate(_, _, _, _) do
    []
  end

  @spec do_validate(
          version :: non_neg_integer,
          type :: ExJsonSchema.data(),
          data :: ExJsonSchema.data()
        ) :: Validator.errors_with_list_paths()
  defp do_validate(version, type, data) do
    if valid?(version, type, data) do
      []
    else
      type_name = type_name(type)

      data_type_name =
        data
        |> data_type()
        |> type_name()

      [{"Type mismatch. Expected #{type_name} but got #{data_type_name}.", []}]
    end
  end

  @spec valid?(non_neg_integer, String.t() | [String.t()], ExJsonSchema.data()) :: boolean
  defp valid?(_, "number", data), do: is_number(data)
  defp valid?(_, "array", data), do: is_list(data)
  defp valid?(_, "object", data), do: is_map(data)
  defp valid?(_, "null", data), do: is_nil(data)
  defp valid?(_, "boolean", data), do: is_boolean(data)
  defp valid?(_, "string", data), do: is_binary(data)
  defp valid?(_, "integer", data) when is_integer(data), do: true
  defp valid?(4, "integer", _), do: false

  defp valid?(version, "integer", data) when version >= 6 do
    is_float(data) and Float.round(data) == data
  end

  defp valid?(version, type, data) when is_list(type) do
    Enum.any?(type, &valid?(version, &1, data))
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
