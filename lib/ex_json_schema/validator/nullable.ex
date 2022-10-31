defmodule ExJsonSchema.Validator.Nullable do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"nullable"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.5.2
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.25
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.1.1
  """

  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(_, _, {"nullable", nullable}, data, _) do
    do_validate(nullable, data)
  end

  def validate(_, _, _, data, _) do
    # by default nullable is not allowed
    nullable = false
    do_validate(nullable, data)
  end

  defp do_validate(nullable, data) do
    if !nil_allowed?(nullable) && is_nil(data) do
      [%Error{error: %Error.Nullable{allowed: false}}]
    else
      []
    end
  end

  defp nil_allowed?(nullable), do: nullable == true
end
