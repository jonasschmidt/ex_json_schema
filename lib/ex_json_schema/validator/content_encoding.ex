defmodule ExJsonSchema.Validator.ContentEncoding do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"contentEncoding"` attributes.

  See:
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-8.3
  """

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(
          root :: Root.t(),
          schema :: ExJsonSchema.data(),
          property :: {String.t(), ExJsonSchema.data()},
          data :: ExJsonSchema.data()
        ) :: Validator.errors()
  def validate(%{version: version}, _, {"contentEncoding", content_encoding}, data)
      when version >= 7 do
    do_validate(content_encoding, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate("base64", data) when is_bitstring(data) do
    case Base.decode64(data) do
      {:ok, _} ->
        []

      :error ->
        [%Error{error: %{message: "Invalid base64 string."}, path: ""}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
