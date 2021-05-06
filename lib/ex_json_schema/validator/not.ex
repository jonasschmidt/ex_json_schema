defmodule ExJsonSchema.Validator.Not do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"not"` attributes.

  See:

  """

  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, _, {"not", not_schema}, data, _) do
    do_validate(root, not_schema, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(root, not_schema, data) do
    case Validator.valid_fragment?(root, not_schema, data) do
      true -> [%Error{error: %Error.Not{}, fragment: not_schema}]
      false -> []
    end
  end
end
