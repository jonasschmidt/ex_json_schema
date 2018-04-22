defmodule ExJsonSchema.Validator.MinLength do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths
  def validate(_, _, {"minLength", min_length}, data) do
    do_validate(min_length, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(min_length, data) when is_bitstring(data) do
    length = String.length(data)
    if length >= min_length do
      []
    else
      [{"Expected value to have a minimum length of #{min_length} but was #{length}.", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end