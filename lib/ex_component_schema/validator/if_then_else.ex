defmodule ExComponentSchema.Validator.IfThenElse do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"if"`/`"then"`/`"else"` attributes.

  See:

  """

  alias ExComponentSchema.Schema.Root
  alias ExComponentSchema.Validator
  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(%Root{version: version} = root, schema, {"if", if_schema}, data, _)
      when version >= 7 do
    validate_with_if(root, schema, if_schema, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp validate_with_if(root, %{"then" => then_schema, "else" => else_schema}, if_schema, data) do
    validate_with_if_then_else(root, if_schema, then_schema, else_schema, data)
  end

  defp validate_with_if(root, %{"then" => then_schema}, if_schema, data) do
    validate_with_if_then_else(root, if_schema, then_schema, nil, data)
  end

  defp validate_with_if(root, %{"else" => else_schema}, if_schema, data) do
    validate_with_if_then_else(root, if_schema, nil, else_schema, data)
  end

  defp validate_with_if(_, _, _, _) do
    []
  end

  defp validate_with_if_then_else(root, if_schema, then_schema, else_schema, data) do
    case Validator.valid_fragment?(root, if_schema, data) do
      true ->
        case then_schema do
          nil -> []
          then_schema -> validation_errors(root, then_schema, data, :then)
        end

      false ->
        case else_schema do
          nil -> []
          else_schema -> validation_errors(root, else_schema, data, :else)
        end
    end
  end

  defp validation_errors(root, schema, data, branch) do
    case Validator.validation_errors(root, schema, data) do
      [] -> []
      errors -> [%Error{error: %Error.IfThenElse{branch: branch, errors: errors}}]
    end
  end
end
