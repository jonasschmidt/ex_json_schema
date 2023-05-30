defmodule ExJsonSchema.Validator.Ref do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"$ref"` attributes.

  See:

  """

  alias ExJsonSchema.Schema
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Result

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, _, {"$ref", ref}, data, path) do
    schema = Schema.get_fragment!(root, ref)
    Validator.validation_result(root, schema, data, path)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end
end
