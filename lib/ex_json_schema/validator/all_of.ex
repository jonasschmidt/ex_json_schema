defmodule ExJsonSchema.Validator.AllOf do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"allOf"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.5.3
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.26
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.7.1
  """

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(
          root :: Root.t(),
          schema :: ExJsonSchema.data(),
          property :: {String.t(), ExJsonSchema.data()},
          data :: ExJsonSchema.data()
        ) :: Validator.errors()
  def validate(root, _, {"allOf", all_of}, data) do
    do_validate(root, all_of, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(root, all_of, data) do
    invalid =
      all_of
      |> Enum.map(&Validator.validation_errors(root, &1, data))
      |> Enum.with_index()
      |> Enum.filter(fn {errors, _index} -> !Enum.empty?(errors) end)
      |> Validator.map_to_invalid_errors()

    case Enum.empty?(invalid) do
      true -> []
      false -> [%Error{error: %Error.AllOf{invalid: invalid}, path: ""}]
    end
  end
end
