defmodule ExJsonSchema.Validator.PropertyNames do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"propertyNames"` attributes.

  See:

  """

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, _, {"propertyNames", property_names}, data, _) do
    do_validate(root, property_names, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(root, property_names, data = %{}) do
    valid? =
      Enum.all?(data, fn {name, _} ->
        Validator.valid_fragment?(root, property_names, name)
      end)

    if valid? do
      []
    else
      [%Error{error: %{message: "Expected data keys to match propertyNames but they don't."}}]
    end
  end

  defp do_validate(_, _, _) do
    []
  end
end
