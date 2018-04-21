defmodule ExJsonSchema.Validator.MinProperties do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"minProperties"` attributes.

  See:

  """

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
