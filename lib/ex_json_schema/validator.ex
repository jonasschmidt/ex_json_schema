defmodule ExJsonSchema.Validator do
  alias ExJsonSchema.Validator.Dependencies
  alias ExJsonSchema.Validator.Error
  alias ExJsonSchema.Validator.Format
  alias ExJsonSchema.Validator.Items
  alias ExJsonSchema.Validator.Properties
  alias ExJsonSchema.Validator.Type
  alias ExJsonSchema.Schema
  alias ExJsonSchema.Schema.Root

  @type errors :: [%Error{}] | list
  @type options :: [error_formatter: module() | false]

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
    Enum.flat_map(schema, &validate_aspect(root, schema, &1, data))
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

  defp format_errors(:ok, _error_formatter), do: :ok

  defp format_errors({:error, errors}, error_formatter) when is_list(errors) do
    {:error, error_formatter.format(errors)}
  end

  defp format_errors({:error, _} = error, _error_formatter), do: error

  defp validate_aspect(root, _, {"$ref", path}, data) do
    schema = Schema.get_fragment!(root, path)
    validation_errors(root, schema, data, "")
  end

  defp validate_aspect(root, _, {"allOf", all_of}, data) do
    invalid =
      all_of
      |> Enum.map(&validation_errors(root, &1, data))
      |> Enum.with_index()
      |> Enum.filter(fn {errors, _index} -> !Enum.empty?(errors) end)
      |> map_to_invalid_errors

    case Enum.empty?(invalid) do
      true -> []
      false -> [%Error{error: %Error.AllOf{invalid: invalid}, path: ""}]
    end
  end

  defp validate_aspect(root, _, {"anyOf", any_of}, data) do
    invalid =
      any_of
      |> Enum.reduce_while([], fn schema, acc ->
        case validation_errors(root, schema, data) do
          [] -> {:halt, []}
          errors -> {:cont, [errors | acc]}
        end
      end)
      |> Enum.reverse()
      |> Enum.with_index()
      |> map_to_invalid_errors

    case Enum.empty?(invalid) do
      true -> []
      false -> [%Error{error: %Error.AnyOf{invalid: invalid}, path: ""}]
    end
  end

  defp validate_aspect(root, _, {"oneOf", one_of}, data) do
    {valid_count, valid_indices, errors} =
      one_of
      |> Enum.with_index()
      |> Enum.reduce({0, [], []}, fn {schema, index}, {valid_count, valid_indices, errors} ->
        case validation_errors(root, schema, data) do
          [] -> {valid_count + 1, [index | valid_indices], errors}
          e -> {valid_count, valid_indices, [{e, index} | errors]}
        end
      end)

    case valid_count do
      1 ->
        []

      0 ->
        [
          %Error{
            error: %Error.OneOf{
              valid_indices: [],
              invalid: errors |> Enum.reverse() |> map_to_invalid_errors
            },
            path: ""
          }
        ]

      _ ->
        [
          %Error{
            error: %Error.OneOf{valid_indices: Enum.reverse(valid_indices), invalid: []},
            path: ""
          }
        ]
    end
  end

  defp validate_aspect(root, _, {"not", not_schema}, data) do
    case valid_fragment?(root, not_schema, data) do
      true -> [%Error{error: %Error.Not{}, path: ""}]
      false -> []
    end
  end

  defp validate_aspect(_, _, {"type", type}, data) do
    Type.validate(type, data)
  end

  defp validate_aspect(root, schema, {"properties", _}, data = %{}) do
    Properties.validate(root, schema, data)
  end

  defp validate_aspect(_, _, {"minProperties", min_properties}, data) when is_map(data) do
    case map_size(data) >= min_properties do
      true ->
        []

      false ->
        [
          %Error{
            error: %Error.MinProperties{expected: min_properties, actual: map_size(data)},
            path: ""
          }
        ]
    end
  end

  defp validate_aspect(_, _, {"maxProperties", max_properties}, data) when is_map(data) do
    case map_size(data) <= max_properties do
      true ->
        []

      false ->
        [
          %Error{
            error: %Error.MaxProperties{expected: max_properties, actual: map_size(data)},
            path: ""
          }
        ]
    end
  end

  defp validate_aspect(_, _, {"required", required}, data = %{}) do
    case Enum.filter(required, &(!Map.has_key?(data, &1))) do
      [] -> []
      missing -> [%Error{error: %Error.Required{missing: missing}, path: ""}]
    end
  end

  defp validate_aspect(root, _, {"dependencies", dependencies}, data) do
    Dependencies.validate(root, dependencies, data)
  end

  defp validate_aspect(root, schema, {"items", _}, items) do
    Items.validate(root, schema, items)
  end

  defp validate_aspect(_, _, {"minItems", min_items}, items) when is_list(items) do
    case (count = Enum.count(items)) >= min_items do
      true -> []
      false -> [%Error{error: %Error.MinItems{expected: min_items, actual: count}, path: ""}]
    end
  end

  defp validate_aspect(_, _, {"maxItems", max_items}, items) when is_list(items) do
    case (count = Enum.count(items)) <= max_items do
      true -> []
      false -> [%Error{error: %Error.MaxItems{expected: max_items, actual: count}, path: ""}]
    end
  end

  defp validate_aspect(_, _, {"uniqueItems", true}, items) when is_list(items) do
    case Enum.uniq(items) == items do
      true -> []
      false -> [%Error{error: %Error.UniqueItems{}, path: ""}]
    end
  end

  defp validate_aspect(_, _, {"enum", enum}, data) do
    case Enum.any?(enum, &(&1 == data)) do
      true -> []
      false -> [%Error{error: %Error.Enum{}, path: ""}]
    end
  end

  defp validate_aspect(_, schema, {"minimum", minimum}, data) when is_number(data) do
    exclusive? = schema["exclusiveMinimum"] || false
    fun = if exclusive?, do: &Kernel.>/2, else: &Kernel.>=/2

    case fun.(data, minimum) do
      true ->
        []

      false ->
        [%Error{error: %Error.Minimum{expected: minimum, exclusive?: exclusive?}, path: ""}]
    end
  end

  defp validate_aspect(_, schema, {"maximum", maximum}, data) when is_number(data) do
    exclusive? = schema["exclusiveMaximum"] || false
    fun = if exclusive?, do: &Kernel.</2, else: &Kernel.<=/2

    case fun.(data, maximum) do
      true ->
        []

      false ->
        [%Error{error: %Error.Maximum{expected: maximum, exclusive?: exclusive?}, path: ""}]
    end
  end

  defp validate_aspect(_, _, {"multipleOf", multiple_of}, data) when is_number(data) do
    factor = data / multiple_of

    case Float.floor(factor) == factor do
      true -> []
      false -> [%Error{error: %Error.MultipleOf{expected: multiple_of}, path: ""}]
    end
  end

  defp validate_aspect(_, _, {"minLength", min_length}, data) when is_binary(data) do
    case (length = String.length(data)) >= min_length do
      true -> []
      false -> [%Error{error: %Error.MinLength{expected: min_length, actual: length}, path: ""}]
    end
  end

  defp validate_aspect(_, _, {"maxLength", max_length}, data) when is_binary(data) do
    case (length = String.length(data)) <= max_length do
      true -> []
      false -> [%Error{error: %Error.MaxLength{expected: max_length, actual: length}, path: ""}]
    end
  end

  defp validate_aspect(_, _, {"pattern", pattern}, data) when is_binary(data) do
    case pattern |> Regex.compile!() |> Regex.match?(data) do
      true -> []
      false -> [%Error{error: %Error.Pattern{expected: pattern}, path: ""}]
    end
  end

  defp validate_aspect(root, _, {"format", format}, data) do
    Format.validate(root, format, data)
  end

  defp validate_aspect(_, _, _, _), do: []

  defp map_to_invalid_errors(errors_with_index) do
    errors_with_index
    |> Enum.map(fn {errors, index} ->
      %Error.InvalidAtIndex{errors: errors, index: index}
    end)
  end
end
