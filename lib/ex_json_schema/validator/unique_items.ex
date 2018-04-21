defmodule ExJsonSchema.Validator.UniqueItems do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths

  def validate(_, _, {"uniqueItems", unique_items}, data) do
    do_validate(unique_items, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(true, items) when is_list(items) do
    if Enum.uniq(items) == items do
      []
    else
      [{"Expected items to be unique but they were not.", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
