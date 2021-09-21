defmodule ExComponentSchema.Validator.Pattern do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"pattern"` attributes.

  See:

  """

  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
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
      [%Error{error: %Error.Pattern{expected: pattern}}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
