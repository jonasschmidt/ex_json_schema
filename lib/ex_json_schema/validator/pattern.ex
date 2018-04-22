defmodule ExJsonSchema.Validator.Pattern do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths
  def validate(_, _, {"pattern", pattern}, data) do
    do_validate(pattern, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(pattern, data) when is_bitstring(data) do
    matches? =
      pattern
      |> Regex.compile!()
      |> Regex.match?(data)

    if matches? do
      []
    else
      [{"String #{inspect(data)} does not match pattern #{inspect(pattern)}.", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
