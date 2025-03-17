defmodule ExJsonSchema.Validator.MaxProperties do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"maxProperties"` attributes.

  See:

  """

  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(_, _, {"maxProperties", max_properties}, data, _) do
    do_validate(max_properties, data)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(max_properties, data) when is_map(data) do
    if map_size(data) <= max_properties do
      Result.new()
    else
      Result.with_errors([%Error{error: %Error.MaxProperties{expected: max_properties, actual: map_size(data)}}])
    end
  end

  defp do_validate(_, _) do
    Result.new()
  end
end
