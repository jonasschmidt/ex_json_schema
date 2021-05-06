defmodule ExJsonSchema.Validator.Pattern do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"pattern"` attributes.

  See:

  """

  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(_, _, {"pattern", pattern}, data, _) do
    do_validate(pattern, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(pattern, data) when is_bitstring(data) do
    matches? =
      pattern
      |> Regex.compile!()
      |> Regex.match?(data)

    if matches? do
      []
    else
      [%Error{error: %Error.Pattern{expected: pattern}, fragment: pattern}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
