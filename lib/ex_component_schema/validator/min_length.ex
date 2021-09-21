defmodule ExComponentSchema.Validator.MinLength do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"minLength"` attributes.

  See:

  """

  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(_, _, {"minLength", min_length}, data, _) do
    do_validate(min_length, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(min_length, data) when is_bitstring(data) do
    length = String.length(data)

    if length >= min_length do
      []
    else
      [%Error{error: %Error.MinLength{expected: min_length, actual: length}}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
