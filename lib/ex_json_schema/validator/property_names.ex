defmodule ExJsonSchema.Validator.PropertyNames do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"propertyNames"` attributes.

  See:

  """

  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Context
  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, _, {"propertyNames", property_names}, data, context) do
    do_validate(root, property_names, data, context)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(root, property_names, data = %{}, context) do
    invalid =
      data
      |> Enum.flat_map(fn {name, _} ->
        case Validator.validation_result(root, property_names, name, Context.append_path(context, "/#{name}")) do
          %Result{errors: []} -> []
          %Result{errors: errors} -> [{name, errors}]
        end
      end)
      |> Enum.into(%{})

    if map_size(invalid) == 0 do
      Result.new()
    else
      Result.with_errors([%Error{error: %Error.PropertyNames{invalid: invalid}}])
    end
  end

  defp do_validate(_, _, _, _) do
    Result.new()
  end
end
