defmodule ExJsonSchema.Validator.ExclusiveMaximum do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"exclusiveMaximum"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.1.2
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.3
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.2.3
  """

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(%Root{version: version}, _, {"exclusiveMaximum", maximum}, data, _)
      when version > 4 do
    do_validate(maximum, data)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(maximum, data) when is_number(data) do
    if data < maximum do
      Result.new()
    else
      Result.with_errors([%Error{error: %Error.Maximum{expected: maximum, exclusive?: true}}])
    end
  end

  defp do_validate(_, _) do
    Result.new()
  end
end
