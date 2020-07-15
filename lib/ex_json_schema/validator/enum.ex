defmodule ExJsonSchema.Validator.Enum do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"enum"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.5.1
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.23
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.1.2
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
  def validate(_, _, {"enum", enum}, data) do
    do_validate(enum, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(enum, data) when is_list(enum) do
    case Enum.any?(enum, &(&1 == data)) do
      true -> []
      false -> [%Error{error: %Error.Enum{}, path: ""}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
