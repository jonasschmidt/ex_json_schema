defmodule ExJsonSchema.Validator.Contains do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths

  def validate(root, _, {"contains", contains}, data) do
    do_validate(root, contains, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(_, true, [_ | _]) do
    []
  end

  defp do_validate(_, false, [_ | _]) do
    [{"Expected a nonempty array in data", []}]
  end

  defp do_validate(_, _, %{}) do
    []
  end

  defp do_validate(_, _, data) when not is_list(data) do
    [{"Expected #{inspect(data)} to be a list.", []}]
  end

  defp do_validate(root, contains, data) do
    if Enum.any?(data, &Validator.valid?(root, contains, &1)) do
      []
    else
      [{"Expected #{inspect(data)} to be in #{inspect(contains)}.", []}]
    end
  end
end
