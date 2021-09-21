defmodule ExComponentSchema.Validator.Not do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"not"` attributes.

  See:

  """

  alias ExComponentSchema.Validator
  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(root, _, {"not", not_schema}, data, _) do
    do_validate(root, not_schema, data)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(root, not_schema, data) do
    case Validator.valid_fragment?(root, not_schema, data) do
      true -> [%Error{error: %Error.Not{}}]
      false -> []
    end
  end
end
