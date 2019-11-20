defmodule ExJsonSchema.Validator.Required do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"required"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.4.3
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.17
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.5.3
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
  def validate(_, _, {"required", required}, data) do
    do_validate(required, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(required, data = %{}) do
    case Enum.filter(List.wrap(required), &(!Map.has_key?(data, &1))) do
      [] -> []
      missing -> [%Error{error: %Error.Required{missing: missing}, path: ""}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
