defmodule ExComponentSchema.Validator.PropertyNames do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"propertyNames"` attributes.

  See:

  """

  alias ExComponentSchema.Validator
  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
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
      [%Error{error: %Error.PropertyNames{invalid: invalid}}]
    end
  end

  defp do_validate(_, _, _, _) do
    []
  end
end
