defmodule ExJsonSchema.Validator.Contains do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"contains"` attributes.

  See:
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.14
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.4.6
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
  def validate(root = %{version: version}, _, {"contains", contains}, data) when version >= 6 do
    do_validate(root, contains, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(root, contains, data) when is_list(data) do
    if Enum.any?(data, &Validator.valid_fragment?(root, contains, &1)) do
      []
    else
      [
        %Error{
          error: %{message: "Expected #{inspect(data)} to be in #{inspect(contains)}."},
          path: ""
        }
      ]
    end
  end

  defp do_validate(_, _, _) do
    []
  end
end
