defmodule ExJsonSchema.Validator.PropertyNames do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"propertyNames"` attributes.

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
  def validate(root, _, {"propertyNames", property_names}, data) do
    do_validate(root, property_names, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(_, false, data = %{}) do
    if Map.size(data) == 0 do
      []
    else
      [{"Expected data to not have any keys.", []}]
    end
  end

  defp do_validate(root, property_names = %{}, data = %{}) do
    valid? =
      Enum.all?(data, fn {name, _} ->
        Validator.valid?(root, property_names, name)
      end)

    if valid? do
      []
    else
      [{"Expected data keys to match propertyNames but they don't.", []}]
    end
  end

  defp do_validate(_, _, _) do
    []
  end
end
