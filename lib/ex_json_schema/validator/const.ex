defmodule ExJsonSchema.Validator.Const do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"anyOf"` attributes.

  See:
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.24
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.1.3
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
  def validate(%{version: version}, _, {"const", const}, data) when version >= 6 do
    do_validate(const, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(const, data) do
    if const == data do
      []
    else
      [
        %Error{
          error: %{message: "Expected data to be #{inspect(const)} but got #{inspect(data)}"},
          path: ""
        }
      ]
    end
  end
end
