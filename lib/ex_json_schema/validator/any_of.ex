defmodule ExJsonSchema.Validator.AnyOf do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths
  def validate(root, _, {"anyOf", any_of}, data) do
    # IO.inspect any_of
    # IO.inspect data
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
