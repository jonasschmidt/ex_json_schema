defmodule ExJsonSchema.Validator.Ref do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"$ref"` attributes.

  See:

  """

  alias ExJsonSchema.Schema
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, _, {"$ref", ref}, data, path) do
    schema = Schema.get_fragment!(root, ref)
    Validator.validation_errors(root, schema, data, path)
  end

  def validate(_, _, _, _, _) do
    []
  end
end
