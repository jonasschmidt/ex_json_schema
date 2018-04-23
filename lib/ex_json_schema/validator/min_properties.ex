defmodule ExJsonSchema.Validator.MinProperties do
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
  def validate(_, _, {"minProperties", min_properties}, data) do
    do_validate(min_properties, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(min_properties, data) when is_map(data) do
    if Map.size(data) >= min_properties do
      []
    else
      [{"Expected a minimum of #{min_properties} properties but got #{Map.size(data)}", []}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
