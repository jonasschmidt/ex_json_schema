defmodule ExJsonSchema.Validator.UniqueItems do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"uniqueItems"` attributes.

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
  def validate(_, _, {"uniqueItems", unique_items}, data) do
    do_validate(unique_items, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(true, items) when is_list(items) do
    unique? =
      items
      |> Enum.uniq()
      |> Enum.count()
      |> Kernel.==(Enum.count(items))

    if unique? do
      []
    else
      [{"Expected items to be unique but they were not.", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
