defmodule ExJsonSchema.Validator.ContentEncodingContentMediaType do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"contentEncoding"` and `"contentMediaType"` attributes.

  See:
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-8.3
  """

  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(%{version: version}, schema, {"contentEncoding", content_encoding}, data, _)
      when version >= 7 do
    {result, data} = validate_content_encoding(content_encoding, data)
    validate_content_media_type(schema, data, result)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp validate_content_encoding("base64", data) when is_bitstring(data) do
    case Base.decode64(data) do
      {:ok, decoded_data} -> {Result.new(), decoded_data}
      :error -> {Result.with_errors([%Error{error: %Error.ContentEncoding{expected: "base64"}}]), data}
    end
  end

  defp validate_content_encoding(_, data) do
    {Result.new(), data}
  end

  defp validate_content_media_type(%{"contentMediaType" => "application/json"}, data, result)
       when is_bitstring(data) do
    case ExJsonSchema.Schema.decode_json(data) do
      {:ok, _} ->
        result

      {:error, _} ->
        result |> Result.add_error(%Error{error: %Error.ContentMediaType{expected: "application/json"}})
    end
  end

  defp validate_content_media_type(_, _, result), do: result
end
