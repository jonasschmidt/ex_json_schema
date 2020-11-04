defmodule ExJsonSchema.Validator.Ref do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"$ref"` attributes.

  See:

  """

  alias ExJsonSchema.Schema
  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
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
