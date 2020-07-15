defmodule ExJsonSchema.Validator.MaxLength do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"maxLength"` attributes.

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
  def validate(_, _, {"maxLength", max_length}, data) do
    do_validate(max_length, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(max_length, data) when is_bitstring(data) do
    length = String.length(data)

    if length <= max_length do
      []
    else
      [%Error{error: %Error.MaxLength{expected: max_length, actual: length}, path: ""}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
