defmodule ExJsonSchema.Validator.ContentEncodingContentMediaType do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"contentEncoding"` and `"contentMediaType"` attributes.

  See:
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-8.3
  """

  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(%{version: version}, schema, {"contentEncoding", content_encoding}, data, _)
      when version >= 7 do
    {errors, data} = validate_content_encoding(content_encoding, data)
    validate_content_media_type(schema, data, errors)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp validate_content_encoding("base64" = encoding, data) when is_bitstring(data) do
    case Base.decode64(data) do
      {:ok, decoded_data} ->
        {[], decoded_data}

      :error ->
        {[%Error{error: %Error.ContentEncoding{expected: "base64"}, fragment: encoding}], data}
    end
  end

  defp validate_content_encoding(_, data) do
    {[], data}
  end

  defp validate_content_media_type(
         %{"contentMediaType" => "application/json" = content_media_type},
         data,
         errors
       )
       when is_bitstring(data) do
    case ExJsonSchema.Schema.decode_json(data) do
      {:ok, _} ->
        errors

      {:error, _} ->
        errors ++
          [
            %Error{
              error: %Error.ContentMediaType{expected: "application/json"},
              fragment: content_media_type
            }
          ]
    end
  end

  defp validate_content_media_type(_, _, errors), do: errors
end
