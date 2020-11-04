defmodule ExJsonSchema.Validator.Required do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"required"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.4.3
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.17
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.5.3
  """

  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(_, _, {"required", required}, data, _) do
    do_validate(required, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(required, data = %{}) do
    case Enum.filter(List.wrap(required), &(!Map.has_key?(data, &1))) do
      [] -> []
      missing -> [%Error{error: %Error.Required{missing: missing}}]
    end
  end

  defp do_validate(_, _) do
    []
  end
end
