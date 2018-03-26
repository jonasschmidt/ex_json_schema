defmodule ExJsonSchema.Validator do
  alias ExJsonSchema.Validator.Dependencies
  alias ExJsonSchema.Validator.Format
  alias ExJsonSchema.Validator.Items
  alias ExJsonSchema.Validator.Properties
  alias ExJsonSchema.Validator.Type
  alias ExJsonSchema.Schema
  alias ExJsonSchema.Schema.Root

  @type errors :: [{String.t, String.t}] | []
  @type errors_with_list_paths :: [{String.t, [String.t | integer]}] | []

  @spec validate(Root.t | ExJsonSchema.object, ExJsonSchema.data) :: :ok | {:error, errors}
  def validate(root = %Root{}, data) do
    errors = validate(root, root.schema, data, ["#"]) |> errors_with_string_paths
    case Enum.empty?(errors) do
      true -> :ok
      false -> {:error, errors}
    end
  end

  def validate(schema = %{}, data) do
    validate(Schema.resolve(schema), data)
  end

  @spec validate(Root.t, Schema.resolved, ExJsonSchema.data, [String.t | integer]) :: errors_with_list_paths
  def validate(root, schema, data, path \\ []) do
    Enum.flat_map(schema, &validate_aspect(root, schema, &1, data))
    |> Enum.map(fn {msg, p} -> {msg, path ++ p} end)
  end

  @spec valid?(Root.t | ExJsonSchema.object, ExJsonSchema.data) :: boolean
  def valid?(root = %Root{}, data), do: valid?(root, root.schema, data)

  def valid?(schema = %{}, data), do: valid?(Schema.resolve(schema), data)

  @spec valid?(Root.t, Schema.resolved, ExJsonSchema.data) :: boolean
  def valid?(root, schema, data), do: validate(root, schema, data) |> Enum.empty?

  defp errors_with_string_paths(errors) do
    Enum.map errors, fn {msg, path} -> {msg, Enum.join(path, "/")} end
  end

  defp validate_aspect(root, _, {"$ref", path}, data) do
    schema = Schema.get_ref_schema(root, path)
    validate(root, schema, data)
  end

  defp validate_aspect(root, _, {"allOf", all_of}, data) do
    invalid_indexes = validation_result_indexes(root, all_of, data, &(!elem(&1, 0)))

    case Enum.empty?(invalid_indexes) do
      true -> []
      false ->
        [{"Expected all of the schemata to match, " <>
          "but the schemata at the following indexes did not: " <>
          "#{Enum.join(invalid_indexes, ", ")}.", []}]
    end
  end

  defp validate_aspect(root, _, {"anyOf", any_of}, data) do
    case Enum.any?(any_of, &valid?(root, &1, data)) do
      true -> []
      false -> [{"Expected any of the schemata to match but none did.", []}]
    end
  end

  defp validate_aspect(root, _, {"oneOf", one_of}, data) do
    valid_indexes = validation_result_indexes(root, one_of, data, &(elem(&1, 0)))

    case Enum.empty?(valid_indexes) do
      true -> [{"Expected exactly one of the schemata to match, but none of them did.", []}]
      false -> if Enum.count(valid_indexes) == 1 do
          []
        else
          [{"Expected exactly one of the schemata to match, " <>
            "but the schemata at the following indexes did: " <>
            "#{Enum.join(valid_indexes, ", ")}.", []}]
        end
    end
  end

  defp validate_aspect(root, _, {"not", not_schema}, data) do
    case valid?(root, not_schema, data) do
      true -> [{"Expected schema not to match but it did.", []}]
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
      false -> [{"Expected a minimum of #{min_properties} properties but got #{Map.size(data)}", []}]
    end
  end

  defp validate_aspect(_, _, {"maxProperties", max_properties}, data) when is_map(data) do
    case Map.size(data) <= max_properties do
      true -> []
      false -> [{"Expected a maximum of #{max_properties} properties but got #{Map.size(data)}", []}]
    end
  end

  defp validate_aspect(_, _, {"required", required}, data = %{}) do
    Enum.flat_map List.wrap(required), fn property ->
      case Map.has_key?(data, property) do
        true -> []
        false -> [{"Required property #{property} was not present.", []}]
      end
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
      false -> [{"Expected a minimum of #{min_items} items but got #{count}.", []}]
    end
  end

  defp validate_aspect(_, _, {"maxItems", max_items}, items) when is_list(items) do
    case (count = Enum.count(items)) <= max_items do
      true -> []
      false -> [{"Expected a maximum of #{max_items} items but got #{count}.", []}]
    end
  end

  defp validate_aspect(_, _, {"uniqueItems", true}, items) when is_list(items) do
    case Enum.uniq(items) == items do
      true -> []
      false -> [{"Expected items to be unique but they were not.", []}]
    end
  end

  defp validate_aspect(_, _, {"enum", enum}, data) do
    case Enum.any?(enum, &(&1 === data)) do
      true -> []
      false -> [{"Value #{inspect(data)} is not allowed in enum.", []}]
    end
  end

  defp validate_aspect(_, schema, {"minimum", minimum}, data) when is_number(data) do
    exclusive? = schema["exclusiveMinimum"]
    fun = if exclusive?, do: &Kernel.>/2, else: &Kernel.>=/2
    case fun.(data, minimum) do
      true -> []
      false -> [{"Expected the value to be #{if exclusive?, do: ">", else: ">="} #{minimum}", []}]
    end
  end

  defp validate_aspect(_, schema, {"maximum", maximum}, data) when is_number(data) do
    exclusive? = schema["exclusiveMaximum"]
    fun = if exclusive?, do: &Kernel.</2, else: &Kernel.<=/2
    case fun.(data, maximum) do
      true -> []
      false -> [{"Expected the value to be #{if exclusive?, do: "<", else: "<="} #{maximum}", []}]
    end
  end

  defp validate_aspect(_, _, {"multipleOf", multiple_of}, data) when is_number(data) do
    factor = data / multiple_of
    case Float.floor(factor) == factor do
      true -> []
      false -> [{"Expected value to be a multiple of #{multiple_of} but got #{data}.", []}]
    end
  end

  defp validate_aspect(_, _, {"minLength", min_length}, data) when is_binary(data) do
    case (length = String.length(data)) >= min_length do
      true -> []
      false -> [{"Expected value to have a minimum length of #{min_length} but was #{length}.", []}]
    end
  end

  defp validate_aspect(_, _, {"maxLength", max_length}, data) when is_binary(data) do
    case (length = String.length(data)) <= max_length do
      true -> []
      false -> [{"Expected value to have a maximum length of #{max_length} but was #{length}.", []}]
    end
  end

  defp validate_aspect(_, _, {"pattern", pattern}, data) when is_binary(data) do
    case pattern |> Regex.compile! |> Regex.match?(data) do
      true -> []
      false -> [{"String #{inspect(data)} does not match pattern #{inspect(pattern)}.", []}]
    end
  end

  defp validate_aspect(_, _, {"format", format}, data) do
    Format.validate(format, data)
  end

  defp validate_aspect(_, _, _, _), do: []

  defp validation_result_indexes(root, schemata, data, filter) do
    schemata
    |> Enum.map(&valid?(root, &1, data))
    |> Enum.with_index
    |> Enum.filter(filter)
    |> Enum.map(fn {_k, v} -> v end)
  end
end
