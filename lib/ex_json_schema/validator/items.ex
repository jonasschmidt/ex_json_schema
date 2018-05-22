defmodule ExJsonSchema.Validator.Items do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"items"` attributes.

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
  def validate(root, schema, {"additionalItems", _}, data) do
    do_validate(root, schema, data)
  end

  def validate(root, schema, {"items", _}, data) do
    do_validate(root, Map.put_new(schema, "additionalItems", true), data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(_, %{"items" => true}, _) do
    []
  end

  defp do_validate(_, %{"items" => false}, []) do
    []
  end

  defp do_validate(_, %{"items" => false}, _) do
    [{"Schema does not allow items.", []}]
  end

  defp do_validate(root, %{"items" => schemata, "additionalItems" => false}, items)
       when is_list(items) and is_list(schemata) do
    cond do
      Enum.count(schemata) < Enum.count(items) ->
        Enum.map(items, fn _ ->
          {"Schema does not allow additional items", []}
        end)

      Enum.empty?(additional_items(root, schemata, items)) ->
        []

      true ->
        [{"Expected items to match schema but they didn't.", []}]
    end
  end

  defp do_validate(root, %{"items" => schema = %{}, "additionalItems" => false}, items)
       when is_list(items) do
    additional_items =
      items
      |> Enum.with_index()
      |> Enum.reject(fn {item, index} ->
        root
        |> validate_item(schema, item, index)
        |> Enum.empty?()
      end)

    if Enum.empty?(additional_items) do
      []
    else
      [{"Expected no additional items but had #{inspect(additional_items)}", []}]
    end
  end

  defp do_validate(root, %{"items" => schemata, "additionalItems" => additional_items}, items)
       when is_list(items) and is_list(schemata) do
    items
    |> Enum.with_index()
    |> Enum.flat_map(fn {item, index} ->
      schema = Enum.at(schemata, index, additional_items_schema(additional_items))
      validate_item(root, schema, item, index)
    end)
  end

  defp do_validate(root, %{"items" => schema = %{}}, items) when is_list(items) do
    items
    |> Enum.with_index()
    |> Enum.flat_map(fn {item, index} ->
      validate_item(root, schema, item, index)
    end)
  end

  defp do_validate(root, %{"items" => schema}, items) when is_list(items) and is_list(schema) do
    items
    |> Enum.with_index()
    |> Enum.flat_map(fn {item, index} ->
      validate_item(root, schema, item, index)
    end)
  end

  defp do_validate(_, %{"items" => _}, _) do
    []
  end

  defp do_validate(_, _, _), do: []

  defp validate_item(_, nil, _, _) do
    [{"Schema does not allow additional items.", []}]
  end

  defp validate_item(_, true, _, _) do
    []
  end

  defp validate_item(_, false, _, index) do
    [{"Schema does not allow this value.", [index]}]
  end

  defp validate_item(root, schema, item, index) do
    Validator.validate(root, schema, item, [index])
  end

  defp valid_item?(root, schema, item, index) do
    root
    |> validate_item(schema, item, index)
    |> Enum.empty?()
  end

  defp additional_items_schema(schema = %{}), do: schema
  defp additional_items_schema(true), do: %{}
  defp additional_items_schema(_), do: nil

  defp additional_items(root, schemata, items) do
    items
    |> Enum.with_index()
    |> Enum.reject(fn {item, index} ->
      schema = Enum.at(schemata, index)
      schema == true || valid_item?(root, schema, item, index)
    end)
  end
end
