defmodule ExComponentSchema.Validator.Const do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"anyOf"` attributes.

  See:
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.24
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.1.3
  """

  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(%{version: version}, _, {"const", const}, data, _) when version >= 6 do
    do_validate(const, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(const, data) do
    if const == data do
      []
    else
      [%Error{error: %Error.Const{expected: const}}]
    end
  end
end
