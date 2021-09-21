defmodule ExComponentSchema.Validator.ExclusiveMinimum do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"exclusiveMinimum"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.1.3
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.5
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.2.5
  """

  alias ExComponentSchema.Schema.Root
  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(%Root{version: version}, _, {"exclusiveMinimum", minimum}, data, _)
      when version > 4 do
    do_validate(minimum, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(true, data) do
    do_validate(1, data)
  end

  defp do_validate(minimum, data) when is_number(data) do
    if data > minimum do
      []
    else
      [%Error{error: %Error.Minimum{expected: minimum, exclusive?: true}}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
