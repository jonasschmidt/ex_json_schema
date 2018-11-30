defmodule ExJsonSchema.Validator.Items do
  alias ExJsonSchema.Schema
  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error

  @spec validate(Root.t(), Schema.resolved(), ExJsonSchema.data()) ::
          Validator.errors() | no_return
  def validate(root, %{"items" => schema = %{}}, items) when is_list(items) do
    items
    |> Enum.with_index()
    |> Enum.flat_map(fn {item, index} ->
      Validator.validation_errors(root, schema, item, "/#{index}")
    end)
  end

  def validate(root, %{"items" => schemata, "additionalItems" => additional_items}, items)
      when is_list(items) and is_list(schemata) do
    validate_items(root, {schemata, additional_items}, items, {[], 0})
    |> Enum.reverse()
    |> List.flatten()
  end

  def validate(_, _, _), do: []

  defp validate_items(_root, {_schemata, _additional_items}, [], {errors, _index}), do: errors
  defp validate_items(_root, {[], true}, _items, {errors, _index}), do: errors

  defp validate_items(_root, {[], false}, items, {errors, index}) do
    [
      %Error{
        error: %Error.AdditionalItems{additional_indices: index..(index + Enum.count(items) - 1)},
        path: ""
      }
      | errors
    ]
  end

  defp validate_items(root, {[], additional_items_schema}, [item | items], {errors, index}) do
    acc =
      {[Validator.validation_errors(root, additional_items_schema, item, "/#{index}") | errors],
       index + 1}

    validate_items(root, {[], additional_items_schema}, items, acc)
  end

  defp validate_items(
         root,
         {[schema | schemata], additional_items},
         [item | items],
         {errors, index}
       ) do
    acc = {[Validator.validation_errors(root, schema, item, "/#{index}") | errors], index + 1}
    validate_items(root, {schemata, additional_items}, items, acc)
  end
end
