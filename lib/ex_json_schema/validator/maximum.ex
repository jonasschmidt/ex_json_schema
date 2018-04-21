defmodule ExJsonSchema.Validator.Maximum do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths

  def validate(_, _, {"maximum", maximum}, data) do
    do_validate(maximum, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(maximum, data) when is_number(data) do
    if data <= maximum do
      []
    else
      [{"Expected the value to be <= #{maximum}", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
