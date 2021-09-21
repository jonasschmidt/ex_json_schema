defmodule ExComponentSchema.Validator.AnyOf do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"anyOf"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.5.4
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.27
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.7.2
  """

  alias ExComponentSchema.Validator
  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(root, _, {"anyOf", any_of}, data, path) do
    do_validate(root, any_of, data, path)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(root, any_of, data, path) when is_list(any_of) do
    invalid =
      any_of
      |> Enum.with_index()
      |> Enum.reduce_while([], fn
        {schema, index}, acc ->
          case Validator.validation_errors(root, schema, data, path) do
            [] -> {:halt, []}
            errors -> {:cont, [{errors, index} | acc]}
          end
      end)
      |> Enum.reverse()
      |> Validator.map_to_invalid_errors()

    case Enum.empty?(invalid) do
      true -> []
      false -> [%Error{error: %Error.AnyOf{invalid: invalid}}]
    end
  end

  defp do_validate(_, _, _, _) do
    []
  end
end
