defmodule ExComponentSchema.Validator do
  alias ExComponentSchema.Schema
  alias ExComponentSchema.Schema.Root
  alias ExComponentSchema.Validator.Error

  @type errors :: [%Error{}] | list
  @type options :: [error_formatter: module() | false]

  @callback validate(
              Root.t(),
              ExComponentSchema.data(),
              {String.t(), ExComponentSchema.data()},
              ExComponentSchema.data(),
              ExComponentSchema.json_path()
            ) :: errors

  @spec validate(Root.t() | ExComponentSchema.object(), ExComponentSchema.data()) ::
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
          ExComponentSchema.json_path() | Schema.resolved(),
          ExComponentSchema.data(),
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
          ExComponentSchema.json_path() | Schema.resolved(),
          ExComponentSchema.data(),
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
    |> Enum.flat_map(fn {property_name, _} = property ->
      case validator_for(property_name) do
        nil -> []
        validator -> validator.validate(root, schema, property, data, path)
      end
    end)
    |> Enum.map(fn
      %Error{path: nil} = error -> %{error | path: path}
      error -> error
    end)
  end

  @spec valid?(Root.t() | ExComponentSchema.object(), ExComponentSchema.data()) ::
          boolean | no_return
  def valid?(root = %Root{}, data), do: valid_fragment?(root, root.schema, data)

  def valid?(schema = %{}, data), do: valid?(Schema.resolve(schema), data)

  @spec valid_fragment?(
          Root.t(),
          ExComponentSchema.json_path() | Schema.resolved(),
          ExComponentSchema.data()
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

  defp validator_for("allOf"), do: ExComponentSchema.Validator.AllOf
  defp validator_for("anyOf"), do: ExComponentSchema.Validator.AnyOf
  defp validator_for("const"), do: ExComponentSchema.Validator.Const
  defp validator_for("contains"), do: ExComponentSchema.Validator.Contains

  defp validator_for("contentEncoding"),
    do: ExComponentSchema.Validator.ContentEncodingContentMediaType

  defp validator_for("dependencies"), do: ExComponentSchema.Validator.Dependencies
  defp validator_for("enum"), do: ExComponentSchema.Validator.Enum
  defp validator_for("exclusiveMaximum"), do: ExComponentSchema.Validator.ExclusiveMaximum
  defp validator_for("exclusiveMinimum"), do: ExComponentSchema.Validator.ExclusiveMinimum
  defp validator_for("format"), do: ExComponentSchema.Validator.Format
  defp validator_for("if"), do: ExComponentSchema.Validator.IfThenElse
  defp validator_for("items"), do: ExComponentSchema.Validator.Items
  defp validator_for("maxItems"), do: ExComponentSchema.Validator.MaxItems
  defp validator_for("maxLength"), do: ExComponentSchema.Validator.MaxLength
  defp validator_for("maxProperties"), do: ExComponentSchema.Validator.MaxProperties
  defp validator_for("maximum"), do: ExComponentSchema.Validator.Maximum
  defp validator_for("minItems"), do: ExComponentSchema.Validator.MinItems
  defp validator_for("minLength"), do: ExComponentSchema.Validator.MinLength
  defp validator_for("minProperties"), do: ExComponentSchema.Validator.MinProperties
  defp validator_for("minimum"), do: ExComponentSchema.Validator.Minimum
  defp validator_for("multipleOf"), do: ExComponentSchema.Validator.MultipleOf
  defp validator_for("not"), do: ExComponentSchema.Validator.Not
  defp validator_for("oneOf"), do: ExComponentSchema.Validator.OneOf
  defp validator_for("pattern"), do: ExComponentSchema.Validator.Pattern
  defp validator_for("properties"), do: ExComponentSchema.Validator.Properties
  defp validator_for("propertyNames"), do: ExComponentSchema.Validator.PropertyNames
  defp validator_for("$ref"), do: ExComponentSchema.Validator.Ref
  defp validator_for("required"), do: ExComponentSchema.Validator.Required
  defp validator_for("type"), do: ExComponentSchema.Validator.Type
  defp validator_for("uniqueItems"), do: ExComponentSchema.Validator.UniqueItems

  defp validator_for(_) do
    nil
  end
end
