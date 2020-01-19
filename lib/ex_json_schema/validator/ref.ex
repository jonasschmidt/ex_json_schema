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
  @spec validate(
          root :: Root.t(),
          schema :: ExJsonSchema.data(),
          property :: {String.t(), ExJsonSchema.data()},
          data :: ExJsonSchema.data()
        ) :: Validator.errors()
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
    [%Error{error: %{message: "$ref to false is always invalid."}, path: ""}]
  end

  defp do_validate(root, path, data) when is_bitstring(path) or is_list(path) do
    case Schema.get_fragment!(root, path) do
      true -> []
      false -> [%Error{error: %{message: "false never matches"}, path: ""}]
      schema -> Validator.validation_errors(root, schema, data, "")
    end
  end

  defp do_validate(root, ref, data) when is_map(ref) do
    Validator.validation_errors(root, ref, data, "")
  end

  defp do_validate(_, _, _) do
    [%Error{error: %{message: "$ref is invalid."}, path: ""}]
  end
end
