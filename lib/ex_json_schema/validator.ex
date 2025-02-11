defmodule ExJsonSchema.Validator do
  alias ExJsonSchema.Validator.Error
  alias ExJsonSchema.Schema
  alias ExJsonSchema.Schema.Root

  @type errors :: [%Error{}] | list
  @type options :: [error_formatter: module() | false]

  @callback validate(
              Root.t(),
              ExJsonSchema.data(),
              {String.t(), ExJsonSchema.data()},
              ExJsonSchema.data(),
              ExJsonSchema.json_path()
            ) :: errors

  @spec validate(Root.t() | ExJsonSchema.object(), ExJsonSchema.data()) ::
          :ok | {:error, errors} | no_return
  def validate(root, data, options \\ [])

  def validate(root = %Root{}, data, options) when is_list(options) do
    validate_fragment(root, root.schema, data, options)
  end

  def validate(schema = %{}, data, options) when is_list(options) do
    validate(Schema.resolve(schema), data, options)
  end

  @spec validate_fragment(
          Root.t(),
          ExJsonSchema.json_path() | Schema.resolved(),
          ExJsonSchema.data(),
          options
        ) :: :ok | {:error, errors} | Schema.invalid_reference_error() | no_return
  def validate_fragment(root, schema_or_ref, data, options \\ []) when is_list(options) do
    result =
      case validation_errors(root, schema_or_ref, data) do
        {:error, _error} = error -> error
        [] -> :ok
        errors -> {:error, errors}
      end

    case Keyword.get(options, :error_formatter, Error.StringFormatter) do
      false -> result
      formatter -> format_errors(result, formatter)
    end
  end

  @spec validation_errors(
          Root.t(),
          ExJsonSchema.json_path() | Schema.resolved(),
          ExJsonSchema.data(),
          String.t()
        ) :: errors | Schema.invalid_reference_error() | no_return
  def validation_errors(root, schema_or_ref, data, path \\ "#")

  def validation_errors(root, ref, data, path) when is_binary(ref) do
    case Schema.get_fragment(root, ref) do
      {:ok, schema} -> validation_errors(root, schema, data, path)
      error -> error
    end
  end

  def validation_errors(root = %Root{}, %{"$ref" => ref}, data, path) do
    do_validation_errors(root, %{"$ref" => ref}, data, path)
  end

  def validation_errors(%Root{}, true, _data, _path) do
    []
  end

  def validation_errors(%Root{}, false, _data, path) do
    [%Error{error: %Error.False{}, path: path}]
  end

  def validation_errors(root = %Root{}, schema = %{}, data, path) do
    do_validation_errors(root, schema, data, path)
  end

  def do_validation_errors(root = %Root{}, schema = %{}, data, path) do
    schema
    |> Enum.flat_map(fn {propertyName, _} = property ->
      case validator_for(propertyName) do
        {:ok, validator} -> validator.validate(root, schema, property, data, path)
        :error -> []
      end
    end)
    |> Enum.map(fn
      %Error{path: nil} = error -> %{error | path: path}
      error -> error
    end)
  end

  @spec valid?(Root.t() | ExJsonSchema.object(), ExJsonSchema.data()) :: boolean | no_return
  def valid?(root = %Root{}, data), do: valid_fragment?(root, root.schema, data)

  def valid?(schema = %{}, data), do: valid?(Schema.resolve(schema), data)

  @spec valid_fragment?(
          Root.t(),
          ExJsonSchema.json_path() | Schema.resolved(),
          ExJsonSchema.data()
        ) :: boolean | Schema.invalid_reference_error() | no_return
  def valid_fragment?(root, schema_or_ref, data) do
    case validation_errors(root, schema_or_ref, data) do
      {:error, _error} = error -> error
      [] -> true
      _errors -> false
    end
  end

  def map_to_invalid_errors(errors_with_index) do
    errors_with_index
    |> Enum.map(fn {errors, index} ->
      %Error.InvalidAtIndex{errors: errors, index: index}
    end)
  end

  defp format_errors(:ok, _error_formatter), do: :ok

  defp format_errors({:error, errors}, error_formatter) when is_list(errors) do
    {:error, error_formatter.format(errors)}
  end

  defp format_errors({:error, _} = error, _error_formatter), do: error

  defp validator_for("allOf"), do: {:ok, ExJsonSchema.Validator.AllOf}
  defp validator_for("anyOf"), do: {:ok, ExJsonSchema.Validator.AnyOf}
  defp validator_for("const"), do: {:ok, ExJsonSchema.Validator.Const}
  defp validator_for("contains"), do: {:ok, ExJsonSchema.Validator.Contains}
  defp validator_for("contentEncoding"), do: {:ok, ExJsonSchema.Validator.ContentEncodingContentMediaType}
  defp validator_for("dependencies"), do: {:ok, ExJsonSchema.Validator.Dependencies}
  defp validator_for("enum"), do: {:ok, ExJsonSchema.Validator.Enum}
  defp validator_for("exclusiveMaximum"), do: {:ok, ExJsonSchema.Validator.ExclusiveMaximum}
  defp validator_for("exclusiveMinimum"), do: {:ok, ExJsonSchema.Validator.ExclusiveMinimum}
  defp validator_for("format"), do: {:ok, ExJsonSchema.Validator.Format}
  defp validator_for("if"), do: {:ok, ExJsonSchema.Validator.IfThenElse}
  defp validator_for("items"), do: {:ok, ExJsonSchema.Validator.Items}
  defp validator_for("maxItems"), do: {:ok, ExJsonSchema.Validator.MaxItems}
  defp validator_for("maxLength"), do: {:ok, ExJsonSchema.Validator.MaxLength}
  defp validator_for("maxProperties"), do: {:ok, ExJsonSchema.Validator.MaxProperties}
  defp validator_for("maximum"), do: {:ok, ExJsonSchema.Validator.Maximum}
  defp validator_for("minItems"), do: {:ok, ExJsonSchema.Validator.MinItems}
  defp validator_for("minLength"), do: {:ok, ExJsonSchema.Validator.MinLength}
  defp validator_for("minProperties"), do: {:ok, ExJsonSchema.Validator.MinProperties}
  defp validator_for("minimum"), do: {:ok, ExJsonSchema.Validator.Minimum}
  defp validator_for("multipleOf"), do: {:ok, ExJsonSchema.Validator.MultipleOf}
  defp validator_for("not"), do: {:ok, ExJsonSchema.Validator.Not}
  defp validator_for("oneOf"), do: {:ok, ExJsonSchema.Validator.OneOf}
  defp validator_for("pattern"), do: {:ok, ExJsonSchema.Validator.Pattern}
  defp validator_for("properties"), do: {:ok, ExJsonSchema.Validator.Properties}
  defp validator_for("propertyNames"), do: {:ok, ExJsonSchema.Validator.PropertyNames}
  defp validator_for("$ref"), do: {:ok, ExJsonSchema.Validator.Ref}
  defp validator_for("required"), do: {:ok, ExJsonSchema.Validator.Required}
  defp validator_for("type"), do: {:ok, ExJsonSchema.Validator.Type}
  defp validator_for("uniqueItems"), do: {:ok, ExJsonSchema.Validator.UniqueItems}
  defp validator_for(_), do: :error
end
