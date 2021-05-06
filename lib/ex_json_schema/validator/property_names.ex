defmodule ExJsonSchema.Validator.PropertyNames do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"propertyNames"` attributes.

  See:

  """

  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, _, {"propertyNames", property_names}, data, path) do
    do_validate(root, property_names, data, path)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(root, property_names, data = %{}, path) do
    invalid =
      data
      |> Enum.flat_map(fn {name, _} ->
        case Validator.validation_errors(root, property_names, name, path <> "/#{name}") do
          [] -> []
          errors -> [{name, errors}]
        end
      end)
      |> Enum.into(%{})

    if map_size(invalid) == 0 do
      []
    else
      [%Error{error: %Error.PropertyNames{invalid: invalid}, fragment: property_names}]
    end
  end

  defp do_validate(_, _, _, _) do
    []
  end
end
