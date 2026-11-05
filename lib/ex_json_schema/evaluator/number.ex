defmodule ExJsonSchema.Evaluator.Number do
  @moduledoc false

  # Implements exact divisibility for Elixir integers and the shortest decimal
  # representation of Elixir floats without a fixed-precision decimal context.

  @spec multiple_of?(number(), number()) :: boolean()
  def multiple_of?(number, divisor)
      when is_integer(number) and is_integer(divisor) and divisor > 0,
      do: rem(number, divisor) == 0

  def multiple_of?(number, divisor)
      when is_number(number) and is_number(divisor) and divisor > 0 do
    {number_coefficient, number_exponent} = decimal_parts(number)
    {divisor_coefficient, divisor_exponent} = decimal_parts(divisor)
    exponent = number_exponent - divisor_exponent

    if exponent >= 0 do
      rem(
        number_coefficient * Integer.pow(10, exponent),
        divisor_coefficient
      ) == 0
    else
      rem(
        number_coefficient,
        divisor_coefficient * Integer.pow(10, -exponent)
      ) == 0
    end
  end

  def multiple_of?(_number, _divisor), do: false

  defp decimal_parts(number) when is_integer(number), do: {abs(number), 0}

  defp decimal_parts(number) when is_float(number) do
    number
    |> abs()
    |> Float.to_string()
    |> split_exponent()
    |> decimal_parts_from_string()
  end

  defp split_exponent(value) do
    case :binary.match(value, ["e", "E"]) do
      {position, 1} ->
        mantissa = binary_part(value, 0, position)
        exponent = binary_part(value, position + 1, byte_size(value) - position - 1)
        {mantissa, String.to_integer(exponent)}

      :nomatch ->
        {value, 0}
    end
  end

  defp decimal_parts_from_string({mantissa, exponent}) do
    case :binary.match(mantissa, ".") do
      {position, 1} ->
        integer = binary_part(mantissa, 0, position)
        fraction = binary_part(mantissa, position + 1, byte_size(mantissa) - position - 1)
        {String.to_integer(integer <> fraction), exponent - byte_size(fraction)}

      :nomatch ->
        {String.to_integer(mantissa), exponent}
    end
  end
end
