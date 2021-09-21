defmodule ExComponentSchema.Validator.Type do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"type"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.5.2
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.25
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.1.1
  """

  alias ExComponentSchema.Validator
  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(%{version: version}, _, {"type", type}, data, _) do
    do_validate(version, type, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  @spec do_validate(
          version :: non_neg_integer,
          type :: ExComponentSchema.data(),
          data :: ExComponentSchema.data()
        ) :: Validator.errors()
  defp do_validate(version, type, data) do
    if valid?(version, type, data) do
      []
    else
      [%Error{error: %Error.Type{expected: List.wrap(type), actual: data_type(data)}}]
    end
  end

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

  defp valid?(_, "component", %{"type" => _}), do: true
  defp valid?(_, "component", _), do: false
  defp valid?(_, "listener", data), do: is_map(data)

  defp valid?(version, type, data) when is_list(type) do
    Enum.any?(type, &valid?(version, &1, data))
  end

  defp data_type(nil), do: "null"
  defp data_type(data) when is_binary(data), do: "string"
  defp data_type(data) when is_boolean(data), do: "boolean"
  defp data_type(data) when is_integer(data), do: "integer"
  defp data_type(data) when is_list(data), do: "array"
  defp data_type(data) when is_map(data), do: "object"
  defp data_type(data) when is_number(data), do: "number"
  defp data_type(_), do: "unknown"
end
