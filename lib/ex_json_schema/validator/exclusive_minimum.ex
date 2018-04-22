defmodule ExJsonSchema.Validator.ExclusiveMinimum do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"exclusiveMinimum"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.1.3
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.5
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.2.5
  """

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths
  def validate(%{version: 4}, schema, {"exclusiveMinimum", true}, data) do
    schema
    |> Map.get("minimum")
    |> do_validate(data)
  end

  def validate(root, schema, {"exclusiveMinimum", minimum}, data) do
    do_validate(minimum, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(true, data)  do
    do_validate(1, data)
  end

  defp do_validate(minimum, data) when is_number(data) do
    if data > minimum do
      []
    else
      [{"Expected the value to be > #{minimum}", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
