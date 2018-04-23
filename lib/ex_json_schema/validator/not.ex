defmodule ExJsonSchema.Validator.Not do
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
  def validate(root, _, {"not", not_schema}, data) do
    do_validate(root, not_schema, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(root, not_schema, data) do
    if Validator.valid?(root, not_schema, data) do
      [{"Expected schema not to match but it did.", []}]
    else
      []
    end
  end
end
