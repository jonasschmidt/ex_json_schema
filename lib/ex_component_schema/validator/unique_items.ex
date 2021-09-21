defmodule ExComponentSchema.Validator.UniqueItems do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"uniqueItems"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.3.4
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.13
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.4.5
  """

  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(_, _, {"uniqueItems", unique_items}, data, _) do
    do_validate(unique_items, data)
  end

  def validate(_, _, _, _, _) do
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
      [%Error{error: %Error.UniqueItems{}}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
