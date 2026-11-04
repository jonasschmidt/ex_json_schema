defmodule ExJsonSchema.Evaluator.FlagEngine do
  @moduledoc false

  # Executes supported compiled plans with boolean-only short-circuiting and
  # falls back when contextual evaluation is required.

  alias ExJsonSchema.CompiledSchema
  alias ExJsonSchema.Compiler.EvaluationPlan
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Resource
  alias ExJsonSchema.Evaluator.Number

  @spec valid?(ExJsonSchema.data(), CompiledSchema.t()) :: {:ok, boolean()} | :fallback
  def valid?(instance, compiled) do
    %Location{resource: resource_uri, pointer: pointer} =
      CompiledSchema.entrypoint(compiled)

    %Resource{evaluation_plans: evaluation_plans} =
      resource = Map.fetch!(CompiledSchema.resources(compiled), resource_uri)

    case Map.fetch(evaluation_plans, pointer) do
      {:ok, %EvaluationPlan{validity: :fallback}} ->
        :fallback

      {:ok, %EvaluationPlan{validity: validity}} ->
        {:ok, evaluate(validity, instance, resource, pointer)}

      :error ->
        :fallback
    end
  end

  defp evaluate({:boolean, valid}, _instance, _resource, _pointer), do: valid

  defp evaluate({:all, instructions}, instance, resource, pointer) do
    Enum.all?(instructions, &evaluate_instruction(&1, instance, resource, pointer))
  end

  defp evaluate_instruction({:type, expected, version}, instance, _resource, _pointer) do
    type_valid?(expected, instance, version)
  end

  defp evaluate_instruction({:const, expected}, instance, _resource, _pointer) do
    json_equal?(expected, instance)
  end

  defp evaluate_instruction({:enum, values}, instance, _resource, _pointer) do
    Enum.any?(values, &json_equal?(&1, instance))
  end

  defp evaluate_instruction({:multiple_of, divisor}, instance, _resource, _pointer) do
    not is_number(instance) or Number.multiple_of?(instance, divisor)
  end

  defp evaluate_instruction(
         {:maximum, _keyword, limit, exclusive?},
         instance,
         _resource,
         _pointer
       ) do
    not is_number(instance) or
      if(exclusive?, do: instance < limit, else: instance <= limit)
  end

  defp evaluate_instruction(
         {:minimum, _keyword, limit, exclusive?},
         instance,
         _resource,
         _pointer
       ) do
    not is_number(instance) or
      if(exclusive?, do: instance > limit, else: instance >= limit)
  end

  defp evaluate_instruction({:count, keyword, limit}, instance, _resource, _pointer) do
    count_valid?(keyword, instance, limit)
  end

  defp evaluate_instruction({:pattern, pattern}, instance, _resource, _pointer) do
    not is_binary(instance) or pattern_matches?(pattern, instance)
  end

  defp evaluate_instruction({:required, required}, instance, _resource, _pointer) do
    not is_map(instance) or Enum.all?(required, &Map.has_key?(instance, &1))
  end

  defp evaluate_instruction(:unique_items, instance, _resource, _pointer) do
    not is_list(instance) or unique_json_values?(instance)
  end

  defp evaluate_instruction({:items, child}, instance, resource, pointer) do
    if is_list(instance) do
      child = resolve_child(child, resource, pointer)
      Enum.all?(instance, &evaluate_resolved_child(child, &1, resource))
    else
      true
    end
  end

  defp evaluate_instruction({:properties, properties}, instance, resource, pointer) do
    not is_map(instance) or
      present_properties_all?(instance, properties, fn _name, child, value ->
        child
        |> resolve_child(resource, pointer)
        |> evaluate_resolved_child(value, resource)
      end)
  end

  defp evaluate_instruction(
         {:properties_with_unevaluated, properties, unevaluated},
         instance,
         resource,
         pointer
       ) do
    if is_map(instance) do
      unevaluated = resolve_child(unevaluated, resource, pointer)

      Enum.all?(instance, fn {name, value} ->
        case Map.fetch(properties, name) do
          {:ok, child} ->
            child
            |> resolve_child(resource, pointer)
            |> evaluate_resolved_child(value, resource)

          :error ->
            evaluate_resolved_child(unevaluated, value, resource)
        end
      end)
    else
      true
    end
  end

  defp evaluate_instruction(
         {:contains, {:boolean, false}, minimum, _maximum},
         instance,
         _resource,
         _pointer
       ) do
    not is_list(instance) or minimum == 0
  end

  defp evaluate_instruction(
         {:contains, {:boolean, true}, minimum, :infinity},
         instance,
         _resource,
         _pointer
       ) do
    not is_list(instance) or list_has_at_least?(instance, minimum)
  end

  defp evaluate_instruction(
         {:contains, {:boolean, true}, minimum, maximum},
         instance,
         _resource,
         _pointer
       ) do
    if is_list(instance) do
      matches = length(instance)
      matches >= minimum and matches <= maximum
    else
      true
    end
  end

  defp evaluate_instruction(
         {:contains, child, minimum, maximum},
         instance,
         resource,
         pointer
       ) do
    if is_list(instance) do
      child = resolve_child(child, resource, pointer)
      contains_valid?(instance, child, resource, 0, minimum, maximum)
    else
      true
    end
  end

  defp evaluate_instruction(
         {:unevaluated_properties, child},
         instance,
         resource,
         pointer
       ) do
    if is_map(instance) do
      child = resolve_child(child, resource, pointer)

      Enum.all?(instance, fn {_name, value} ->
        evaluate_resolved_child(child, value, resource)
      end)
    else
      true
    end
  end

  defp present_properties_all?(instance, properties, validator) do
    if map_size(instance) < map_size(properties) do
      Enum.all?(instance, fn {name, value} ->
        case Map.fetch(properties, name) do
          {:ok, child} -> validator.(name, child, value)
          :error -> true
        end
      end)
    else
      Enum.all?(properties, fn {name, child} ->
        case Map.fetch(instance, name) do
          {:ok, value} -> validator.(name, child, value)
          :error -> true
        end
      end)
    end
  end

  defp resolve_child({:boolean, valid}, _resource, _pointer), do: {:boolean, valid}

  defp resolve_child(
         {:plan, relative},
         %Resource{evaluation_plans: evaluation_plans},
         pointer
       ) do
    pointer = pointer ++ relative
    %EvaluationPlan{validity: validity} = Map.fetch!(evaluation_plans, pointer)
    {:plan, validity, pointer}
  end

  defp evaluate_resolved_child({:boolean, valid}, _instance, _resource), do: valid

  defp evaluate_resolved_child({:plan, validity, pointer}, instance, resource),
    do: evaluate(validity, instance, resource, pointer)

  defp contains_valid?([], _child, _resource, matches, minimum, maximum) do
    matches >= minimum and (maximum == :infinity or matches <= maximum)
  end

  defp contains_valid?(
         [item | rest],
         child,
         resource,
         matches,
         minimum,
         maximum
       ) do
    matches = if evaluate_resolved_child(child, item, resource), do: matches + 1, else: matches

    cond do
      maximum != :infinity and matches > maximum ->
        false

      maximum == :infinity and matches >= minimum ->
        true

      true ->
        contains_valid?(rest, child, resource, matches, minimum, maximum)
    end
  end

  defp list_has_at_least?(_items, 0), do: true
  defp list_has_at_least?([], _minimum), do: false
  defp list_has_at_least?([_item | rest], minimum), do: list_has_at_least?(rest, minimum - 1)

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
end
