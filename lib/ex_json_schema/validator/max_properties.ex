defmodule ExJsonSchema.Validator.MaxProperties do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"maxProperties"` attributes.

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
  def validate(_, _, {"maxProperties", max_properties}, data) do
    do_validate(max_properties, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(max_properties, data) when is_map(data) do
    if map_size(data) <= max_properties do
      []
    else
      [
        %Error{
          error: %Error.MaxProperties{expected: max_properties, actual: map_size(data)},
          path: ""
        }
      ]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
