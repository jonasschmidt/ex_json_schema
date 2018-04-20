defmodule ExJsonSchema.Validator.Items do
  alias ExJsonSchema.{Schema, Validator}
  alias ExJsonSchema.Schema.Root

  @spec validate(Root.t, Schema.resolved, ExJsonSchema.data) :: Validator.errors_with_list_paths
  def validate(root, %{"items" => schema = %{}}, items) when is_list(items) do
    items
    |> Enum.with_index
    |> Enum.flat_map(fn {item, index} ->
      Validator.validate(root, schema, item, [index])
    end)
  end

  def validate(root, %{"items" => schemata, "additionalItems" => additional_items}, items) when is_list(items) and is_list(schemata) do
    items
    |> Enum.with_index
    |> Enum.flat_map(fn {item, index} ->
      schema = Enum.at(schemata, index, additional_items_schema(additional_items))
      validate_item(root, schema, item, index)
    end)
  end

  def validate(_, _, _), do: []

  defp validate_item(_, nil, _, index) do
    [{"Schema does not allow additional items.", [index]}]
  end

  defp validate_item(root, schema, item, index) do
    Validator.validate(root, schema, item, [index])
  end

  defp additional_items_schema(schema = %{}), do: schema
  defp additional_items_schema(true), do: %{}
  defp additional_items_schema(_), do: nil
end
