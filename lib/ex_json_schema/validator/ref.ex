defmodule ExJsonSchema.Validator.Ref do
  alias ExJsonSchema.Schema
  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  @spec validate(
          Root.t(),
          ExJsonSchema.data(),
          {String.t(), ExJsonSchema.data()},
          ExJsonSchema.data()
        ) :: Validator.errors_with_list_paths()
  def validate(root, _, {"$ref", ref}, data) do
    do_validate(root, ref, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate(_, true, _) do
    []
  end

  defp do_validate(_, false, _) do
    [{"$ref to false is always invalid.", []}]
  end

  defp do_validate(root, path, data) when is_bitstring(path) or is_list(path) do
    schema = Schema.get_ref_schema(root, path)
    Validator.validate(root, schema, data)
  end

  defp do_validate(root, ref, data) when is_map(ref) do
    Validator.validate(root, ref, data)
  end

  defp do_validate(_, _, _) do
    [{"$ref is invalid.", []}]
  end
end
