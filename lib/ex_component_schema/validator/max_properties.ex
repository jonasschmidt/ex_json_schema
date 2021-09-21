defmodule ExComponentSchema.Validator.MaxProperties do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"maxProperties"` attributes.

  See:

  """

  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(_, _, {"maxProperties", max_properties}, data, _) do
    do_validate(max_properties, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(max_properties, data) when is_map(data) do
    if map_size(data) <= max_properties do
      []
    else
      [%Error{error: %Error.MaxProperties{expected: max_properties, actual: map_size(data)}}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
