defmodule ExComponentSchema.Validator.Ref do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"$ref"` attributes.

  See:

  """

  alias ExComponentSchema.Schema
  alias ExComponentSchema.Validator

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(root, _, {"$ref", ref}, data, path) do
    do_validate(root, ref, data, path)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(root, ref, data, path) when is_bitstring(ref) or is_list(ref) do
    schema = Schema.get_fragment!(root, ref)
    Validator.validation_errors(root, schema, data, path)
  end

  defp do_validate(root, ref, data, path) when is_map(ref) do
    Validator.validation_errors(root, ref, data, path)
  end
end
