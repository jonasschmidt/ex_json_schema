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
              ExJsonSchema.data()
            ) :: errors

  @validators [
    ExJsonSchema.Validator.AllOf,
    ExJsonSchema.Validator.AnyOf,
    ExJsonSchema.Validator.Const,
    ExJsonSchema.Validator.Contains,
    ExJsonSchema.Validator.ContentEncoding,
    ExJsonSchema.Validator.ContentMediaType,
    ExJsonSchema.Validator.Dependencies,
    ExJsonSchema.Validator.Enum,
    ExJsonSchema.Validator.ExclusiveMaximum,
    ExJsonSchema.Validator.ExclusiveMinimum,
    ExJsonSchema.Validator.Format,
    ExJsonSchema.Validator.Items,
    ExJsonSchema.Validator.MaxItems,
    ExJsonSchema.Validator.MaxLength,
    ExJsonSchema.Validator.MaxProperties,
    ExJsonSchema.Validator.Maximum,
    ExJsonSchema.Validator.MinItems,
    ExJsonSchema.Validator.MinLength,
    ExJsonSchema.Validator.MinProperties,
    ExJsonSchema.Validator.Minimum,
    ExJsonSchema.Validator.MultipleOf,
    ExJsonSchema.Validator.Not,
    ExJsonSchema.Validator.OneOf,
    ExJsonSchema.Validator.Pattern,
    ExJsonSchema.Validator.Properties,
    ExJsonSchema.Validator.PropertyNames,
    ExJsonSchema.Validator.Ref,
    ExJsonSchema.Validator.Required,
    ExJsonSchema.Validator.Type,
    ExJsonSchema.Validator.UniqueItems
  ]

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

  def validation_errors(root = %Root{}, schema = %{}, data, path) do
    schema
    |> Enum.flat_map(fn property ->
      Enum.flat_map(@validators, fn validator ->
        validator.validate(root, schema, property, data)
      end)
    end)
    |> Enum.map(fn %Error{path: p} = error -> %{error | path: path <> p} end)
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
end
