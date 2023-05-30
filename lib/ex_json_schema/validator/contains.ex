defmodule ExJsonSchema.Validator.Contains do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"contains"` attributes.

  See:
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.14
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.4.6
  """

  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Context
  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root = %{version: version}, _, {"contains", contains}, data, context)
      when version >= 6 do
    do_validate(root, contains, data, context)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(_, _, [], _) do
    Result.with_errors([%Error{error: %Error.Contains{empty?: true, invalid: []}}])
  end

  defp do_validate(root, contains, data, context) when is_list(data) do
    invalid =
      data
      |> Enum.with_index()
      |> Enum.reduce_while([], fn
        {data, index}, acc ->
          case Validator.validation_result(root, contains, data, Context.append_path(context, "/#{index}")) do
            %Result{errors: []} -> {:halt, []}
            result -> {:cont, [{result, index} | acc]}
          end
      end)
      |> Enum.reverse()
      |> Validator.map_to_invalid_errors()

    case Enum.empty?(invalid) do
      true -> Result.new()
      false -> Result.with_errors([%Error{error: %Error.Contains{empty?: false, invalid: invalid}}])
    end
  end

  defp do_validate(_, _, _, _) do
    Result.new()
  end
end
