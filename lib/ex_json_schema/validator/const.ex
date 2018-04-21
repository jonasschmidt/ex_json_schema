defmodule ExJsonSchema.Validator.Const do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths

  def validate(_, _, {"const", const}, data) do
    do_validate(const, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(const, data) do
    if const == data do
      []
    else
      [{"Expected data to be #{inspect(const)} but it wasn't", []}]
    end
  end
end
