defmodule ExJsonSchema.Evaluator.Engine do
  @moduledoc false

  # Implements full keyword evaluation, including references, annotations,
  # dynamic scope, and unevaluated-location bookkeeping.

  alias ExJsonSchema.CompiledSchema
  alias ExJsonSchema.Compiler.Callbacks
  alias ExJsonSchema.Compiler.Dialect
  alias ExJsonSchema.Compiler.EvaluationPlan
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Pointer
  alias ExJsonSchema.Compiler.Reference
  alias ExJsonSchema.Compiler.Resource
  alias ExJsonSchema.Evaluator.Context
  alias ExJsonSchema.Evaluator.Dispatcher
  alias ExJsonSchema.Evaluator.Format
  alias ExJsonSchema.Evaluator.Number
  alias ExJsonSchema.Evaluator.PlanEngine
  alias ExJsonSchema.Evaluator.Result

  @metadata_keywords ~w[title description default deprecated readOnly writeOnly examples]
  @count_keywords ~w[maxLength minLength maxItems minItems maxProperties minProperties]

  @spec evaluate(ExJsonSchema.data(), ExJsonSchema.data(), Context.t()) :: Result.t()
  def evaluate(true, _instance, context), do: schema_result(true, context)

  def evaluate(false, _instance, context) do
    schema_result(false, context, error: "boolean schema is false")
  end

  def evaluate(
        schema,
        instance,
        %Context{
          output_format: :flag,
          track_evaluated?: false,
          keyword_plan: %EvaluationPlan{unevaluated: []},
          dialect: %Dialect{version: version}
        } = context
      )
      when is_map(schema) do
    %EvaluationPlan{identifiers: identifiers, ordinary: ordinary} =
      Dispatcher.phases(context, schema)

    initial_keywords =
      if version in [4, 6, 7] and "$ref" in identifiers do
        ["$ref"]
      else
        identifiers ++ ordinary
      end

    Enum.reduce_while(initial_keywords, %Result{valid: true}, fn keyword, result ->
      case evaluate_keyword(keyword, schema, instance, context) do
        nil -> {:cont, result}
        %Result{valid: true} = next -> {:cont, next}
        %Result{valid: false} = next -> {:halt, next}
      end
    end)
  end

  def evaluate(
        schema,
        instance,
        %Context{
          dialect: %Dialect{version: version},
          schema_location: schema_location,
          keyword_location: keyword_location,
          instance_location: instance_location
        } = context
      )
      when is_map(schema) do
    %EvaluationPlan{
      identifiers: identifiers,
      ordinary: ordinary,
      unevaluated: unevaluated
    } = Dispatcher.phases(context, schema)

    context =
      if unevaluated == [],
        do: context,
        else: %Context{context | track_evaluated?: true}

    initial_keywords =
      if version in [4, 6, 7] and "$ref" in identifiers do
        ["$ref"]
      else
        identifiers ++ ordinary
      end

    ordinary_children =
      initial_keywords
      |> Enum.map(&evaluate_keyword(&1, schema, instance, context))
      |> Enum.reject(&is_nil/1)

    ordinary_children =
      ordinary_children ++ unknown_keyword_annotations(schema, context)

    children =
      Enum.reduce(unevaluated, ordinary_children, fn keyword, children ->
        children ++ [evaluate_unevaluated(keyword, schema, instance, context, children)]
      end)

    children
    |> Result.parent(
      schema_location: schema_location,
      keyword_location: keyword_location,
      instance_location: instance_location,
      report_locations: report_locations?(context)
    )
    |> compact(context)
  end

  defp evaluate_keyword(keyword, schema, _instance, context)
       when keyword in @metadata_keywords do
    annotation(context, keyword, schema[keyword])
  end

  defp evaluate_keyword(
         "type",
         schema,
         instance,
         %Context{dialect: %Dialect{version: version}} = context
       ) do
    expected = schema["type"]
    valid = PlanEngine.type_valid?(expected, instance, version)
    assertion(context, "type", valid, fn -> "value does not match type #{inspect(expected)}" end)
  end

  defp evaluate_keyword("$ref", _schema, instance, context) do
    evaluate_reference("$ref", instance, context)
  end

  defp evaluate_keyword("$dynamicRef", _schema, instance, context) do
    evaluate_reference("$dynamicRef", instance, context)
  end

  defp evaluate_keyword("enum", schema, instance, context) do
    valid = Enum.any?(schema["enum"], &PlanEngine.json_equal?(&1, instance))
    assertion(context, "enum", valid, "value is not one of the enumerated values")
  end

  defp evaluate_keyword("const", schema, instance, context) do
    valid = PlanEngine.json_equal?(schema["const"], instance)
    assertion(context, "const", valid, "value does not equal the constant")
  end

  defp evaluate_keyword("format", schema, instance, %Context{compiled: compiled} = context) do
    format = schema["format"]

    if assert_formats?(context) do
      result =
        case Map.fetch(CompiledSchema.formats(compiled), format) do
          {:ok, validator} -> Callbacks.validate_format(validator, format, instance)
          :error -> Format.validate(format, instance)
        end

      case result do
        :ok ->
          context
          |> assertion("format", true, "")
          |> Map.merge(%{annotation: format, annotation?: true})

        :unknown ->
          context
          |> assertion("format", true, "")
          |> Map.merge(%{annotation: format, annotation?: true})

        {:error, reason} ->
          assertion(context, "format", false, "value does not satisfy #{format}: #{inspect(reason)}")
      end
    else
      annotation(context, "format", format)
    end
  end

  defp evaluate_keyword(
         keyword,
         schema,
         instance,
         %Context{dialect: %Dialect{version: version}} = context
       )
       when keyword in ["contentEncoding", "contentMediaType", "contentSchema"] do
    if version == :"2020-12" do
      cond do
        not is_binary(instance) ->
          nil

        keyword == "contentSchema" and not Map.has_key?(schema, "contentMediaType") ->
          nil

        true ->
          annotation(context, keyword, schema[keyword])
      end
    else
      evaluate_legacy_content(keyword, schema, instance, context)
    end
  end

  defp evaluate_keyword("multipleOf", schema, instance, context) do
    divisor = schema["multipleOf"]
    valid = not is_number(instance) or Number.multiple_of?(instance, divisor)

    assertion(context, "multipleOf", valid, fn ->
      "number is not a multiple of #{inspect(divisor)}"
    end)
  end

  defp evaluate_keyword(
         "maximum",
         schema,
         instance,
         %Context{dialect: %Dialect{version: version}} = context
       ) do
    limit = schema["maximum"]

    valid =
      not is_number(instance) or
        if version == 4 and schema["exclusiveMaximum"] == true do
          instance < limit
        else
          instance <= limit
        end

    assertion(context, "maximum", valid, fn -> "number exceeds maximum #{inspect(limit)}" end)
  end

  defp evaluate_keyword(
         "minimum",
         schema,
         instance,
         %Context{dialect: %Dialect{version: version}} = context
       ) do
    limit = schema["minimum"]

    valid =
      not is_number(instance) or
        if version == 4 and schema["exclusiveMinimum"] == true do
          instance > limit
        else
          instance >= limit
        end

    assertion(context, "minimum", valid, fn -> "number is below minimum #{inspect(limit)}" end)
  end

  defp evaluate_keyword(
         "exclusiveMaximum",
         schema,
         instance,
         %Context{dialect: %Dialect{version: version}} = context
       )
       when version != 4 do
    limit = schema["exclusiveMaximum"]
    valid = not is_number(instance) or instance < limit

    assertion(context, "exclusiveMaximum", valid, fn ->
      "number is not below #{inspect(limit)}"
    end)
  end

  defp evaluate_keyword(
         "exclusiveMinimum",
         schema,
         instance,
         %Context{dialect: %Dialect{version: version}} = context
       )
       when version != 4 do
    limit = schema["exclusiveMinimum"]
    valid = not is_number(instance) or instance > limit

    assertion(context, "exclusiveMinimum", valid, fn ->
      "number is not above #{inspect(limit)}"
    end)
  end

  defp evaluate_keyword(keyword, schema, instance, context) when keyword in @count_keywords do
    limit = schema[keyword]
    valid = PlanEngine.count_valid?(keyword, instance, limit)
    assertion(context, keyword, valid, fn -> "#{keyword} constraint failed" end)
  end

  defp evaluate_keyword("pattern", schema, instance, context) do
    valid = not is_binary(instance) or PlanEngine.pattern_matches?(schema["pattern"], instance)

    assertion(context, "pattern", valid, "string does not match pattern")
  end

  defp evaluate_keyword("uniqueItems", schema, instance, context) do
    valid =
      schema["uniqueItems"] != true or not is_list(instance) or
        PlanEngine.unique_json_values?(instance)

    assertion(context, "uniqueItems", valid, "array items are not unique")
  end

  defp evaluate_keyword("required", schema, instance, context) do
    missing =
      if is_map(instance) do
        Enum.reject(schema["required"], &Map.has_key?(instance, &1))
      else
        []
      end

    assertion(context, "required", missing == [], fn ->
      "required properties are missing: #{inspect(missing)}"
    end)
  end

  defp evaluate_keyword("prefixItems", schema, instance, context) do
    if is_list(instance) do
      schemata = schema["prefixItems"]

      children =
        schemata
        |> Enum.zip(instance)
        |> Enum.with_index()
        |> Enum.map(fn {{subschema, item}, index} ->
          evaluate_subschema(subschema, item, context, ["prefixItems", index], index)
        end)

      evaluated = index_set(0, min(length(schemata), length(instance)) - 1)

      applicator(context, "prefixItems", children, Enum.all?(children, &valid_result?/1), evaluated_items: evaluated)
    else
      applicator(context, "prefixItems", [], true)
    end
  end

  defp evaluate_keyword(
         "items",
         schema,
         instance,
         %Context{dialect: %Dialect{version: version}} = context
       ) do
    cond do
      not is_list(instance) ->
        applicator(context, "items", [], true)

      version == :"2020-12" ->
        start = length(Map.get(schema, "prefixItems", []))
        evaluate_uniform_items(schema["items"], instance, context, start)

      is_list(schema["items"]) ->
        children =
          schema["items"]
          |> Enum.zip(instance)
          |> Enum.with_index()
          |> Enum.map(fn {{subschema, item}, index} ->
            evaluate_subschema(subschema, item, context, ["items", index], index)
          end)

        evaluated = index_set(0, min(length(schema["items"]), length(instance)) - 1)

        applicator(context, "items", children, Enum.all?(children, &valid_result?/1), evaluated_items: evaluated)

      true ->
        evaluate_uniform_items(schema["items"], instance, context, 0)
    end
  end

  defp evaluate_keyword("additionalItems", schema, instance, context) do
    cond do
      not is_list(instance) or not is_list(schema["items"]) ->
        applicator(context, "additionalItems", [], true)

      true ->
        start = length(schema["items"])

        evaluate_uniform_items(
          schema["additionalItems"],
          instance,
          context,
          start,
          "additionalItems"
        )
    end
  end

  defp evaluate_keyword(
         "contains",
         schema,
         instance,
         %Context{dialect: %Dialect{version: version}} = context
       ) do
    if is_list(instance) do
      cond do
        validity_only_flag?(context) and version in [6, 7] ->
          subschema_context = at_subschema(context, ["contains"])

          valid =
            instance
            |> Enum.with_index()
            |> Enum.any?(fn {item, index} ->
              item_context = Context.at_instance_child(subschema_context, index)
              valid_result?(evaluate(schema["contains"], item, item_context))
            end)

          applicator(context, "contains", [], valid, error: if(valid, do: nil, else: "array contains no matching item"))

        validity_only_flag?(context) ->
          valid = contains_valid?(schema, instance, context)
          applicator(context, "contains", [], valid)

        true ->
          evaluate_contains(schema, instance, context)
      end
    else
      applicator(context, "contains", [], true)
    end
  end

  defp evaluate_keyword("properties", schema, instance, context) do
    if is_map(instance) do
      if validity_only_flag?(context) do
        valid =
          present_properties_all?(instance, schema["properties"], fn name, subschema, value ->
            subschema
            |> evaluate_subschema(value, context, ["properties", name], name)
            |> valid_result?()
          end)

        applicator(context, "properties", [], valid)
      else
        names = present_property_names(instance, schema["properties"])

        children =
          Enum.map(names, fn name ->
            evaluate_subschema(
              schema["properties"][name],
              instance[name],
              context,
              ["properties", name],
              name
            )
          end)

        applicator(context, "properties", children, Enum.all?(children, &valid_result?/1),
          evaluated_properties: MapSet.new(names)
        )
      end
    else
      applicator(context, "properties", [], true)
    end
  end

  defp evaluate_keyword("patternProperties", schema, instance, context) do
    if is_map(instance) do
      matches =
        for {pattern, subschema} <- schema["patternProperties"],
            {:ok, regex} = PlanEngine.compile_pattern(pattern),
            {name, value} <- instance,
            Regex.match?(regex, name),
            do: {pattern, subschema, name, value}

      children =
        Enum.map(matches, fn {pattern, subschema, name, value} ->
          evaluate_subschema(subschema, value, context, ["patternProperties", pattern], name)
        end)

      names = matches |> Enum.map(&elem(&1, 2)) |> MapSet.new()

      applicator(
        context,
        "patternProperties",
        children,
        Enum.all?(children, &valid_result?/1),
        evaluated_properties: names
      )
    else
      applicator(context, "patternProperties", [], true)
    end
  end

  defp evaluate_keyword("additionalProperties", schema, instance, context) do
    if is_map(instance) do
      known = Map.keys(Map.get(schema, "properties", %{})) |> MapSet.new()

      patterns =
        Map.get(schema, "patternProperties", %{})
        |> Map.keys()
        |> Enum.map(fn pattern ->
          {:ok, regex} = PlanEngine.compile_pattern(pattern)
          regex
        end)

      names =
        instance
        |> Map.keys()
        |> Enum.reject(fn name ->
          MapSet.member?(known, name) or Enum.any?(patterns, &Regex.match?(&1, name))
        end)

      subschema_context = at_subschema(context, ["additionalProperties"])

      children =
        Enum.map(names, fn name ->
          property_context = Context.at_instance_child(subschema_context, name)
          evaluate(schema["additionalProperties"], instance[name], property_context)
        end)

      applicator(
        context,
        "additionalProperties",
        children,
        Enum.all?(children, &valid_result?/1),
        evaluated_properties: MapSet.new(names)
      )
    else
      applicator(context, "additionalProperties", [], true)
    end
  end

  defp evaluate_keyword("propertyNames", schema, instance, context) do
    if is_map(instance) do
      children =
        Enum.map(Map.keys(instance), fn name ->
          evaluate_subschema(schema["propertyNames"], name, context, ["propertyNames"], :same)
        end)

      applicator(context, "propertyNames", children, Enum.all?(children, &valid_result?/1))
    else
      applicator(context, "propertyNames", [], true)
    end
  end

  defp evaluate_keyword("dependentRequired", schema, instance, context) do
    missing =
      if is_map(instance) do
        for {property, required} <- schema["dependentRequired"],
            Map.has_key?(instance, property),
            dependency <- required,
            not Map.has_key?(instance, dependency),
            do: {property, dependency}
      else
        []
      end

    assertion(
      context,
      "dependentRequired",
      missing == [],
      fn -> "dependent properties are missing: #{inspect(missing)}" end
    )
  end

  defp evaluate_keyword("dependencies", schema, instance, context) do
    if is_map(instance) do
      {property_dependencies, schema_dependencies} =
        schema["dependencies"]
        |> Enum.filter(fn {property, _dependency} -> Map.has_key?(instance, property) end)
        |> Enum.split_with(fn {_property, dependency} -> is_list(dependency) end)

      missing =
        for {property, dependencies} <- property_dependencies,
            dependency <- dependencies,
            not Map.has_key?(instance, dependency),
            do: {property, dependency}

      assertion =
        assertion(
          context,
          "dependencies",
          missing == [],
          fn -> "property dependencies are missing: #{inspect(missing)}" end
        )

      children =
        Enum.map(schema_dependencies, fn {property, subschema} ->
          evaluate_subschema(
            subschema,
            instance,
            context,
            ["dependencies", property],
            :same
          )
        end)

      applicator(
        context,
        "dependencies",
        [assertion | children],
        valid_result?(assertion) and Enum.all?(children, &valid_result?/1)
      )
    else
      applicator(context, "dependencies", [], true)
    end
  end

  defp evaluate_keyword("dependentSchemas", schema, instance, context) do
    if is_map(instance) do
      selected =
        Enum.filter(schema["dependentSchemas"], fn {property, _subschema} ->
          Map.has_key?(instance, property)
        end)

      children =
        Enum.map(selected, fn {property, subschema} ->
          evaluate_subschema(
            subschema,
            instance,
            context,
            ["dependentSchemas", property],
            :same
          )
        end)

      applicator(context, "dependentSchemas", children, Enum.all?(children, &valid_result?/1))
    else
      applicator(context, "dependentSchemas", [], true)
    end
  end

  defp evaluate_keyword(keyword, schema, instance, context)
       when keyword in ["allOf", "anyOf", "oneOf"] do
    if validity_only_flag?(context) do
      valid = combinator_valid?(keyword, schema[keyword], instance, context)
      applicator(context, keyword, [], valid)
    else
      children =
        schema[keyword]
        |> Enum.with_index()
        |> Enum.map(fn {subschema, index} ->
          evaluate_subschema(subschema, instance, context, [keyword, index], :same)
        end)

      valid_count = Enum.count(children, &valid_result?/1)

      valid =
        case keyword do
          "allOf" -> valid_count == length(children)
          "anyOf" -> valid_count > 0
          "oneOf" -> valid_count == 1
        end

      applicator(context, keyword, children, valid, error: fn -> "#{keyword} matched #{valid_count} branches" end)
    end
  end

  defp evaluate_keyword("not", schema, instance, context) do
    %Result{valid: child_valid} =
      child = evaluate_subschema(schema["not"], instance, context, ["not"], :same)

    %Context{
      schema_location: schema_location,
      keyword_location: keyword_location
    } = keyword_context(context, "not")

    %Context{instance_location: instance_location} = context

    Result.new(
      not child_valid,
      kind: :applicator,
      keyword: "not",
      schema_location: schema_location,
      keyword_location: keyword_location,
      instance_location: instance_location,
      children: [child],
      error: if(child_valid, do: "not subschema matched", else: nil),
      report_locations: report_locations?(context)
    )
    |> compact(context)
  end

  defp evaluate_keyword("if", schema, instance, context) do
    %Result{valid: condition_valid} =
      condition = evaluate_subschema(schema["if"], instance, context, ["if"], :same)

    {branch_keyword, branch} =
      cond do
        condition_valid and Map.has_key?(schema, "then") -> {"then", schema["then"]}
        not condition_valid and Map.has_key?(schema, "else") -> {"else", schema["else"]}
        true -> {nil, nil}
      end

    branch_result =
      if branch_keyword,
        do: evaluate_subschema(branch, instance, context, [branch_keyword], :same),
        else: nil

    children =
      if condition_valid,
        do: Enum.reject([condition, branch_result], &is_nil/1),
        else: Enum.reject([branch_result], &is_nil/1)

    valid = is_nil(branch_result) or valid_result?(branch_result)

    applicator(context, "if", children, valid,
      error: fn ->
        if(branch_keyword, do: "#{branch_keyword} branch failed", else: "conditional failed")
      end
    )
  end

  defp evaluate_keyword(keyword, _schema, _instance, _context)
       when keyword in [
              "$schema",
              "id",
              "$id",
              "$vocabulary",
              "$anchor",
              "$dynamicAnchor",
              "exclusiveMaximum",
              "exclusiveMinimum",
              "minContains",
              "maxContains",
              "then",
              "else"
            ],
       do: nil

  defp evaluate_keyword(_keyword, _schema, _instance, _context), do: nil

  defp contains_valid?(schema, instance, context) do
    minimum = Map.get(schema, "minContains", 1)
    maximum = Map.get(schema, "maxContains", :infinity)

    if minimum == 0 and maximum == :infinity do
      true
    else
      subschema_context = at_subschema(context, ["contains"])

      contains_valid?(
        instance,
        0,
        0,
        schema["contains"],
        subschema_context,
        minimum,
        maximum
      )
    end
  end

  defp contains_valid?([], _index, matches, _schema, _context, minimum, maximum) do
    matches >= minimum and (maximum == :infinity or matches <= maximum)
  end

  defp contains_valid?(
         [item | rest],
         index,
         matches,
         schema,
         context,
         minimum,
         maximum
       ) do
    item_context = Context.at_instance_child(context, index)

    matches =
      if valid_result?(evaluate(schema, item, item_context)),
        do: matches + 1,
        else: matches

    cond do
      maximum != :infinity and matches > maximum ->
        false

      maximum == :infinity and matches >= minimum ->
        true

      true ->
        contains_valid?(
          rest,
          index + 1,
          matches,
          schema,
          context,
          minimum,
          maximum
        )
    end
  end

  defp evaluate_contains(
         schema,
         instance,
         %Context{dialect: %Dialect{version: version}} = context
       ) do
    subschema_context = at_subschema(context, ["contains"])

    children =
      instance
      |> Enum.with_index()
      |> Enum.map(fn {item, index} ->
        item_context = Context.at_instance_child(subschema_context, index)
        evaluate(schema["contains"], item, item_context)
      end)

    matching =
      children
      |> Enum.with_index()
      |> Enum.filter(fn {result, _index} -> valid_result?(result) end)
      |> Enum.map(fn {_result, index} -> index end)

    minimum =
      if version == :"2020-12", do: Map.get(schema, "minContains", 1), else: 1

    maximum =
      if version == :"2020-12",
        do: Map.get(schema, "maxContains", :infinity),
        else: :infinity

    valid =
      length(matching) >= minimum and
        (maximum == :infinity or length(matching) <= maximum)

    applicator(context, "contains", children, valid,
      evaluated_items: MapSet.new(matching),
      error: fn -> "array contains #{length(matching)} matching items" end
    )
  end

  defp evaluate_unevaluated("unevaluatedProperties", schema, instance, context, siblings) do
    if is_map(instance) do
      evaluated =
        siblings
        |> Enum.filter(&valid_result?/1)
        |> Enum.reduce(MapSet.new(), fn %Result{evaluated_properties: properties}, evaluated ->
          MapSet.union(evaluated, properties)
        end)

      names = Map.keys(instance) |> Enum.reject(&MapSet.member?(evaluated, &1))
      subschema_context = at_subschema(context, ["unevaluatedProperties"])

      children =
        Enum.map(names, fn name ->
          property_context = Context.at_instance_child(subschema_context, name)
          evaluate(schema["unevaluatedProperties"], instance[name], property_context)
        end)

      applicator(
        context,
        "unevaluatedProperties",
        children,
        Enum.all?(children, &valid_result?/1),
        evaluated_properties: MapSet.new(names)
      )
    else
      applicator(context, "unevaluatedProperties", [], true)
    end
  end

  defp evaluate_unevaluated("unevaluatedItems", schema, instance, context, siblings) do
    if is_list(instance) do
      evaluated =
        siblings
        |> Enum.filter(&valid_result?/1)
        |> Enum.reduce(MapSet.new(), fn %Result{evaluated_items: items}, evaluated ->
          MapSet.union(evaluated, items)
        end)

      indexes =
        instance
        |> Enum.with_index()
        |> Enum.map(&elem(&1, 1))
        |> Enum.reject(&MapSet.member?(evaluated, &1))

      subschema_context = at_subschema(context, ["unevaluatedItems"])

      children =
        Enum.map(indexes, fn index ->
          item_context = Context.at_instance_child(subschema_context, index)
          evaluate(schema["unevaluatedItems"], Enum.fetch!(instance, index), item_context)
        end)

      applicator(context, "unevaluatedItems", children, Enum.all?(children, &valid_result?/1),
        evaluated_items: MapSet.new(indexes)
      )
    else
      applicator(context, "unevaluatedItems", [], true)
    end
  end

  defp unknown_keyword_annotations(_schema, %Context{output_format: :flag}), do: []

  defp unknown_keyword_annotations(
         schema,
         %Context{dialect: %Dialect{version: :"2020-12"}} = context
       ) do
    known_keywords = EvaluationPlan.known_keywords()

    schema
    |> Map.keys()
    |> Enum.reject(&Map.has_key?(known_keywords, &1))
    |> Enum.sort()
    |> Enum.map(fn keyword -> annotation(context, keyword, schema[keyword]) end)
  end

  defp unknown_keyword_annotations(_schema, _context), do: []

  defp assertion(
         %Context{output_format: output_format, instance_location: instance_location} = context,
         keyword,
         valid,
         message
       ) do
    if output_format == :flag do
      %Result{valid: valid, kind: :assertion}
    else
      %Context{
        schema_location: schema_location,
        keyword_location: keyword_location
      } = keyword_context(context, keyword)

      Result.new(valid,
        kind: :assertion,
        keyword: keyword,
        schema_location: schema_location,
        keyword_location: keyword_location,
        instance_location: instance_location,
        error: if(valid, do: nil, else: error_message(message)),
        report_locations: report_locations?(context)
      )
    end
  end

  defp annotation(
         %Context{output_format: output_format, instance_location: instance_location} = context,
         keyword,
         value
       ) do
    if output_format == :flag do
      %Result{valid: true, kind: :annotation}
    else
      %Context{
        schema_location: schema_location,
        keyword_location: keyword_location
      } = keyword_context(context, keyword)

      Result.new(true,
        kind: :annotation,
        keyword: keyword,
        schema_location: schema_location,
        keyword_location: keyword_location,
        instance_location: instance_location,
        annotation: value
      )
    end
  end

  defp applicator(
         %Context{output_format: output_format, instance_location: instance_location} = context,
         keyword,
         children,
         valid,
         options \\ []
       ) do
    cond do
      validity_only_flag?(context) ->
        %Result{valid: valid, kind: :applicator}

      output_format == :flag ->
        children
        |> Result.parent(
          kind: :applicator,
          valid: valid,
          instance_location: instance_location,
          evaluated_properties: Keyword.get(options, :evaluated_properties, MapSet.new()),
          evaluated_items: Keyword.get(options, :evaluated_items, MapSet.new()),
          report_locations: false
        )
        |> compact(context)

      true ->
        %Context{
          schema_location: schema_location,
          keyword_location: keyword_location
        } = keyword_context(context, keyword)

        children
        |> Result.parent(
          kind: :applicator,
          keyword: keyword,
          valid: valid,
          schema_location: schema_location,
          keyword_location: keyword_location,
          instance_location: instance_location,
          evaluated_properties: Keyword.get(options, :evaluated_properties, MapSet.new()),
          evaluated_items: Keyword.get(options, :evaluated_items, MapSet.new()),
          error:
            if(valid,
              do: nil,
              else: options |> Keyword.get(:error, "#{keyword} failed") |> error_message()
            ),
          report_locations: true
        )
        |> compact(context)
    end
  end

  defp evaluate_uniform_items(subschema, instance, context, start, keyword \\ "items") do
    subschema_context = at_subschema(context, [keyword])

    if validity_only_flag?(context) do
      selected = if start == 0, do: instance, else: Enum.drop(instance, start)
      valid = uniform_items_valid?(selected, start, subschema, subschema_context)

      applicator(context, keyword, [], valid)
    else
      selected = Enum.drop(instance, start)

      children =
        selected
        |> Enum.with_index(start)
        |> Enum.map(fn {item, index} ->
          item_context = Context.at_instance_child(subschema_context, index)
          evaluate(subschema, item, item_context)
        end)

      evaluated = index_set(start, start + length(selected) - 1)

      applicator(context, keyword, children, Enum.all?(children, &valid_result?/1), evaluated_items: evaluated)
    end
  end

  defp uniform_items_valid?([], _index, _subschema, _context), do: true

  defp uniform_items_valid?([item | rest], index, subschema, context) do
    item_context = Context.at_instance_child(context, index)

    if valid_result?(evaluate(subschema, item, item_context)) do
      uniform_items_valid?(rest, index + 1, subschema, context)
    else
      false
    end
  end

  defp evaluate_subschema(schema, instance, context, relative_schema_path, instance_segment) do
    context = at_subschema(context, relative_schema_path)

    context =
      if instance_segment == :same,
        do: context,
        else: Context.at_instance_child(context, instance_segment)

    evaluate(schema, instance, context)
  end

  defp at_subschema(
         %Context{
           schema_location: %Location{pointer: schema_pointer},
           resource_data: resource_data,
           compiled: compiled,
           resource: resource_uri
         } = context,
         relative_path
       ) do
    pointer = schema_pointer ++ relative_path

    %Resource{} =
      resource =
      resource_data ||
        Map.fetch!(CompiledSchema.resources(compiled), resource_uri)

    target =
      case Resource.fetch_location(resource, pointer) do
        {:ok, location} -> location
        :error -> %Location{resource: resource_uri, pointer: pointer}
      end

    Context.at_schema(context, target)
  end

  defp evaluate_reference(
         keyword,
         instance,
         %Context{
           compiled: compiled,
           resource: resource_uri,
           schema_location: %Location{pointer: schema_pointer},
           instance_location: %Location{pointer: instance_pointer},
           dynamic_scope: dynamic_scope,
           seen: seen
         } = context
       ) do
    %Resource{references: references} =
      Map.fetch!(CompiledSchema.resources(compiled), resource_uri)

    pointer = Pointer.encode(schema_pointer ++ [keyword])
    %Reference{} = reference = Map.fetch!(references, pointer)

    %Location{resource: target_resource, pointer: target_pointer} =
      target = reference_target(reference, context)

    cycle_key = {
      target_resource,
      target_pointer,
      instance_pointer,
      dynamic_scope
    }

    child =
      if MapSet.member?(seen, cycle_key) do
        schema_result(true, Context.at_schema(context, target))
      else
        target_context =
          context
          |> Context.push_dynamic_scope(resource_uri)
          |> Context.at_schema(target)

        %Context{seen: target_seen} = target_context
        target_context = %Context{target_context | seen: MapSet.put(target_seen, cycle_key)}

        target_schema = schema_at!(compiled, target)
        evaluate(target_schema, instance, target_context)
      end

    applicator(context, keyword, [child], valid_result?(child))
  end

  defp reference_target(
         %Reference{
           kind: :dynamic_ref,
           dynamic_anchor: anchor,
           target: %Location{resource: static_resource_uri} = static_target
         },
         %Context{compiled: compiled, dynamic_scope: dynamic_scope}
       )
       when is_binary(anchor) do
    resources = CompiledSchema.resources(compiled)

    %Resource{dynamic_anchors: static_dynamic_anchors} =
      Map.fetch!(resources, static_resource_uri)

    if Map.has_key?(static_dynamic_anchors, anchor) do
      Enum.find_value(dynamic_scope, static_target, fn resource_uri ->
        %Resource{dynamic_anchors: dynamic_anchors} =
          Map.fetch!(resources, resource_uri)

        Map.get(dynamic_anchors, anchor)
      end)
    else
      static_target
    end
  end

  defp reference_target(%Reference{target: target}, _context), do: target

  defp schema_at!(compiled, %Location{resource: resource_uri, pointer: pointer}) do
    %Resource{schema: schema} =
      Map.fetch!(CompiledSchema.resources(compiled), resource_uri)

    Enum.reduce(pointer, schema, &schema_child!/2)
  end

  defp schema_child!(segment, schema) when is_binary(segment), do: Map.fetch!(schema, segment)
  defp schema_child!(segment, schema) when is_integer(segment), do: Enum.fetch!(schema, segment)

  defp index_set(first, last) when last < first, do: MapSet.new()
  defp index_set(first, last), do: MapSet.new(first..last)

  defp present_properties_all?(instance, properties, validator) do
    if map_size(instance) < map_size(properties) do
      Enum.all?(instance, fn {name, value} ->
        case Map.fetch(properties, name) do
          {:ok, subschema} -> validator.(name, subschema, value)
          :error -> true
        end
      end)
    else
      Enum.all?(properties, fn {name, subschema} ->
        case Map.fetch(instance, name) do
          {:ok, value} -> validator.(name, subschema, value)
          :error -> true
        end
      end)
    end
  end

  defp present_property_names(instance, properties) do
    if map_size(instance) < map_size(properties) do
      for {name, _value} <- instance, Map.has_key?(properties, name), do: name
    else
      for {name, _subschema} <- properties, Map.has_key?(instance, name), do: name
    end
  end

  defp combinator_valid?("allOf", schemata, instance, context),
    do: all_of_valid?(schemata, instance, context, 0)

  defp combinator_valid?("anyOf", schemata, instance, context),
    do: any_of_valid?(schemata, instance, context, 0)

  defp combinator_valid?("oneOf", schemata, instance, context),
    do: one_of_valid?(schemata, instance, context, 0, 0)

  defp all_of_valid?([], _instance, _context, _index), do: true

  defp all_of_valid?([schema | rest], instance, context, index) do
    valid_result?(evaluate_subschema(schema, instance, context, ["allOf", index], :same)) and
      all_of_valid?(rest, instance, context, index + 1)
  end

  defp any_of_valid?([], _instance, _context, _index), do: false

  defp any_of_valid?([schema | rest], instance, context, index) do
    valid_result?(evaluate_subschema(schema, instance, context, ["anyOf", index], :same)) or
      any_of_valid?(rest, instance, context, index + 1)
  end

  defp one_of_valid?([], _instance, _context, _index, valid_count), do: valid_count == 1

  defp one_of_valid?([schema | rest], instance, context, index, valid_count) do
    valid_count =
      if valid_result?(evaluate_subschema(schema, instance, context, ["oneOf", index], :same)),
        do: valid_count + 1,
        else: valid_count

    valid_count <= 1 and
      one_of_valid?(rest, instance, context, index + 1, valid_count)
  end

  defp schema_result(
         valid,
         %Context{
           output_format: output_format,
           schema_location: schema_location,
           keyword_location: keyword_location,
           instance_location: instance_location
         } = context,
         options \\ []
       ) do
    if output_format == :flag do
      %Result{valid: valid}
    else
      Result.new(valid,
        schema_location: schema_location,
        keyword_location: keyword_location,
        instance_location: instance_location,
        error: Keyword.get(options, :error),
        report_locations: report_locations?(context)
      )
    end
  end

  defp compact(%Result{} = result, %Context{output_format: :flag}),
    do: %Result{result | children: []}

  defp compact(%Result{} = result, _context), do: result

  defp report_locations?(%Context{output_format: output_format}), do: output_format != :flag

  defp validity_only_flag?(%Context{
         output_format: :flag,
         track_evaluated?: false,
         keyword_plan: %EvaluationPlan{unevaluated: []}
       }),
       do: true

  defp validity_only_flag?(_context), do: false

  defp error_message(message) when is_function(message, 0), do: message.()
  defp error_message(message), do: message

  defp keyword_context(%Context{output_format: :flag} = context, _keyword), do: context
  defp keyword_context(context, keyword), do: Context.at_keyword(context, keyword)

  defp assert_formats?(%Context{
         assert_formats?: assert_formats?,
         vocabularies: vocabularies,
         dialect: %Dialect{assert_formats?: assert_formats_by_default?}
       }) do
    assertion_vocabulary =
      "https://json-schema.org/draft/2020-12/vocab/format-assertion"

    case assert_formats? do
      true ->
        true

      false ->
        MapSet.member?(vocabularies, assertion_vocabulary)

      :default ->
        assert_formats_by_default? or MapSet.member?(vocabularies, assertion_vocabulary)
    end
  end

  defp evaluate_legacy_content("contentSchema", _schema, _instance, context) do
    annotation(context, "contentSchema", nil)
  end

  defp evaluate_legacy_content("contentMediaType", schema, instance, context)
       when is_binary(instance) do
    if Map.has_key?(schema, "contentEncoding") do
      nil
    else
      validate_media_type(schema["contentMediaType"], instance, context)
    end
  end

  defp evaluate_legacy_content("contentEncoding", schema, instance, context)
       when is_binary(instance) do
    {valid_encoding?, decoded} =
      case schema["contentEncoding"] do
        "base64" ->
          case Base.decode64(instance) do
            {:ok, decoded} -> {true, decoded}
            :error -> {false, instance}
          end

        _encoding ->
          {true, instance}
      end

    encoding_result =
      assertion(
        context,
        "contentEncoding",
        valid_encoding?,
        "value does not satisfy content encoding #{schema["contentEncoding"]}"
      )

    media_result =
      if valid_encoding? and Map.has_key?(schema, "contentMediaType"),
        do: validate_media_type(schema["contentMediaType"], decoded, context),
        else: nil

    context
    |> applicator(
      "contentEncoding",
      Enum.reject([encoding_result, media_result], &is_nil/1),
      valid_encoding? and (is_nil(media_result) or valid_result?(media_result))
    )
    |> with_annotation(schema["contentEncoding"])
  end

  defp evaluate_legacy_content(keyword, _schema, _instance, context) do
    assertion(context, keyword, true, "")
  end

  defp validate_media_type(
         "application/json",
         encoded,
         %Context{compiled: compiled} = context
       ) do
    valid =
      case Callbacks.decode_content(CompiledSchema.content_decoder(compiled), encoded) do
        {:ok, _decoded} -> true
        {:error, _reason} -> false
      end

    context
    |> assertion(
      "contentMediaType",
      valid,
      "decoded content is not valid application/json"
    )
    |> with_annotation("application/json")
  end

  defp validate_media_type(media_type, _encoded, context) do
    context
    |> assertion("contentMediaType", true, "")
    |> with_annotation(media_type)
  end

  defp with_annotation(%Result{} = result, annotation),
    do: %Result{result | annotation: annotation, annotation?: true}

  defp valid_result?(%Result{valid: valid}), do: valid
end
