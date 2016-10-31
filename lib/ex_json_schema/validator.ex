defmodule ExJsonSchema.Validator do
  alias ExJsonSchema.Validator.Dependencies
  alias ExJsonSchema.Validator.Error
  alias ExJsonSchema.Validator.Format
  alias ExJsonSchema.Validator.Items
  alias ExJsonSchema.Validator.Properties
  alias ExJsonSchema.Validator.Type
  alias ExJsonSchema.Schema
  alias ExJsonSchema.Schema.Root

  @type errors :: [{String.t, String.t}] | []

  @spec validate(Root.t, ExJsonSchema.data) :: :ok | {:error, errors}
  def validate(root = %Root{}, data) do
    validate(root, root.schema, data)
  end

  @spec validate(ExJsonSchema.json, ExJsonSchema.data) :: :ok | {:error, errors}
  def validate(schema = %{}, data) do
    validate(Schema.resolve(schema), data)
  end

  @spec validate(Root.t, Schema.resolved, ExJsonSchema.data) :: errors
  def validate(root = %Root{}, schema = %{}, data) do
    case validation_errors(root, schema, data) do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  @spec validation_errors(Root.t, Schema.resolved, ExJsonSchema.data, [String.t | integer]) :: errors
  def validation_errors(root = %Root{}, schema = %{}, data, path \\ "#") do
    Enum.flat_map(schema, &validate_aspect(root, schema, &1, data))
    |> Enum.map(fn %Error{path: p} = error -> %{error | path: path <> p} end)
  end

  @spec valid?(Root.t, ExJsonSchema.data) :: boolean
  def valid?(root = %Root{}, data), do: valid?(root, root.schema, data)

  @spec valid?(ExJsonSchema.json, ExJsonSchema.data) :: boolean
  def valid?(schema = %{}, data), do: valid?(Schema.resolve(schema), data)

  @spec valid?(Root.t, Schema.resolved, ExJsonSchema.data) :: boolean
  def valid?(root = %Root{}, schema = %{}, data), do: validation_errors(root, schema, data) |> Enum.empty?

  defp validate_aspect(root, _, {"$ref", path}, data) do
    schema = Schema.get_ref_schema(root, path)
    validation_errors(root, schema, data, "")
  end

  defp validate_aspect(root, _, {"allOf", all_of}, data) do
    invalid_indices = validation_result_indices(root, all_of, data, &(!elem(&1, 0)))

    case Enum.empty?(invalid_indices) do
      true -> []
      false -> [%Error{error: %Error.AllOf{invalid_indices: invalid_indices}, path: ""}]
    end
  end

  defp validate_aspect(root, _, {"anyOf", any_of}, data) do
    case Enum.any?(any_of, &valid?(root, &1, data)) do
      true -> []
      false -> [%Error{error: %Error.AnyOf{}, path: ""}]
    end
  end

  defp validate_aspect(root, _, {"oneOf", one_of}, data) do
    valid_indices = validation_result_indices(root, one_of, data, &(elem(&1, 0)))

    case Enum.count(valid_indices) do
      1 -> []
      _ -> [%Error{error: %Error.OneOf{valid_indices: valid_indices}, path: ""}]
    end
  end

  defp validate_aspect(root, _, {"not", not_schema}, data) do
    case valid?(root, not_schema, data) do
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
    case Map.size(data) >= min_properties do
      true -> []
      false -> [%Error{error: %Error.MinProperties{expected: min_properties, actual: Map.size(data)}, path: ""}]
    end
  end

  defp validate_aspect(_, _, {"maxProperties", max_properties}, data) when is_map(data) do
    case Map.size(data) <= max_properties do
      true -> []
      false -> [%Error{error: %Error.MaxProperties{expected: max_properties, actual: Map.size(data)}, path: ""}]
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
    case Enum.any?(enum, &(&1 === data)) do
      true -> []
      false -> [%Error{error: %Error.Enum{}, path: ""}]
    end
  end

  defp validate_aspect(_, schema, {"minimum", minimum}, data) when is_number(data) do
    exclusive? = schema["exclusiveMinimum"] || false
    fun = if exclusive?, do: &Kernel.>/2, else: &Kernel.>=/2
    case fun.(data, minimum) do
      true -> []
      false -> [%Error{error: %Error.Minimum{expected: minimum, exclusive?: exclusive?}, path: ""}]
    end
  end

  defp validate_aspect(_, schema, {"maximum", maximum}, data) when is_number(data) do
    exclusive? = schema["exclusiveMaximum"] || false
    fun = if exclusive?, do: &Kernel.</2, else: &Kernel.<=/2
    case fun.(data, maximum) do
      true -> []
      false -> [%Error{error: %Error.Maximum{expected: maximum, exclusive?: exclusive?}, path: ""}]
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
    case pattern |> Regex.compile! |> Regex.match?(data) do
      true -> []
      false -> [%Error{error: %Error.Pattern{expected: pattern}, path: ""}]
    end
  end

  defp validate_aspect(_, _, {"format", format}, data) do
    Format.validate(format, data)
  end

  defp validate_aspect(_, _, _, _), do: []

  defp validation_result_indices(root, schemata, data, filter) do
    schemata
    |> Enum.map(&valid?(root, &1, data))
    |> Enum.with_index
    |> Enum.filter(filter)
    |> Dict.values
  end
end
