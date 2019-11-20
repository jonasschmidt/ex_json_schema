defmodule ExJsonSchema.Validator.MinProperties do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"minProperties"` attributes.

  See:

  """

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(
          root :: Root.t(),
          schema :: ExJsonSchema.data(),
          property :: {String.t(), ExJsonSchema.data()},
          data :: ExJsonSchema.data()
        ) :: Validator.errors()
  def validate(_, _, {"minProperties", min_properties}, data) do
    do_validate(min_properties, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(min_properties, data) when is_map(data) do
    if map_size(data) >= min_properties do
      []
    else
      [
        %Error{
          error: %Error.MinProperties{expected: min_properties, actual: map_size(data)},
          path: ""
        }
      ]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
