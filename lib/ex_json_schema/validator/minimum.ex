defmodule ExJsonSchema.Validator.Minimum do
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
  def validate(_, _, {"minimum", minimum}, data) do
    do_validate(minimum, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(minimum, data) when is_number(data) do
    if data >= minimum do
      []
    else
      [{"Expected the value to be >= #{minimum}", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
