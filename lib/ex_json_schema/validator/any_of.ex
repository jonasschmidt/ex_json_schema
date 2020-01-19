defmodule ExJsonSchema.Validator.AnyOf do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"anyOf"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.5.4
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.27
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.7.2
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
  def validate(root, _, {"anyOf", any_of}, data) do
    do_validate(root, any_of, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(root, any_of, data) when is_list(any_of) do
    invalid =
      any_of
      |> Enum.reduce_while([], fn
        true, _acc ->
          {:halt, []}

        false, acc ->
          {:cont, [%Error{error: %{message: "false never matches"}, path: ""} | acc]}

        schema, acc ->
          case Validator.validation_errors(root, schema, data) do
            [] -> {:halt, []}
            errors -> {:cont, [errors | acc]}
          end
      end)
      |> Enum.reverse()
      |> Enum.with_index()
      |> Validator.map_to_invalid_errors()

    case Enum.empty?(invalid) do
      true -> []
      false -> [%Error{error: %Error.AnyOf{invalid: invalid}, path: ""}]
    end
  end

  defp do_validate(_, _, _) do
    []
  end
end
