defmodule ExComponentSchema.Validator.MinItems do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"minItems"` attributes.

  See:

  """

  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(_, _, {"minItems", min_items}, data, _) do
    do_validate(min_items, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(min_items, items) when is_list(items) do
    count = Enum.count(items)

    if count >= min_items do
      []
    else
      [%Error{error: %Error.MinItems{expected: min_items, actual: count}}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
