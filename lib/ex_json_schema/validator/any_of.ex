defmodule ExJsonSchema.Validator.AnyOf do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"anyOf"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.5.4
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.27
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.7.2
  """

  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, _, {"anyOf", any_of}, data, path) do
    do_validate(root, any_of, data, path)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(root, any_of, data, path) when is_list(any_of) do
    invalid =
      any_of
      |> Enum.with_index()
      |> Enum.reduce_while([], fn
        {schema, index}, acc ->
          case Validator.validation_result(root, schema, data, path) do
            %Result{errors: []} -> {:halt, []}
            result -> {:cont, [{result, index} | acc]}
          end
      end)
      |> Enum.reverse()
      |> Validator.map_to_invalid_errors()

    case Enum.empty?(invalid) do
      true -> Result.new()
      false -> Result.with_errors([%Error{error: %Error.AnyOf{invalid: invalid}}])
    end
  end

  defp do_validate(_, _, _, _) do
    Result.new()
  end
end
