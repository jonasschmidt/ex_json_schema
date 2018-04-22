defmodule ExJsonSchema.Validator.ExclusiveMaximum do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths
  def validate(%{version: 4}, schema, {"exclusiveMaximum", true}, data) do
    schema
    |> Map.get("maximum")
    |> do_validate(data)
  end

  def validate(_, _, {"exclusiveMaximum", maximum}, data) do
    do_validate(maximum, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(maximum, data) when is_number(data) do
    if data < maximum do
      []
    else
      [{"Expected the value to be < #{maximum}", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
