defmodule ExJsonSchema.Validator.CustomKeyword do
  @moduledoc """
  `ExJsonSchema.Validator` for custom keywords.
  """

  alias ExJsonSchema.Schema.Root

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, schema, property, data, path) do
    do_validate(root, schema, property, data, path)
  end

  defp do_validate(%Root{custom_keyword_validator: nil}, schema, property, data, path) do
    case Application.fetch_env(:ex_json_schema, :custom_keyword_validator) do
      :error -> []
      {:ok, validator = {_mod, _fun}} -> validate_with_custom_validator(validator, schema, property, data, path)
    end
  end

  defp do_validate(%Root{custom_keyword_validator: validator = {_mod, _fun}}, schema, property, data, path) do
    validate_with_custom_validator(validator, schema, property, data, path)
  end

  defp do_validate(%Root{custom_keyword_validator: validator}, schema, property, data, path)
       when is_function(validator) do
    validate_with_custom_validator(validator, schema, property, data, path)
  end

  defp validate_with_custom_validator(validator, schema, property, data, path) do
    case validator do
      {mod, fun} -> apply(mod, fun, [schema, property, data, path])
      fun when is_function(fun, 4) -> fun.(schema, property, data, path)
    end
  end
end
