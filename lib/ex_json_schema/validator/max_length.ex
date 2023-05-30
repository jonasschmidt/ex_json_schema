defmodule ExJsonSchema.Validator.MaxLength do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"maxLength"` attributes.

  See:

  """

  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(_, _, {"maxLength", max_length}, data, _) do
    do_validate(max_length, data)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(max_length, data) when is_bitstring(data) do
    length = String.length(data)

    if length <= max_length do
      Result.new()
    else
      Result.with_errors([%Error{error: %Error.MaxLength{expected: max_length, actual: length}}])
    end
  end

  defp do_validate(_, _) do
    Result.new()
  end
end
