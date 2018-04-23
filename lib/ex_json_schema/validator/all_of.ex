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

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(
          Root.t(),
          ExJsonSchema.data(),
          {String.t(), ExJsonSchema.data()},
          ExJsonSchema.data()
        ) :: Validator.errors_with_list_paths()
  def validate(root, _, {"allOf", all_of}, data) do
    do_validate(root, all_of, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(root, all_of, data) do
    invalid_indexes =
      all_of
      |> Enum.map(&Validator.valid?(root, &1, data))
      |> Enum.reject(& &1)
      |> Enum.with_index()
      |> Enum.map(fn {_k, v} -> v end)

    if Enum.empty?(invalid_indexes) do
      []
    else
      [
        {"Expected all of the schemata to match, " <>
           "but the schemata at the following indexes did not: " <>
           "#{Enum.join(invalid_indexes, ", ")}.", []}
      ]
    end
  end
end
