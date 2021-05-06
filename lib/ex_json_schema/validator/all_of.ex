defmodule ExJsonSchema.Validator.AllOf do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"allOf"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.5.3
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.26
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.7.1
  """

  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, _, {"allOf", all_of}, data, path) do
    do_validate(root, all_of, data, path)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(root, all_of, data, path) do
    invalid =
      all_of
      |> Enum.with_index()
      |> Enum.map(fn {schema, index} ->
        {Validator.validation_errors(root, schema, data, path), index}
      end)
      |> Enum.filter(fn {errors, _index} -> !Enum.empty?(errors) end)
      |> Validator.map_to_invalid_errors()

    case Enum.empty?(invalid) do
      true -> []
      false -> [%Error{error: %Error.AllOf{invalid: invalid}, fragment: all_of}]
    end
  end
end
