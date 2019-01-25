defmodule NExJsonSchema.Validator do
  alias NExJsonSchema.Validator.Dependencies
  alias NExJsonSchema.Validator.Format
  alias NExJsonSchema.Validator.Items
  alias NExJsonSchema.Validator.Properties
  alias NExJsonSchema.Validator.Type
  alias NExJsonSchema.Schema
  alias NExJsonSchema.Schema.Root

  @type errors :: [{String.t(), String.t()}] | []
  @type errors_with_list_paths :: [{String.t(), [String.t() | integer]}] | []

  @spec validate(Root.t(), NExJsonSchema.data()) :: :ok | {:error, errors}
  def validate(root = %Root{}, data) do
    errors = validate(root, root.schema, data, ["$"]) |> errors_with_string_paths

    case Enum.empty?(errors) do
      true -> :ok
      false -> {:error, errors}
    end
  end

  @spec validate(NExJsonSchema.json(), NExJsonSchema.data()) :: :ok | {:error, errors}
  def validate(schema = %{}, data) do
    validate(Schema.resolve(schema), data)
  end

  @spec validate(Root.t(), Schema.resolved(), NExJsonSchema.data(), [String.t() | integer]) :: errors_with_list_paths
  def validate(root, schema, data, path \\ []) do
    schema
    |> Enum.flat_map(&validate_aspect(root, schema, &1, data))
    |> Enum.map(fn {%{} = rules, p} -> {rules, path ++ p} end)
  end

  @spec valid?(Root.t(), NExJsonSchema.data()) :: boolean
  def valid?(root = %Root{}, data), do: valid?(root, root.schema, data)

  @spec valid?(NExJsonSchema.json(), NExJsonSchema.data()) :: boolean
  def valid?(schema = %{}, data), do: valid?(Schema.resolve(schema), data)

  @spec valid?(Root.t(), Schema.resolved(), NExJsonSchema.data()) :: boolean
  def valid?(root, schema, data), do: validate(root, schema, data) |> Enum.empty?()

  defp errors_with_string_paths(errors) do
    Enum.map(errors, fn {msg, path} -> {msg, Enum.join(path, ".")} end)
  end

  def format_error(rule, raw_description, params \\ []) do
    %{
      raw_description: raw_description,
      description: format_description(raw_description, params),
      rule: rule,
      params: Map.new(params)
    }
  end

  defp validate_aspect(root, _, {"$ref", path}, data) do
    schema = Schema.get_ref_schema(root, path)
    validate(root, schema, data)
  end

  defp validate_aspect(root, _, {"allOf", all_of}, data) do
    invalid_indexes = validation_result_indexes(root, all_of, data, &(!elem(&1, 0)))

    case Enum.empty?(invalid_indexes) do
      true ->
        []

      false ->
        [
          {format_error(
             :schemata,
             "expected all of the schemata to match, but the schemata at the following indexes did not: %{indexes}",
             indexes: invalid_indexes
           ), []}
        ]
    end
  end

  defp validate_aspect(root, _, {"anyOf", any_of}, data) do
    case Enum.any?(any_of, &valid?(root, &1, data)) do
      true ->
        []

      false ->
        [{format_error(:schemata, "expected any of the schemata to match but none did"), []}]
    end
  end

  defp validate_aspect(root, _, {"oneOf", one_of}, data) do
    valid_indexes = validation_result_indexes(root, one_of, data, &elem(&1, 0))

    case Enum.empty?(valid_indexes) do
      true ->
        [{format_error(:schemata, "expected exactly one of the schemata to match, but none of them did"), []}]

      false ->
        if Enum.count(valid_indexes) == 1 do
          []
        else
          [
            {format_error(
               :schemata,
               "expected exactly one of the schemata to match, but the schemata at the following indexes did: %{indexes}",
               indexes: valid_indexes
             ), []}
          ]
        end
    end
  end

  defp validate_aspect(root, _, {"not", not_schema}, data) do
    case valid?(root, not_schema, data) do
      true ->
        [
          {format_error(
             :schema,
             "expected schema not to match but it did"
           ), []}
        ]

      false ->
        []
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
      true ->
        []

      false ->
        [
          {format_error(
             :length,
             "expected a minimum of %{min} properties but got %{actual}",
             min: min_properties,
             actual: Map.size(data)
           ), []}
        ]
    end
  end

  defp validate_aspect(_, _, {"maxProperties", max_properties}, data) when is_map(data) do
    case Map.size(data) <= max_properties do
      true ->
        []

      false ->
        [
          {format_error(
             :length,
             "expected a maximum of %{max} properties but got %{actual}",
             max: max_properties,
             actual: Map.size(data)
           ), []}
        ]
    end
  end

  defp validate_aspect(_, _, {"required", required}, data = %{}) do
    Enum.flat_map(List.wrap(required), fn property ->
      case Map.has_key?(data, property) do
        true ->
          []

        false ->
          [
            {format_error(
               :required,
               "required property %{property} was not present",
               property: property
             ), [property]}
          ]
      end
    end)
  end

  defp validate_aspect(root, _, {"dependencies", dependencies}, data) do
    Dependencies.validate(root, dependencies, data)
  end

  defp validate_aspect(root, schema, {"items", _}, items) do
    Items.validate(root, schema, items)
  end

  defp validate_aspect(_, _, {"minItems", min_items}, items) when is_list(items) do
    case (count = Enum.count(items)) >= min_items do
      true ->
        []

      false ->
        [
          {format_error(
             :length,
             "expected a minimum of %{min} items but got %{actual}",
             min: min_items,
             actual: count
           ), []}
        ]
    end
  end

  defp validate_aspect(_, _, {"maxItems", max_items}, items) when is_list(items) do
    case (count = Enum.count(items)) <= max_items do
      true ->
        []

      false ->
        [
          {format_error(
             :length,
             "expected a maximum of %{max} items but got %{actual}",
             max: max_items,
             actual: count
           ), []}
        ]
    end
  end

  defp validate_aspect(_, _, {"uniqueItems", true}, items) when is_list(items) do
    case Enum.uniq(items) == items do
      true ->
        []

      false ->
        [
          {format_error(
             :unique,
             "expected items to be unique but they were not"
           ), []}
        ]
    end
  end

  defp validate_aspect(_, _, {"enum", enum}, data) do
    case Enum.any?(enum, &(&1 === data)) do
      true ->
        []

      false ->
        [
          {format_error(
             :inclusion,
             "value is not allowed in enum",
             values: enum
           ), []}
        ]
    end
  end

  defp validate_aspect(_, schema, {"minimum", minimum}, data) when is_number(data) do
    exclusive? = schema["exclusiveMinimum"]
    fun = if exclusive?, do: &Kernel.>/2, else: &Kernel.>=/2

    case fun.(data, minimum) do
      true ->
        []

      false ->
        [
          {format_error(
             :number,
             "expected the value to be #{if exclusive?, do: "> %{greater_than}", else: ">= %{greater_than_or_equal_to}"}",
             get_number_validation_params(:minimum, minimum, exclusive?)
           ), []}
        ]
    end
  end

  defp validate_aspect(_, schema, {"maximum", maximum}, data) when is_number(data) do
    exclusive? = schema["exclusiveMaximum"]
    fun = if exclusive?, do: &Kernel.</2, else: &Kernel.<=/2

    case fun.(data, maximum) do
      true ->
        []

      false ->
        [
          {format_error(
             :number,
             "expected the value to be #{if exclusive?, do: "< %{less_than}", else: "<= %{less_than_or_equal_to}"}",
             get_number_validation_params(:maximum, maximum, exclusive?)
           ), []}
        ]
    end
  end

  defp validate_aspect(_, _, {"multipleOf", multiple_of}, data) when is_number(data) do
    factor = data / multiple_of

    case Float.floor(factor) == factor do
      true ->
        []

      false ->
        [
          {format_error(
             :number,
             "expected value to be a multiple of %{multiple_of} but got %{actual}",
             multiple_of: multiple_of,
             actual: data
           ), []}
        ]
    end
  end

  defp validate_aspect(_, _, {"minLength", min_length}, data) when is_binary(data) do
    case (length = String.length(data)) >= min_length do
      true ->
        []

      false ->
        [
          {format_error(
             :length,
             "expected value to have a minimum length of %{min} but was %{actual}",
             min: min_length,
             actual: length
           ), []}
        ]
    end
  end

  defp validate_aspect(_, _, {"maxLength", max_length}, data) when is_binary(data) do
    case (length = String.length(data)) <= max_length do
      true ->
        []

      false ->
        [
          {format_error(
             :length,
             "expected value to have a maximum length of %{max} but was %{actual}",
             max: max_length,
             actual: length
           ), []}
        ]
    end
  end

  defp validate_aspect(_, _, {"pattern", pattern}, data) when is_binary(data) do
    case pattern |> Regex.compile!("u") |> Regex.match?(data) do
      true ->
        []

      false ->
        [
          {format_error(
             :format,
             "string does not match pattern \"%{pattern}\"",
             pattern: pattern
           ), []}
        ]
    end
  end

  defp validate_aspect(_, _, {"format", format}, data) do
    Format.validate(format, data)
  end

  defp validate_aspect(_, _, _, _), do: []

  defp format_description(raw_description, params) do
    Enum.reduce(params, raw_description, fn {key, value}, acc ->
      template = "%{#{key}}"

      case String.contains?(acc, template) do
        true -> String.replace(acc, template, format_parameter(value))
        false -> acc
      end
    end)
  end

  defp format_parameter(value) when is_list(value), do: Enum.join(value, ", ")
  defp format_parameter(value), do: to_string(value)

  defp get_number_validation_params(:maximum, value, true), do: [less_than: value]
  defp get_number_validation_params(:maximum, value, _), do: [less_than_or_equal_to: value]
  defp get_number_validation_params(:minimum, value, true), do: [greater_than: value]
  defp get_number_validation_params(:minimum, value, _), do: [greater_than_or_equal_to: value]

  defp validation_result_indexes(root, schemata, data, filter) do
    schemata
    |> Enum.map(&valid?(root, &1, data))
    |> Enum.with_index()
    |> Enum.filter(filter)
    |> Dict.values()
  end
end
