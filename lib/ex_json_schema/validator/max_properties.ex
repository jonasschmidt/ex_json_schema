defmodule ExJsonSchema.Validator.MaxProperties do

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths

  def validate(_, _, {"maxProperties", max_properties}, data) do
    do_validate(max_properties, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(max_properties, data) when is_map(data) do
    if Map.size(data) <= max_properties do
      []
    else
      [{"Expected a maximum of #{max_properties} properties but got #{Map.size(data)}", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
