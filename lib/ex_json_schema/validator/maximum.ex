defmodule ExJsonSchema.Validator.Maximum do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"maximum"` attributes.

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
  def validate(%Root{version: 4}, schema, {"maximum", maximum}, data) do
    exclusive = Map.get(schema, "exclusiveMaximum", false)
    do_validate(maximum, exclusive, data)
  end

  def validate(_, _, {"maximum", maximum}, data) do
    do_validate(maximum, false, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(maximum, exclusive, data) when is_number(data) do
    valid = if exclusive, do: data < maximum, else: data <= maximum

    if valid do
      []
    else
      [%Error{error: %Error.Maximum{expected: maximum, exclusive?: exclusive}, path: ""}]
    end
  end

  defp do_validate(_, _, _) do
    []
  end
end
