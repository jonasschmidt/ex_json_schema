defmodule ExComponentSchema.Validator.Enum do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"enum"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.5.1
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.23
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.1.2
  """

  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(_, _, {"enum", enum}, data, _) do
    do_validate(enum, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(enum, data) when is_list(enum) do
    case Enum.any?(enum, &(&1 == data)) do
      true -> []
      false -> [%Error{error: %Error.Enum{enum: enum, actual: data}}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
