defmodule ExComponentSchema.Validator.MultipleOf do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"multipleOf"` attributes.

  See:

  """

  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator
  @zero Decimal.new(0)

  @impl ExComponentSchema.Validator
  def validate(_, _, {"multipleOf", multiple_of}, data, _) do
    do_validate(multiple_of, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(multiple_of, data) when is_number(multiple_of) and is_number(data) do
    dec_multiple_of = dec(multiple_of)
    dec_data = dec(data)

    cond do
      dec_multiple_of == @zero -> [%Error{error: %Error.MultipleOf{expected: 0}}]
      dec_data == @zero -> []
      Decimal.integer?(Decimal.div(dec_data, dec_multiple_of)) -> []
      true -> [%Error{error: %Error.MultipleOf{expected: multiple_of}}]
    end
  end

  defp do_validate(_, _) do
    []
  end

  defp dec(number) do
    if is_float(number) do
      Decimal.from_float(number)
    else
      Decimal.new(number)
    end
  end
end
