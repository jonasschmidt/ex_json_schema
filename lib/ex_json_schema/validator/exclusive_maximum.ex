defmodule ExJsonSchema.Validator.ExclusiveMaximum do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"exclusiveMaximum"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.1.2
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.3
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.2.3
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
  def validate(%{version: 4}, schema, {"exclusiveMaximum", true}, data) do
    schema
    |> Map.get("maximum")
    |> do_validate(data)
  end

  def validate(_, _, {"exclusiveMaximum", maximum}, data) do
    do_validate(maximum, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(maximum, data) when is_number(data) do
    if data < maximum do
      []
    else
      [{"Expected the value to be < #{maximum}", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
