defmodule ExJsonSchema.Evaluator.Format.URITemplate do
  @moduledoc false

  # Validates RFC 6570 URI-template syntax without expanding variables or
  # allocating expansion state.

  @operators ~c"+#./;?&=,!@|"

  @spec valid?(binary()) :: boolean()
  def valid?(template) when is_binary(template), do: valid_template?(template)

  defp valid_template?(<<>>), do: true

  defp valid_template?(<<"{", rest::binary>>) do
    case :binary.match(rest, "}") do
      {length, 1} ->
        expression = binary_part(rest, 0, length)
        remaining = binary_part(rest, length + 1, byte_size(rest) - length - 1)
        valid_expression?(expression) and valid_template?(remaining)

      :nomatch ->
        false
    end
  end

  defp valid_template?(<<"}", _rest::binary>>), do: false

  defp valid_template?(<<"%", high, low, rest::binary>>) do
    hex_digit?(high) and hex_digit?(low) and valid_template?(rest)
  end

  defp valid_template?(<<character::utf8, rest::binary>>) do
    literal_character?(character) and valid_template?(rest)
  end

  defp valid_template?(_invalid_utf8), do: false

  defp valid_expression?(<<>>), do: false

  defp valid_expression?(<<operator, variables::binary>>) when operator in @operators,
    do: valid_variable_list?(variables)

  defp valid_expression?(variables), do: valid_variable_list?(variables)

  defp valid_variable_list?(<<>>), do: false

  defp valid_variable_list?(variables) do
    variables
    |> :binary.split(",", [:global])
    |> Enum.all?(&valid_varspec?/1)
  end

  defp valid_varspec?(varspec) do
    if String.ends_with?(varspec, "*") do
      name = binary_part(varspec, 0, byte_size(varspec) - 1)
      valid_varname?(name)
    else
      case :binary.split(varspec, ":", [:global]) do
        [name] -> valid_varname?(name)
        [name, prefix] -> valid_varname?(name) and valid_prefix?(prefix)
        _multiple_prefixes -> false
      end
    end
  end

  defp valid_varname?(<<>>), do: false

  defp valid_varname?(name) do
    name
    |> :binary.split(".", [:global])
    |> Enum.all?(&valid_varname_segment?/1)
  end

  defp valid_varname_segment?(<<>>), do: false
  defp valid_varname_segment?(segment), do: valid_varchars?(segment)

  defp valid_varchars?(<<>>), do: true

  defp valid_varchars?(<<"%", high, low, rest::binary>>) do
    hex_digit?(high) and hex_digit?(low) and valid_varchars?(rest)
  end

  defp valid_varchars?(<<character, rest::binary>>)
       when character in ?A..?Z or character in ?a..?z or character in ?0..?9 or
              character == ?_ do
    valid_varchars?(rest)
  end

  defp valid_varchars?(_invalid), do: false

  defp valid_prefix?(<<first, rest::binary>>)
       when first in ?1..?9 and byte_size(rest) <= 3 do
    ascii_digits?(rest)
  end

  defp valid_prefix?(_prefix), do: false

  defp ascii_digits?(<<>>), do: true
  defp ascii_digits?(<<digit, rest::binary>>) when digit in ?0..?9, do: ascii_digits?(rest)
  defp ascii_digits?(_value), do: false

  defp hex_digit?(digit),
    do: digit in ?0..?9 or digit in ?A..?F or digit in ?a..?f

  defp literal_character?(character)
       when character == 0x21 or character in 0x23..0x24 or
              character in 0x26..0x3B or character == 0x3D or
              character in 0x3F..0x5B or character == 0x5D or
              character == 0x5F or character in 0x61..0x7A or
              character == 0x7E,
       do: true

  defp literal_character?(character) do
    character in 0xA0..0xD7FF or
      character in 0xE000..0xF8FF or
      character in 0xF900..0xFDCF or
      character in 0xFDF0..0xFFEF or
      character in 0x10000..0x1FFFD or
      character in 0x20000..0x2FFFD or
      character in 0x30000..0x3FFFD or
      character in 0x40000..0x4FFFD or
      character in 0x50000..0x5FFFD or
      character in 0x60000..0x6FFFD or
      character in 0x70000..0x7FFFD or
      character in 0x80000..0x8FFFD or
      character in 0x90000..0x9FFFD or
      character in 0xA0000..0xAFFFD or
      character in 0xB0000..0xBFFFD or
      character in 0xC0000..0xCFFFD or
      character in 0xD0000..0xDFFFD or
      character in 0xE1000..0xEFFFD or
      character in 0xF0000..0xFFFFD or
      character in 0x100000..0x10FFFD
  end
end
