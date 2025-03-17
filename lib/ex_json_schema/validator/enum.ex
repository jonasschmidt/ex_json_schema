defmodule ExJsonSchema.Validator.Enum do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"enum"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.5.1
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.23
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.1.2
  """

  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(_, _, {"enum", enum}, data, _) do
    do_validate(enum, data)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(enum, data) when is_list(enum) do
    case Enum.any?(enum, &(&1 == data)) do
      true -> Result.new()
      false -> Result.with_errors([%Error{error: %Error.Enum{}}])
    end
  end

  defp do_validate(_, _) do
    Result.new()
  end
end
