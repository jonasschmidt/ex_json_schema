defmodule ExComponentSchema.Validator.MinProperties do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"minProperties"` attributes.

  See:

  """

  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(_, _, {"minProperties", min_properties}, data, _) do
    do_validate(min_properties, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(min_properties, data) when is_map(data) do
    if map_size(data) >= min_properties do
      []
    else
      [%Error{error: %Error.MinProperties{expected: min_properties, actual: map_size(data)}}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
