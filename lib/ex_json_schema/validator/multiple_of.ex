defmodule ExJsonSchema.Validator.MultipleOf do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths
  def validate(_, _, {"multipleOf", multiple_of}, data) do
    do_validate(multiple_of, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(_, 0) do
    []
  end

  defp do_validate(0, _) do
    [{"Expected multipleOf to be > 1.", []}]
  end

  defp do_validate(_, data) when not is_number(data) do
    []
  end

  defp do_validate(multiple_of, data) when is_number(multiple_of) and is_number(data) do
    case Float.ratio(data / multiple_of) do
      {_, 1} ->
        []
      _ ->
        [{"Expected value to be a multiple of #{multiple_of} but got #{data}.", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
