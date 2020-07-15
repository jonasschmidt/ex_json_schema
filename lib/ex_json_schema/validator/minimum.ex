defmodule ExJsonSchema.Validator.Minimum do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"minimum"` attributes.

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
  def validate(%Root{version: 4}, schema, {"minimum", minimum}, data) do
    exclusive = Map.get(schema, "exclusiveMinimum", false)
    do_validate(minimum, exclusive, data)
  end

  def validate(_, _, {"minimum", minimum}, data) do
    do_validate(minimum, false, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(minimum, exclusive, data) when is_number(data) do
    valid = if exclusive, do: data > minimum, else: data >= minimum

    if valid do
      []
    else
      [%Error{error: %Error.Minimum{expected: minimum, exclusive?: exclusive}, path: ""}]
    end
  end

  defp do_validate(_, _, _) do
    []
  end
end
