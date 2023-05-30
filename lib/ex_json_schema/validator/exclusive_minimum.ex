defmodule ExJsonSchema.Validator.ExclusiveMinimum do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"exclusiveMinimum"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.1.3
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.5
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.2.5
  """

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(%Root{version: version}, _, {"exclusiveMinimum", minimum}, data, _)
      when version > 4 do
    do_validate(minimum, data)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(true, data) do
    do_validate(1, data)
  end

  defp do_validate(minimum, data) when is_number(data) do
    if data > minimum do
      Result.new()
    else
      Result.with_errors([%Error{error: %Error.Minimum{expected: minimum, exclusive?: true}}])
    end
  end

  defp do_validate(_, _) do
    Result.new()
  end
end
