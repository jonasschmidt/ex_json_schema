defmodule ExJsonSchema.Validator.MinLength do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"minLength"` attributes.

  See:

  """

  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(_, _, {"minLength", min_length}, data, _) do
    do_validate(min_length, data)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(min_length, data) when is_bitstring(data) do
    length = String.length(data)

    if length >= min_length do
      Result.new()
    else
      Result.with_errors([%Error{error: %Error.MinLength{expected: min_length, actual: length}}])
    end
  end

  defp do_validate(_, _) do
    Result.new()
  end
end
