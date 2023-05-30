defmodule ExJsonSchema.Validator.OneOf do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"oneOf"` attributes.

  See:

  """

  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, _, {"oneOf", one_of}, data, path) do
    do_validate(root, one_of, data, path)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(root, one_of, data, path) do
    {valid_count, valid_indices, results} =
      one_of
      |> Enum.with_index()
      |> Enum.reduce({0, [], []}, fn
        {schema, index}, {valid_count, valid_indices, results} ->
          case Validator.validation_result(root, schema, data, path) do
            %Result{errors: []} -> {valid_count + 1, [index | valid_indices], results}
            result -> {valid_count, valid_indices, [{result, index} | results]}
          end
      end)

    case valid_count do
      1 ->
        Result.new()

      0 ->
        Result.with_errors([
          %Error{
            error: %Error.OneOf{
              valid_indices: [],
              invalid: results |> Enum.reverse() |> Validator.map_to_invalid_errors()
            }
          }
        ])

      _ ->
        Result.with_errors([%Error{error: %Error.OneOf{valid_indices: Enum.reverse(valid_indices), invalid: []}}])
    end
  end
end
