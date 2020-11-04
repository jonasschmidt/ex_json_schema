defmodule ExJsonSchema.Validator.ContentMediaType do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"contentMediaType"` attributes.

  See:
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-8.4
  """

  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(%{version: version}, schema, {"contentMediaType", content_media_type}, data, _)
      when version >= 7 do
    do_validate(schema, content_media_type, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(%{"contentEncoding" => "base64"}, "application/json", data)
       when is_bitstring(data) do
    with {:ok, json} <- Base.decode64(data),
         {:ok, _} <- ExJsonSchema.Schema.decode_json(json) do
      []
    else
      _ ->
        [
          %Error{
            error: %Error.ContentMediaType{expected: "application/json", encoding_valid?: true}
          }
        ]
    end
  end

  defp do_validate(_, "application/json", data) when is_bitstring(data) do
    case ExJsonSchema.Schema.decode_json(data) do
      {:ok, _} ->
        []

      {:error, _} ->
        [
          %Error{
            error: %Error.ContentMediaType{expected: "application/json", encoding_valid?: false}
          }
        ]
    end
  end

  defp do_validate(_, _, _) do
    []
  end
end
