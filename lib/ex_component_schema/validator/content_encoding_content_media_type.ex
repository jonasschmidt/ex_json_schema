defmodule ExComponentSchema.Validator.ContentEncodingContentMediaType do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"contentEncoding"` and `"contentMediaType"` attributes.

  See:
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-8.3
  """

  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(%{version: version}, schema, {"contentEncoding", content_encoding}, data, _)
      when version >= 7 do
    {errors, data} = validate_content_encoding(content_encoding, data)
    validate_content_media_type(schema, data, errors)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp validate_content_encoding("base64", data) when is_bitstring(data) do
    case Base.decode64(data) do
      {:ok, decoded_data} -> {[], decoded_data}
      :error -> {[%Error{error: %Error.ContentEncoding{expected: "base64"}}], data}
    end
  end

  defp validate_content_encoding(_, data) do
    {[], data}
  end

  defp validate_content_media_type(%{"contentMediaType" => "application/json"}, data, errors)
       when is_bitstring(data) do
    case ExComponentSchema.Schema.decode_json(data) do
      {:ok, _} ->
        errors

      {:error, _} ->
        errors ++ [%Error{error: %Error.ContentMediaType{expected: "application/json"}}]
    end
  end

  defp validate_content_media_type(_, _, errors), do: errors
end
