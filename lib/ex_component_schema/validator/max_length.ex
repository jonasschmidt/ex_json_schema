defmodule ExComponentSchema.Validator.MaxLength do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"maxLength"` attributes.

  See:

  """

  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(_, _, {"maxLength", max_length}, data, _) do
    do_validate(max_length, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(max_length, data) when is_bitstring(data) do
    length = String.length(data)

    if length <= max_length do
      []
    else
      [%Error{error: %Error.MaxLength{expected: max_length, actual: length}}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
