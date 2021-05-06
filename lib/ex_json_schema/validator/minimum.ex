defmodule ExJsonSchema.Validator.Minimum do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"minimum"` attributes.

  See:

  """

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(%Root{version: 4}, schema, {"minimum", minimum}, data, _) do
    exclusive = Map.get(schema, "exclusiveMinimum", false)
    do_validate(minimum, exclusive, data)
  end

  def validate(_, _, {"minimum", minimum}, data, _) do
    do_validate(minimum, false, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(minimum, exclusive, data) when is_number(data) do
    valid = if exclusive, do: data > minimum, else: data >= minimum

    if valid do
      []
    else
      [%Error{error: %Error.Minimum{expected: minimum, exclusive?: exclusive}, fragment: minimum}]
    end
  end

  defp do_validate(_, _, _) do
    []
  end
end
