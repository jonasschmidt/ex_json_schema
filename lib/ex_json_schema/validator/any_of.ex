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

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths
  def validate(root, _, {"anyOf", any_of}, data) do
    do_validate(root, any_of, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(root, any_of, data) when is_list(any_of) do
    if Enum.any?(any_of, &Validator.valid?(root, &1, data)) do
      []
    else
      [{"Expected any of the schemata to match but none did.", []}]
    end
  end

  defp do_validate(_, _, _) do
    []
  end
end
