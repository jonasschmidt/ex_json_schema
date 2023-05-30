defmodule ExJsonSchema.Validator.Properties do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"properties"` attributes.

  See:

  """

  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Context
  alias ExJsonSchema.Validator.Result
  alias ExJsonSchema.Validator.Error

  @behaviour ExJsonSchema.Validator

  @impl ExJsonSchema.Validator
  def validate(root, schema, {"properties", _}, properties = %{}, context) do
    do_validate(root, schema, properties, context)
  end

  def validate(_, _, _, _, _) do
    Result.new()
  end

  defp do_validate(root, schema, properties, context) do
    validated_known_properties = validate_known_properties(root, schema, properties, context)

    validation_errors(validated_known_properties)
    |> Result.merge(
      validate_additional_properties(
        root,
        schema["additionalProperties"],
        unvalidated_properties(properties, validated_known_properties),
        context
      )
    )
  end

  defp validate_known_properties(root, schema, properties, context) do
    validate_named_properties(root, schema["properties"], properties, context) ++
      validate_pattern_properties(root, schema["patternProperties"], properties, context)
  end

  defp validate_named_properties(root, schema, properties, context) do
    schema
    |> Enum.filter(&Map.has_key?(properties, elem(&1, 0)))
    |> Enum.map(fn
      {name, property_schema} ->
        result =
          Validator.validation_result(root, property_schema, properties[name], Context.append_path(context, "/#{name}"))
          |> Result.add_annotation(name, %{evaluated: true})

        {name, result}
    end)
  end

  defp validate_pattern_properties(_, nil, _, _), do: []

  defp validate_pattern_properties(root, schema, properties, context) do
    Enum.flat_map(schema, &validate_pattern_property(root, &1, properties, context))
  end

  defp validate_pattern_property(root, {pattern, schema}, properties, context) do
    properties_matching(properties, pattern)
    |> Enum.map(fn {name, property} ->
      result =
        Validator.validation_result(root, schema, property, Context.append_path(context, "/#{name}"))
        |> Result.add_annotation(name, %{evaluated: true})

      {name, result}
    end)
  end

  defp validate_additional_properties(root, schema, properties, context) when is_map(schema) do
    Enum.map(properties, fn {name, property} ->
      Validator.validation_result(root, schema, property, Context.append_path(context, "/#{name}"))
      |> Result.add_annotation(name, %{evaluated: true})
    end)
    |> Enum.reduce(Result.new(), &Result.merge/2)
  end

  defp validate_additional_properties(_, false, properties, context) when map_size(properties) > 0 do
    Enum.map(properties, fn {name, _} ->
      %Error{error: %Error.AdditionalProperties{}, path: Context.append_path(context, "/#{name}").path}
    end)
    |> Result.with_errors()
  end

  defp validate_additional_properties(_, true, properties, _context) do
    Enum.reduce(properties, Result.new(), fn {name, _}, result ->
      Result.add_annotation(result, name, %{evaluated: true})
    end)
  end

  defp validate_additional_properties(_, _, _, _), do: Result.new()

  defp validation_errors(validated_properties) do
    validated_properties |> Keyword.values() |> Enum.reduce(Result.new(), &Result.merge/2)
  end

  defp properties_matching(properties, pattern) do
    regex = Regex.compile!(pattern)
    Enum.filter(properties, &Regex.match?(regex, elem(&1, 0)))
  end

  defp unvalidated_properties(properties, validated_properties) do
    keys =
      properties
      |> keys_as_set()
      |> MapSet.difference(keys_as_set(validated_properties))
      |> Enum.to_list()

    Map.take(properties, keys)
  end

  defp keys_as_set(properties) do
    properties |> Enum.map(&elem(&1, 0)) |> Enum.into(MapSet.new())
  end
end
