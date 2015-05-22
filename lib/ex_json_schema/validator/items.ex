defmodule ExJsonSchema.Validator.Items do
  alias ExJsonSchema.Validator, as: Validator

  def valid?(root, %{"items" => schema = %{}}, items) when is_list(items) do
    Enum.all? items, &Validator.valid?(root, schema, &1)
  end

  def valid?(root, %{"items" => schemata, "additionalItems" => additional_items}, items) when is_list(items) and is_list(schemata) do
    items
    |> Enum.with_index
    |> Enum.all? fn {item, index} ->
      schema = Enum.at(schemata, index, additional_items_schema(additional_items))
      Validator.valid?(root, schema, item)
    end
  end

  def valid?(_, _, _), do: true

  defp additional_items_schema(schema = %{}), do: schema
  defp additional_items_schema(true), do: %{}
  defp additional_items_schema(_), do: nil
end
