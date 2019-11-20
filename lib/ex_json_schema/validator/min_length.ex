defmodule ExJsonSchema.Validator.MinLength do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"minLength"` attributes.

  See:

  """

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(
          root :: Root.t(),
          schema :: ExJsonSchema.data(),
          property :: {String.t(), ExJsonSchema.data()},
          data :: ExJsonSchema.data()
        ) :: Validator.errors()
  def validate(_, _, {"minLength", min_length}, data) do
    do_validate(min_length, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(min_length, data) when is_bitstring(data) do
    length = String.length(data)

    if length >= min_length do
      []
    else
      [%Error{error: %Error.MinLength{expected: min_length, actual: length}, path: ""}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
