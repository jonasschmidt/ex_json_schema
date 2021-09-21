defmodule ExComponentSchema.Validator.Maximum do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"maximum"` attributes.

  See:

  """

  alias ExComponentSchema.Schema.Root
  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(%Root{version: 4}, schema, {"maximum", maximum}, data, _) do
    exclusive = Map.get(schema, "exclusiveMaximum", false)
    do_validate(maximum, exclusive, data)
  end

  def validate(_, _, {"maximum", maximum}, data, _) do
    do_validate(maximum, false, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(maximum, exclusive, data) when is_number(data) do
    valid = if exclusive, do: data < maximum, else: data <= maximum

    if valid do
      []
    else
      [%Error{error: %Error.Maximum{expected: maximum, exclusive?: exclusive}}]
    end
  end

  defp do_validate(_, _, _) do
    []
  end
end
