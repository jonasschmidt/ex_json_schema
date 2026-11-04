defmodule ExJsonSchema.Evaluator.BasicEngine do
  @moduledoc false

  # Executes compiled plans directly into basic output when full contextual
  # evaluation and annotation collection are unnecessary.

  alias ExJsonSchema.CompiledSchema
  alias ExJsonSchema.Compiler.EvaluationPlan
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Resource
  alias ExJsonSchema.Evaluator.Number

  @spec validate(ExJsonSchema.data(), CompiledSchema.t()) :: {:ok, map()} | :fallback
  def validate(instance, compiled) do
    %Location{resource: resource_uri, pointer: pointer} =
      location = CompiledSchema.entrypoint(compiled)

    %Resource{evaluation_plans: evaluation_plans} =
      resource = Map.fetch!(CompiledSchema.resources(compiled), resource_uri)

    with {:ok, %EvaluationPlan{validity: validity, annotations?: annotations?}} <-
           Map.fetch(evaluation_plans, pointer),
         false <- validity == :fallback,
         {valid, errors} <-
           evaluate(validity, instance, resource, pointer, []),
         false <- valid and annotations? do
      {:ok, root_output(valid, errors, resource, location)}
    else
      _unsupported_or_annotated -> :fallback
    end
  end

  defp evaluate({:boolean, true}, _instance, _resource, _pointer, _instance_pointer),
    do: {true, []}

  defp evaluate({:boolean, false}, _instance, resource, pointer, instance_pointer) do
    {false, [error_unit(resource, pointer, instance_pointer, "boolean schema is false")]}
  end

  defp evaluate({:all, instructions}, instance, resource, pointer, instance_pointer) do
    Enum.reduce_while(instructions, {true, []}, fn instruction, {valid, chunks} ->
      case evaluate_instruction(instruction, instance, resource, pointer, instance_pointer) do
        :fallback ->
          {:halt, :fallback}

        {next_valid, errors} ->
          {:cont, {valid and next_valid, [errors | chunks]}}
      end
    end)
    |> case do
      :fallback -> :fallback
      {valid, chunks} -> {valid, chunks |> Enum.reverse() |> :lists.append()}
    end
  end

  defp evaluate_instruction(
         {:type, expected, version},
         instance,
         resource,
         pointer,
         instance_pointer
       ) do
    valid = type_valid?(expected, instance, version)

    outcome(
      valid,
      resource,
      pointer ++ ["type"],
      instance_pointer,
      "value does not match type #{inspect(expected)}"
    )
  end

  defp evaluate_instruction({:const, expected}, instance, resource, pointer, instance_pointer) do
    outcome(
      json_equal?(expected, instance),
      resource,
      pointer ++ ["const"],
      instance_pointer,
      "value does not equal the constant"
    )
  end

  defp evaluate_instruction({:enum, values}, instance, resource, pointer, instance_pointer) do
    outcome(
      Enum.any?(values, &json_equal?(&1, instance)),
      resource,
      pointer ++ ["enum"],
      instance_pointer,
      "value is not one of the enumerated values"
    )
  end

  defp evaluate_instruction(
         {:multiple_of, divisor},
         instance,
         resource,
         pointer,
         instance_pointer
       ) do
    outcome(
      not is_number(instance) or Number.multiple_of?(instance, divisor),
      resource,
      pointer ++ ["multipleOf"],
      instance_pointer,
      "number is not a multiple of #{inspect(divisor)}"
    )
  end

  defp evaluate_instruction(
         {:maximum, keyword, limit, exclusive?},
         instance,
         resource,
         pointer,
         instance_pointer
       ) do
    valid =
      not is_number(instance) or
        if(exclusive?, do: instance < limit, else: instance <= limit)

    outcome(
      valid,
      resource,
      pointer ++ [keyword],
      instance_pointer,
      "number exceeds #{keyword} #{inspect(limit)}"
    )
  end

  defp evaluate_instruction(
         {:minimum, keyword, limit, exclusive?},
         instance,
         resource,
         pointer,
         instance_pointer
       ) do
    valid =
      not is_number(instance) or
        if(exclusive?, do: instance > limit, else: instance >= limit)

    outcome(
      valid,
      resource,
      pointer ++ [keyword],
      instance_pointer,
      "number is below #{keyword} #{inspect(limit)}"
    )
  end

  defp evaluate_instruction(
         {:count, keyword, limit},
         instance,
         resource,
         pointer,
         instance_pointer
       ) do
    outcome(
      count_valid?(keyword, instance, limit),
      resource,
      pointer ++ [keyword],
      instance_pointer,
      "#{keyword} constraint failed"
    )
  end

  defp evaluate_instruction({:pattern, pattern}, instance, resource, pointer, instance_pointer) do
    outcome(
      not is_binary(instance) or pattern_matches?(pattern, instance),
      resource,
      pointer ++ ["pattern"],
      instance_pointer,
      "string does not match pattern"
    )
  end

  defp evaluate_instruction(
         {:required, required},
         instance,
         resource,
         pointer,
         instance_pointer
       ) do
    missing =
      if is_map(instance),
        do: Enum.reject(required, &Map.has_key?(instance, &1)),
        else: []

    outcome(
      missing == [],
      resource,
      pointer ++ ["required"],
      instance_pointer,
      "required properties are missing: #{inspect(missing)}"
    )
  end

  defp evaluate_instruction(:unique_items, instance, resource, pointer, instance_pointer) do
    valid = not is_list(instance) or unique_json_values?(instance)

    outcome(
      valid,
      resource,
      pointer ++ ["uniqueItems"],
      instance_pointer,
      "array items are not unique"
    )
  end

  defp evaluate_instruction({:items, child}, instance, resource, pointer, instance_pointer) do
    if is_list(instance) do
      child = resolve_child(child, resource, pointer, ["items"])

      {valid, errors} =
        instance
        |> Enum.with_index()
        |> Enum.reduce({true, []}, fn {item, index}, {valid, chunks} ->
          item_pointer = instance_pointer ++ [index]

          if evaluate_resolved_child_valid?(child, item, resource) do
            {valid, chunks}
          else
            {false,
             [
               evaluate_resolved_child(child, item, resource, item_pointer) |> elem(1)
               | chunks
             ]}
          end
        end)
        |> then(fn {valid, chunks} ->
          {valid, chunks |> Enum.reverse() |> :lists.append()}
        end)

      applicator_outcome(
        valid,
        errors,
        resource,
        pointer ++ ["items"],
        instance_pointer,
        "items failed"
      )
    else
      {true, []}
    end
  end

  defp evaluate_instruction(
         {:properties, properties},
         instance,
         resource,
         pointer,
         instance_pointer
       ) do
    if is_map(instance) do
      {valid, errors} =
        reduce_present_properties(
          instance,
          properties,
          {true, []},
          fn name, child, value, {valid, chunks} ->
            child = resolve_child(child, resource, pointer, ["properties", name])
            property_pointer = instance_pointer ++ [name]

            if evaluate_resolved_child_valid?(child, value, resource) do
              {valid, chunks}
            else
              {false,
               [
                 evaluate_resolved_child(child, value, resource, property_pointer) |> elem(1)
                 | chunks
               ]}
            end
          end
        )
        |> then(fn {valid, chunks} ->
          {valid, chunks |> Enum.reverse() |> :lists.append()}
        end)

      applicator_outcome(
        valid,
        errors,
        resource,
        pointer ++ ["properties"],
        instance_pointer,
        "properties failed"
      )
    else
      {true, []}
    end
  end

  defp evaluate_instruction(
         {:contains, child, minimum, maximum},
         instance,
         resource,
         pointer,
         instance_pointer
       ) do
    if is_list(instance) do
      child = resolve_child(child, resource, pointer, ["contains"])

      {valid, matches} =
        contains_outcome(instance, child, resource, minimum, maximum)

      applicator_outcome(
        valid,
        [],
        resource,
        pointer ++ ["contains"],
        instance_pointer,
        "array contains #{matches} matching items"
      )
    else
      {true, []}
    end
  end

  defp evaluate_instruction(
         {:properties_with_unevaluated, properties, unevaluated},
         instance,
         resource,
         pointer,
         _instance_pointer
       ) do
    if is_map(instance) do
      unevaluated = resolve_child(unevaluated, resource, pointer, ["unevaluatedProperties"])

      valid =
        Enum.all?(instance, fn {name, value} ->
          child =
            case Map.fetch(properties, name) do
              {:ok, child} -> resolve_child(child, resource, pointer, ["properties", name])
              :error -> unevaluated
            end

          evaluate_resolved_child_valid?(child, value, resource)
        end)

      if valid, do: {true, []}, else: :fallback
    else
      {true, []}
    end
  end

  defp evaluate_instruction(
         {:unevaluated_properties, child},
         instance,
         resource,
         pointer,
         _instance_pointer
       ) do
    if is_map(instance) do
      child = resolve_child(child, resource, pointer, ["unevaluatedProperties"])

      valid =
        Enum.all?(instance, fn {_name, value} ->
          evaluate_resolved_child_valid?(child, value, resource)
        end)

      if valid, do: {true, []}, else: :fallback
    else
      {true, []}
    end
  end

  defp contains_outcome(_instance, {{:boolean, false}, _pointer}, _resource, minimum, _maximum),
    do: {minimum == 0, 0}

  defp contains_outcome(
         instance,
         {{:boolean, true}, _pointer},
         _resource,
         minimum,
         :infinity
       ) do
    list_count_until(instance, minimum, 0)
  end

  defp contains_outcome(
         instance,
         {{:boolean, true}, _pointer},
         _resource,
         minimum,
         maximum
       ) do
    matches = length(instance)
    {matches >= minimum and matches <= maximum, matches}
  end

  defp contains_outcome(_instance, _child, _resource, 0, :infinity), do: {true, 0}

  defp contains_outcome(instance, child, resource, minimum, :infinity) do
    contains_at_least(instance, child, resource, minimum, 0)
  end

  defp contains_outcome(instance, child, resource, minimum, maximum) do
    matches = Enum.count(instance, &evaluate_resolved_child_valid?(child, &1, resource))
    {matches >= minimum and matches <= maximum, matches}
  end

  defp contains_at_least([], _child, _resource, _minimum, matches), do: {false, matches}

  defp contains_at_least([item | rest], child, resource, minimum, matches) do
    matches =
      if evaluate_resolved_child_valid?(child, item, resource),
        do: matches + 1,
        else: matches

    if matches >= minimum do
      {true, matches}
    else
      contains_at_least(rest, child, resource, minimum, matches)
    end
  end

  defp list_count_until(_items, minimum, matches) when matches >= minimum,
    do: {true, matches}

  defp list_count_until([], _minimum, matches), do: {false, matches}

  defp list_count_until([_item | rest], minimum, matches),
    do: list_count_until(rest, minimum, matches + 1)

  defp reduce_present_properties(instance, properties, accumulator, reducer) do
    if map_size(instance) < map_size(properties) do
      Enum.reduce(instance, accumulator, fn {name, value}, accumulator ->
        case Map.fetch(properties, name) do
          {:ok, child} -> reducer.(name, child, value, accumulator)
          :error -> accumulator
        end
      end)
    else
      Enum.reduce(properties, accumulator, fn {name, child}, accumulator ->
        case Map.fetch(instance, name) do
          {:ok, value} -> reducer.(name, child, value, accumulator)
          :error -> accumulator
        end
      end)
    end
  end

  defp resolve_child({:boolean, valid}, _resource, pointer, relative) do
    {{:boolean, valid}, pointer ++ relative}
  end

  defp resolve_child(
         {:plan, relative},
         %Resource{evaluation_plans: evaluation_plans},
         pointer,
         _fallback_relative
       ) do
    pointer = pointer ++ relative
    %EvaluationPlan{validity: validity} = Map.fetch!(evaluation_plans, pointer)
    {validity, pointer}
  end

  defp evaluate_resolved_child({validity, pointer}, instance, resource, instance_pointer),
    do: evaluate(validity, instance, resource, pointer, instance_pointer)

  defp evaluate_resolved_child_valid?({validity, pointer}, instance, resource),
    do: evaluate_valid?(validity, instance, resource, pointer)

  defp evaluate_valid?({:boolean, valid}, _instance, _resource, _pointer), do: valid

  defp evaluate_valid?({:all, instructions}, instance, resource, pointer) do
    Enum.all?(instructions, &evaluate_instruction_valid?(&1, instance, resource, pointer))
  end

  defp evaluate_instruction_valid?({:type, expected, version}, instance, _resource, _pointer),
    do: type_valid?(expected, instance, version)

  defp evaluate_instruction_valid?({:const, expected}, instance, _resource, _pointer),
    do: json_equal?(expected, instance)

  defp evaluate_instruction_valid?({:enum, values}, instance, _resource, _pointer),
    do: Enum.any?(values, &json_equal?(&1, instance))

  defp evaluate_instruction_valid?(
         {:multiple_of, divisor},
         instance,
         _resource,
         _pointer
       ),
       do: not is_number(instance) or Number.multiple_of?(instance, divisor)

  defp evaluate_instruction_valid?(
         {:maximum, _keyword, limit, exclusive?},
         instance,
         _resource,
         _pointer
       ),
       do:
         not is_number(instance) or
           if(exclusive?, do: instance < limit, else: instance <= limit)

  defp evaluate_instruction_valid?(
         {:minimum, _keyword, limit, exclusive?},
         instance,
         _resource,
         _pointer
       ),
       do:
         not is_number(instance) or
           if(exclusive?, do: instance > limit, else: instance >= limit)

  defp evaluate_instruction_valid?(
         {:count, keyword, limit},
         instance,
         _resource,
         _pointer
       ),
       do: count_valid?(keyword, instance, limit)

  defp evaluate_instruction_valid?({:pattern, pattern}, instance, _resource, _pointer),
    do: not is_binary(instance) or pattern_matches?(pattern, instance)

  defp evaluate_instruction_valid?({:required, required}, instance, _resource, _pointer),
    do: not is_map(instance) or Enum.all?(required, &Map.has_key?(instance, &1))

  defp evaluate_instruction_valid?(:unique_items, instance, _resource, _pointer),
    do: not is_list(instance) or unique_json_values?(instance)

  defp evaluate_instruction_valid?({:items, child}, instance, resource, pointer) do
    not is_list(instance) or
      child
      |> resolve_child(resource, pointer, ["items"])
      |> then(fn child ->
        Enum.all?(instance, &evaluate_resolved_child_valid?(child, &1, resource))
      end)
  end

  defp evaluate_instruction_valid?({:properties, properties}, instance, resource, pointer) do
    not is_map(instance) or
      Enum.all?(properties, fn {name, child} ->
        case Map.fetch(instance, name) do
          {:ok, value} ->
            child
            |> resolve_child(resource, pointer, ["properties", name])
            |> evaluate_resolved_child_valid?(value, resource)

          :error ->
            true
        end
      end)
  end

  defp evaluate_instruction_valid?(
         {:contains, child, minimum, maximum},
         instance,
         resource,
         pointer
       ) do
    if is_list(instance) do
      child = resolve_child(child, resource, pointer, ["contains"])
      {valid, _matches} = contains_outcome(instance, child, resource, minimum, maximum)
      valid
    else
      true
    end
  end

  defp evaluate_instruction_valid?(
         {:properties_with_unevaluated, properties, unevaluated},
         instance,
         resource,
         pointer
       ) do
    if is_map(instance) do
      unevaluated = resolve_child(unevaluated, resource, pointer, ["unevaluatedProperties"])

      Enum.all?(instance, fn {name, value} ->
        child =
          case Map.fetch(properties, name) do
            {:ok, child} -> resolve_child(child, resource, pointer, ["properties", name])
            :error -> unevaluated
          end

        evaluate_resolved_child_valid?(child, value, resource)
      end)
    else
      true
    end
  end

  defp evaluate_instruction_valid?(
         {:unevaluated_properties, child},
         instance,
         resource,
         pointer
       ) do
    if is_map(instance) do
      child = resolve_child(child, resource, pointer, ["unevaluatedProperties"])

      Enum.all?(instance, fn {_name, value} ->
        evaluate_resolved_child_valid?(child, value, resource)
      end)
    else
      true
    end
  end

  defp applicator_outcome(true, _errors, _resource, _pointer, _instance_pointer, _message),
    do: {true, []}

  defp applicator_outcome(
         false,
         errors,
         resource,
         pointer,
         instance_pointer,
         message
       ) do
    {false, [error_unit(resource, pointer, instance_pointer, message) | errors]}
  end

  defp outcome(true, _resource, _pointer, _instance_pointer, _message), do: {true, []}

  defp outcome(false, resource, pointer, instance_pointer, message) do
    {false, [error_unit(resource, pointer, instance_pointer, message)]}
  end

  defp root_output(valid, errors, resource, %Location{pointer: pointer}) do
    resource
    |> output_unit(pointer, [], valid)
    |> maybe_put_errors(valid, errors)
  end

  defp maybe_put_errors(output, true, _errors), do: output
  defp maybe_put_errors(output, false, []), do: Map.put(output, "error", "validation failed")
  defp maybe_put_errors(output, false, errors), do: Map.put(output, "errors", errors)

  defp error_unit(resource, pointer, instance_pointer, message) do
    resource
    |> output_unit(pointer, instance_pointer, false)
    |> Map.put("error", message)
  end

  defp output_unit(
         %Resource{origin_location: origin_location, canonical_uri: canonical_uri},
         pointer,
         instance_pointer,
         valid
       ) do
    %Location{resource: origin_resource, pointer: origin_pointer} =
      origin_location || Location.root(canonical_uri)

    keyword_location = %Location{
      resource: origin_resource,
      pointer: origin_pointer ++ pointer
    }

    absolute_keyword_location = %Location{
      resource: canonical_uri,
      pointer: pointer
    }

    %{
      "valid" => valid,
      "keywordLocation" => Location.pointer(keyword_location),
      "instanceLocation" => Location.pointer(%Location{pointer: instance_pointer})
    }
    |> maybe_put_absolute(Location.absolute_uri(absolute_keyword_location))
  end

  defp maybe_put_absolute(output, nil), do: output

  defp maybe_put_absolute(output, absolute_keyword_location),
    do: Map.put(output, "absoluteKeywordLocation", absolute_keyword_location)

  defp type_valid?(types, instance, version) when is_list(types),
    do: Enum.any?(types, &type_valid?(&1, instance, version))

  defp type_valid?("null", instance, _version), do: is_nil(instance)
  defp type_valid?("boolean", instance, _version), do: is_boolean(instance)
  defp type_valid?("object", instance, _version), do: is_map(instance)
  defp type_valid?("array", instance, _version), do: is_list(instance)
  defp type_valid?("number", instance, _version), do: is_number(instance)
  defp type_valid?("string", instance, _version), do: is_binary(instance)
  defp type_valid?("integer", instance, _version) when is_integer(instance), do: true
  defp type_valid?("integer", instance, 4), do: is_integer(instance)

  defp type_valid?("integer", instance, _version),
    do: is_float(instance) and Float.floor(instance) == instance

  defp type_valid?(_type, _instance, _version), do: false

  defp count_valid?("maxLength", value, limit) when is_binary(value),
    do: String.length(value) <= limit

  defp count_valid?("minLength", value, limit) when is_binary(value),
    do: String.length(value) >= limit

  defp count_valid?("maxItems", value, limit) when is_list(value), do: length(value) <= limit
  defp count_valid?("minItems", value, limit) when is_list(value), do: length(value) >= limit

  defp count_valid?("maxProperties", value, limit) when is_map(value),
    do: map_size(value) <= limit

  defp count_valid?("minProperties", value, limit) when is_map(value),
    do: map_size(value) >= limit

  defp count_valid?(_keyword, _value, _limit), do: true

  defp pattern_matches?(pattern, value) do
    pattern
    |> String.replace("\\p{Letter}", "\\p{L}")
    |> String.replace("\\P{Letter}", "\\P{L}")
    |> Regex.compile("u")
    |> case do
      {:ok, regex} -> Regex.match?(regex, value)
      {:error, _reason} -> false
    end
  end

  defp unique_json_values?(values) do
    Enum.reduce_while(values, %{}, fn value, seen ->
      key = json_equality_key(value)

      if Map.has_key?(seen, key) do
        {:halt, false}
      else
        {:cont, Map.put(seen, key, true)}
      end
    end)
    |> is_map()
  end

  defp json_equality_key(value) when is_integer(value), do: value

  defp json_equality_key(value) when is_float(value) do
    integer = trunc(value)
    if(value == integer, do: integer, else: value)
  end

  defp json_equality_key(value) when is_map(value) do
    entries =
      value
      |> Enum.map(fn {key, child} -> {key, json_equality_key(child)} end)
      |> Enum.sort()

    {:object, entries}
  end

  defp json_equality_key(value) when is_list(value),
    do: {:array, Enum.map(value, &json_equality_key/1)}

  defp json_equality_key(value), do: value

  defp json_equal?(left, right) when is_number(left) and is_number(right), do: left == right

  defp json_equal?(left, right) when is_map(left) and is_map(right) do
    map_size(left) == map_size(right) and
      Enum.all?(left, fn {key, value} ->
        case Map.fetch(right, key) do
          {:ok, other} -> json_equal?(value, other)
          :error -> false
        end
      end)
  end

  defp json_equal?(left, right) when is_list(left) and is_list(right) do
    length(left) == length(right) and
      Enum.zip(left, right) |> Enum.all?(fn {a, b} -> json_equal?(a, b) end)
  end

  defp json_equal?(left, right), do: left === right
end
