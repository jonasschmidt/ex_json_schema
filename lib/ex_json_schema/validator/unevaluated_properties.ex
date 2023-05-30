defmodule ExJsonSchema.Validator.UnevaluatedProperties do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"unevaluatedProperties"` attributes.

  See:
  """

  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Context
  alias ExJsonSchema.Validator.Result
  # alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, _, {"unevaluatedProperties", unevaluated_properties}, data, context) do
    do_validate(root, unevaluated_properties, data, context)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  # defp do_validate(_root, false, data, context) do
  #   case Enum.any?(data, fn {name, _} -> !Map.has_key?(context.result.annotations, name) end) do
  #     true -> Result.with_errors([%Error{error: nil}])
  #     false -> Result.new()
  #   end
  # end

  defp do_validate(root, schema, data, context) when is_map(data) do
    unevaluated_properties = Map.drop(data, Map.keys(context.result.annotations))

    unevaluated_properties
    |> Enum.reduce(Result.new(), fn {name, data}, acc ->
      case Validator.validation_result(root, schema, data, Context.append_path(context, "/#{name}")) do
        %Result{errors: []} -> acc
        result -> Result.merge(acc, result)
      end
    end)
  end

  defp do_validate(_, _, _, _) do
    Result.new()
  end
end
