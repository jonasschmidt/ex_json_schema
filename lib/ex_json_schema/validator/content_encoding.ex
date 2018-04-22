defmodule ExJsonSchema.Validator.ContentEncoding do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"contains"` attributes.

  See:
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.14
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.4.6
  """

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths
  def validate(root, _, {"contentEncoding", content_encoding}, data) do
    do_validate(content_encoding, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate("base64", data) do
    case Base.decode64(data) do
      {:ok, _} ->
        []
      :error ->
        [{"Invalid base64 string.", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
