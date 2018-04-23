defmodule ExJsonSchema.Validator.Const do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"anyOf"` attributes.

  See:
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.24
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.1.3
  """

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(
          root :: Root.t(),
          schema :: ExJsonSchema.data(),
          property :: {String.t(), ExJsonSchema.data()},
          data :: ExJsonSchema.data()
        ) :: Validator.errors_with_list_paths()
  def validate(_, _, {"const", const}, data) do
    do_validate(const, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(const, data) do
    if const == data do
      []
    else
      [{"Expected data to be #{inspect(const)} but it wasn't", []}]
    end
  end
end
