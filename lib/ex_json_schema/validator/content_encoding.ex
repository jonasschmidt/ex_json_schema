defmodule ExJsonSchema.Validator.ContentEncoding do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"contentEncoding"` attributes.

  See:
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-8.3
  """

  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(%{version: version}, _, {"contentEncoding", content_encoding}, data, _)
      when version >= 7 do
    do_validate(content_encoding, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate("base64", data) when is_bitstring(data) do
    case Base.decode64(data) do
      {:ok, _} -> []
      :error -> [%Error{error: %Error.ContentEncoding{expected: "base64"}}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
