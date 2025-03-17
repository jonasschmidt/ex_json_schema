defmodule ExJsonSchema.Validator.AllOf do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"allOf"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.5.3
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.26
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.7.1
  """

  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, _, {"allOf", all_of}, data, path) do
    do_validate(root, all_of, data, path)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(root, all_of, data, path) do
    results =
      all_of
      |> Enum.with_index()
      |> Enum.map(fn {schema, index} ->
        {Validator.validation_result(root, schema, data, path), index}
      end)

    invalid =
      results
      |> Enum.filter(fn {result, _index} -> !Result.valid?(result) end)
      |> Validator.map_to_invalid_errors()

    result =
      results
      |> Enum.reduce(Result.new(), fn {result, _}, acc ->
        acc |> Result.merge_annotations(result)
      end)

    case Enum.empty?(invalid) do
      true -> result
      false -> result |> Result.add_error(%Error{error: %Error.AllOf{invalid: invalid}})
    end
  end
end
