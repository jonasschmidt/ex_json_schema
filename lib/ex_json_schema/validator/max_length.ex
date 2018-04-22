defmodule ExJsonSchema.Validator.MaxLength do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths
  def validate(_, _, {"maxLength", max_length}, data) do
    do_validate(max_length, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(max_length, data) when is_bitstring(data) do
    length = String.length(data)
    if length <= max_length do
      []
    else
      [{"Expected value to have a maximum length of #{max_length} but was #{length}.", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
