defmodule ExJsonSchema.Validator.Items do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"items"` attributes.

  See:

  """

  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Context
  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, schema, {"items", _}, items, context) when is_list(items) do
    do_validate(root, schema, items, context)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(_, %{"items" => true}, _, _) do
    Result.new()
  end

  defp do_validate(_, %{"items" => false}, [], _) do
    Result.new()
  end

  defp do_validate(_, %{"items" => false}, _, _) do
    Result.with_errors([%Error{error: %Error.ItemsNotAllowed{}}])
  end

  defp do_validate(root, %{"items" => schema = %{}}, items, context) when is_list(items) do
    items
    |> Enum.with_index()
    |> Enum.reduce(Result.new(), fn {item, index}, acc ->
      Result.merge(acc, Validator.validation_result(root, schema, item, Context.append_path(context, "/#{index}")))
    end)
  end

  defp do_validate(
         root,
         %{"items" => schemata, "additionalItems" => additional_items},
         items,
         context
       )
       when is_list(items) and is_list(schemata) do
    validate_items(root, {schemata, additional_items}, items, {Result.new(), 0}, context)
  end

  defp validate_items(_root, {_schemata, _additional_items}, [] = _items, {result, _index}, _), do: result
  defp validate_items(_root, {[], true}, _items, {result, _index}, _), do: result

  defp validate_items(_root, {[], false}, items, {result, index}, _) do
    result
    |> Result.add_error(%Error{
      error: %Error.AdditionalItems{additional_indices: index..(index + Enum.count(items) - 1)}
    })
  end

  defp validate_items(root, {[], additional_items_schema}, [item | items], {result, index}, context) do
    acc =
      {Result.merge(
         result,
         Validator.validation_result(root, additional_items_schema, item, Context.append_path(context, "/#{index}"))
       ), index + 1}

    validate_items(root, {[], additional_items_schema}, items, acc, context)
  end

  defp validate_items(
         root,
         {[schema | schemata], additional_items},
         [item | items],
         {result, index},
         context
       ) do
    acc =
      {Result.merge(result, Validator.validation_result(root, schema, item, Context.append_path(context, "/#{index}"))),
       index + 1}

    validate_items(root, {schemata, additional_items}, items, acc, context)
  end
end
