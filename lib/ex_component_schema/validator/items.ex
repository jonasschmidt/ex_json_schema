defmodule ExComponentSchema.Validator.Items do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"items"` attributes.

  See:

  """

  alias ExComponentSchema.Validator
  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(root, schema, {"items", _}, items, path) when is_list(items) do
    do_validate(root, schema, items, path)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(_, %{"items" => true}, _, _) do
    []
  end

  defp do_validate(_, %{"items" => false}, [], _) do
    []
  end

  defp do_validate(_, %{"items" => false}, _, _) do
    [%Error{error: %Error.ItemsNotAllowed{}}]
  end

  defp do_validate(root, %{"items" => schema = %{}}, items, path) when is_list(items) do
    items
    |> Enum.with_index()
    |> Enum.flat_map(fn {item, index} ->
      Validator.validation_errors(root, schema, item, path <> "/#{index}")
    end)
  end

  defp do_validate(
         root,
         %{"items" => schemata, "additionalItems" => additional_items},
         items,
         path
       )
       when is_list(items) and is_list(schemata) do
    validate_items(root, {schemata, additional_items}, items, {[], 0}, path)
    |> Enum.reverse()
    |> List.flatten()
  end

  defp validate_items(_root, {_schemata, _additional_items}, [], {errors, _index}, _), do: errors
  defp validate_items(_root, {[], true}, _items, {errors, _index}, _), do: errors

  defp validate_items(_root, {[], false}, items, {errors, index}, _) do
    [
      %Error{
        error: %Error.AdditionalItems{additional_indices: index..(index + Enum.count(items) - 1)}
      }
      | errors
    ]
  end

  defp validate_items(root, {[], additional_items_schema}, [item | items], {errors, index}, path) do
    acc =
      {[
         Validator.validation_errors(root, additional_items_schema, item, path <> "/#{index}")
         | errors
       ], index + 1}

    validate_items(root, {[], additional_items_schema}, items, acc, path)
  end

  defp validate_items(
         root,
         {[schema | schemata], additional_items},
         [item | items],
         {errors, index},
         path
       ) do
    acc =
      {[Validator.validation_errors(root, schema, item, path <> "/#{index}") | errors], index + 1}

    validate_items(root, {schemata, additional_items}, items, acc, path)
  end
end
