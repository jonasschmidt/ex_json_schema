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
  def validate(_, _, {"maximum", maximum}, data) do
    do_validate(maximum, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(maximum, data) when is_number(data) do
    if data <= maximum do
      []
    else
      [%Error{error: %Error.Maximum{expected: maximum, exclusive?: false}, path: ""}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
