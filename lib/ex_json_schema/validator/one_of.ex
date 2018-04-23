defmodule ExJsonSchema.Validator.OneOf do
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
  def validate(root, _, {"oneOf", one_of}, data) do
    do_validate(root, one_of, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(root, one_of, data) do
    valid_indexes =
      one_of
      |> Enum.map(&Validator.valid?(root, &1, data))
      |> Enum.filter(& &1)
      |> Enum.with_index()
      |> Enum.map(fn {_k, v} -> v end)

    cond do
      Enum.empty?(valid_indexes) ->
        [{"Expected exactly one of the schemata to match, but none of them did.", []}]

      Enum.count(valid_indexes) == 1 ->
        []

      true ->
        [
          {"Expected exactly one of the schemata to match, " <>
             "but the schemata at the following indexes did: " <>
             "#{Enum.join(valid_indexes, ", ")}.", []}
        ]
    end
  end
end
