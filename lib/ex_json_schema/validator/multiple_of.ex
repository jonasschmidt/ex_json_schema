defmodule ExJsonSchema.Validator.MultipleOf do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"multipleOf"` attributes.

  See:

  """

  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator
  @zero Decimal.new(0)

  @impl ExJsonSchema.Validator
  def validate(_, _, {"multipleOf", multiple_of}, data, _) do
    do_validate(multiple_of, data)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(multiple_of, data) when is_number(multiple_of) and is_number(data) do
    dec_multiple_of = dec(multiple_of)
    dec_data = dec(data)

    cond do
      dec_multiple_of == @zero -> Result.with_errors([%Error{error: %Error.MultipleOf{expected: 0}}])
      dec_data == @zero -> Result.new()
      Decimal.equal?(Decimal.rem(dec_data, dec_multiple_of), Decimal.new(0)) -> Result.new()
      true -> Result.with_errors([%Error{error: %Error.MultipleOf{expected: multiple_of}}])
    end
  rescue
    Decimal.Error -> Result.with_errors([%Error{error: %Error.MultipleOf{expected: multiple_of}}])
  end

  defp do_validate(_, _) do
    Result.new()
  end

  defp dec(number) do
    if is_float(number) do
      Decimal.from_float(number)
    else
      Decimal.new(number)
    end
  end
end
