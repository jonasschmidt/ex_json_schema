defmodule ExJsonSchema.Validator.MinItems do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"minItems"` attributes.

  See:

  """

  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(_, _, {"minItems", min_items}, data, _) do
    do_validate(min_items, data)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(min_items, items) when is_list(items) do
    count = Enum.count(items)

    if count >= min_items do
      Result.new()
    else
      Result.with_errors([%Error{error: %Error.MinItems{expected: min_items, actual: count}}])
    end
  end

  defp do_validate(_, _) do
    Result.new()
  end
end
