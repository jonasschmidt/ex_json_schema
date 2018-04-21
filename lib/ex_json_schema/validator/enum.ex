defmodule ExJsonSchema.Validator.Enum do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths

  def validate(_, _, {"enum", enum}, data) do
    do_validate(enum, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(enum, data) when is_list(enum) do
    if data in enum do
      []
    else
      [{"Value #{inspect(data)} is not allowed in enum.", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
