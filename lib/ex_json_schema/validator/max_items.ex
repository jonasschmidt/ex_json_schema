defmodule ExJsonSchema.Validator.MaxItems do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"maxItems"` attributes.

  See:

  """

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(
          root :: Root.t(),
          schema :: ExJsonSchema.data(),
          property :: {String.t(), ExJsonSchema.data()},
          data :: ExJsonSchema.data()
        ) :: Validator.errors_with_list_paths()
  def validate(_, _, {"maxItems", max_items}, data) do
    do_validate(max_items, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(max_items, items) when is_list(items) do
    count = Enum.count(items)

    if count <= max_items do
      []
    else
      [{"Expected a maximum of #{max_items} items but got #{count}.", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
