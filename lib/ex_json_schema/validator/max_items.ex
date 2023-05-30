defmodule ExJsonSchema.Validator.MaxItems do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"maxItems"` attributes.

  See:

  """

  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(_, _, {"maxItems", max_items}, data, _) do
    do_validate(max_items, data)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(max_items, items) when is_list(items) do
    count = Enum.count(items)

    if count <= max_items do
      Result.new()
    else
      Result.with_errors([%Error{error: %Error.MaxItems{expected: max_items, actual: count}}])
    end
  end

  defp do_validate(_, _) do
    Result.new()
  end
end
