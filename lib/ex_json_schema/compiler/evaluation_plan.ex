defmodule ExJsonSchema.Compiler.EvaluationPlan do
  @moduledoc false

  # Precomputes keyword order, bookkeeping needs, and fast-path validation
  # instructions for a schema location.

  alias ExJsonSchema.Compiler.Dialect
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Registry
  alias ExJsonSchema.Compiler.Vocabulary

  @identifiers ~w[$schema id $id $vocabulary $anchor $dynamicAnchor $ref $dynamicRef]
  @identifier_positions @identifiers |> Enum.with_index() |> Map.new()
  @identifier_set MapSet.new(@identifiers)

  @unevaluated ~w[unevaluatedProperties unevaluatedItems]
  @unevaluated_positions @unevaluated |> Enum.with_index() |> Map.new()
  @unevaluated_set MapSet.new(@unevaluated)

  @count_keywords ~w[maxLength minLength maxItems minItems maxProperties minProperties]
  @combinator_keywords ~w[allOf anyOf oneOf]

  @annotation_keywords ~w[
    title description default deprecated readOnly writeOnly examples
    format contentEncoding contentMediaType contentSchema
  ]
  @known_keywords Registry.vocabularies()
                  |> Map.values()
                  |> Enum.reduce(
                    MapSet.new(),
                    fn %Vocabulary{keywords: keywords}, known ->
                      MapSet.union(known, keywords)
                    end
                  )
                  |> MapSet.union(@identifier_set)
                  |> Map.new(&{&1, true})

  @type t :: %__MODULE__{
          identifiers: [String.t()],
          ordinary: [String.t()],
          unevaluated: [String.t()],
          annotations?: boolean(),
          validity: validity()
        }

  @type child :: {:boolean, boolean()} | {:plan, [Location.pointer_segment()]}
  @type instruction ::
          {:type, String.t() | [String.t()], Dialect.version()}
          | {:const, ExJsonSchema.data()}
          | {:enum, [ExJsonSchema.data()]}
          | {:multiple_of, number()}
          | {:maximum, String.t(), number(), boolean()}
          | {:minimum, String.t(), number(), boolean()}
          | {:count, String.t(), non_neg_integer()}
          | {:pattern, String.t()}
          | {:required, [String.t()]}
          | :unique_items
          | {:items, child()}
          | {:properties, %{String.t() => child()}}
          | {:properties_with_unevaluated, %{String.t() => child()}, child()}
          | {:contains, child(), non_neg_integer(), non_neg_integer() | :infinity}
          | {:all_of, [child()]}
          | {:any_of, [child()]}
          | {:one_of, [child()]}
          | {:unevaluated_properties, child()}
  @type validity :: {:all, [instruction()]} | {:boolean, boolean()} | :fallback

  defstruct identifiers: [],
            ordinary: [],
            unevaluated: [],
            annotations?: false,
            validity: :fallback

  @spec new(boolean(), Dialect.t(), MapSet.t(String.t())) :: t()
  def new(schema, _dialect, _vocabularies) when is_boolean(schema) do
    %__MODULE__{validity: {:boolean, schema}}
  end

  @spec new(map(), Dialect.t(), MapSet.t(String.t())) :: t()
  def new(schema, %Dialect{keyword_order: keyword_order} = dialect, vocabularies)
      when is_map(schema) do
    active_keywords = active_keywords(vocabularies)

    {identifiers, ordinary, unevaluated} =
      Enum.reduce(Map.keys(schema), {[], [], []}, fn keyword, {identifiers, ordinary, unevaluated} ->
        cond do
          not MapSet.member?(active_keywords, keyword) ->
            {identifiers, ordinary, unevaluated}

          MapSet.member?(@identifier_set, keyword) ->
            {[keyword | identifiers], ordinary, unevaluated}

          MapSet.member?(@unevaluated_set, keyword) ->
            {identifiers, ordinary, [keyword | unevaluated]}

          true ->
            {identifiers, [keyword | ordinary], unevaluated}
        end
      end)

    identifiers = sort(identifiers, @identifier_positions)
    ordinary = sort(ordinary, keyword_order)
    unevaluated = sort(unevaluated, @unevaluated_positions)

    %__MODULE__{
      identifiers: identifiers,
      ordinary: ordinary,
      unevaluated: unevaluated,
      annotations?: annotations?(schema, dialect, vocabularies, ordinary),
      validity: compile_validity_plan(schema, dialect, vocabularies, ordinary, unevaluated)
    }
  end

  @spec active_keywords(MapSet.t(String.t())) :: MapSet.t(String.t())
  def active_keywords(vocabularies) do
    Enum.reduce(vocabularies, MapSet.new(), fn vocabulary_id, keywords ->
      case Registry.vocabulary(vocabulary_id) do
        {:ok, %Vocabulary{keywords: vocabulary_keywords}} ->
          MapSet.union(keywords, vocabulary_keywords)

        :error ->
          keywords
      end
    end)
  end

  @spec known_keywords() :: %{String.t() => true}
  def known_keywords, do: @known_keywords

  defp sort([], _positions), do: []
  defp sort([keyword], _positions), do: [keyword]

  defp sort(keywords, positions) when is_map(positions) do
    Enum.sort_by(keywords, &{Map.get(positions, &1, 1_000_000), &1})
  end

  defp sort(keywords, order) when is_list(order) do
    positions = order |> Enum.with_index() |> Map.new()
    sort(keywords, positions)
  end

  defp compile_validity(schema, dialect, vocabularies, ordinary) do
    if Enum.any?(["$ref", "$dynamicRef"], &Map.has_key?(schema, &1)) do
      :fallback
    else
      ordinary
      |> Enum.reduce_while({:ok, []}, fn keyword, {:ok, instructions} ->
        case compile_instruction(keyword, schema, dialect, vocabularies) do
          {:ok, nil} -> {:cont, {:ok, instructions}}
          {:ok, instruction} -> {:cont, {:ok, [instruction | instructions]}}
          :fallback -> {:halt, :fallback}
        end
      end)
      |> case do
        {:ok, instructions} ->
          instructions =
            instructions
            |> Enum.reverse()
            |> merge_unevaluated_properties()
            |> simplify_instructions()

          {:all, instructions}

        :fallback ->
          :fallback
      end
    end
  end

  defp compile_instruction("type", schema, %Dialect{version: version}, _vocabularies),
    do: {:ok, {:type, schema["type"], version}}

  defp compile_instruction("const", schema, _dialect, _vocabularies),
    do: {:ok, {:const, schema["const"]}}

  defp compile_instruction("enum", schema, _dialect, _vocabularies),
    do: {:ok, {:enum, schema["enum"]}}

  defp compile_instruction("multipleOf", schema, _dialect, _vocabularies),
    do: {:ok, {:multiple_of, schema["multipleOf"]}}

  defp compile_instruction("maximum", schema, %Dialect{version: version}, _vocabularies) do
    exclusive? = version == 4 and schema["exclusiveMaximum"] == true
    {:ok, {:maximum, "maximum", schema["maximum"], exclusive?}}
  end

  defp compile_instruction("minimum", schema, %Dialect{version: version}, _vocabularies) do
    exclusive? = version == 4 and schema["exclusiveMinimum"] == true
    {:ok, {:minimum, "minimum", schema["minimum"], exclusive?}}
  end

  defp compile_instruction("exclusiveMaximum", _schema, %Dialect{version: 4}, _vocabularies),
    do: {:ok, nil}

  defp compile_instruction("exclusiveMaximum", schema, _dialect, _vocabularies),
    do: {:ok, {:maximum, "exclusiveMaximum", schema["exclusiveMaximum"], true}}

  defp compile_instruction("exclusiveMinimum", _schema, %Dialect{version: 4}, _vocabularies),
    do: {:ok, nil}

  defp compile_instruction("exclusiveMinimum", schema, _dialect, _vocabularies),
    do: {:ok, {:minimum, "exclusiveMinimum", schema["exclusiveMinimum"], true}}

  defp compile_instruction(keyword, schema, _dialect, _vocabularies)
       when keyword in @count_keywords,
       do: {:ok, {:count, keyword, schema[keyword]}}

  defp compile_instruction("pattern", schema, _dialect, _vocabularies),
    do: {:ok, {:pattern, schema["pattern"]}}

  defp compile_instruction("required", %{"required" => []}, _dialect, _vocabularies),
    do: {:ok, nil}

  defp compile_instruction("required", schema, _dialect, _vocabularies),
    do: {:ok, {:required, schema["required"]}}

  defp compile_instruction("uniqueItems", %{"uniqueItems" => true}, _dialect, _vocabularies),
    do: {:ok, :unique_items}

  defp compile_instruction("uniqueItems", _schema, _dialect, _vocabularies),
    do: {:ok, nil}

  defp compile_instruction("items", schema, dialect, vocabularies) do
    case schema["items"] do
      child when is_map(child) or is_boolean(child) ->
        child_instruction(child, ["items"], dialect, vocabularies)
        |> map_instruction(&{:items, &1})

      _other ->
        :fallback
    end
  end

  defp compile_instruction(
         "properties",
         %{"properties" => properties},
         dialect,
         vocabularies
       )
       when is_map(properties) do
    properties
    |> Enum.reduce_while({:ok, %{}, %{}}, fn {name, child}, {:ok, properties, support_cache} ->
      {support, support_cache} =
        child_support(child, dialect, vocabularies, support_cache)

      case support do
        {:boolean, valid} ->
          child = {:boolean, valid}
          {:cont, {:ok, Map.put(properties, name, child), support_cache}}

        :always_valid ->
          child = {:boolean, true}
          {:cont, {:ok, Map.put(properties, name, child), support_cache}}

        :plan ->
          child = {:plan, ["properties", name]}
          {:cont, {:ok, Map.put(properties, name, child), support_cache}}

        :fallback ->
          {:halt, :fallback}
      end
    end)
    |> case do
      {:ok, properties, _support_cache} -> {:ok, {:properties, properties}}
      :fallback -> :fallback
    end
  end

  defp compile_instruction("properties", _schema, _dialect, _vocabularies),
    do: :fallback

  defp compile_instruction(
         "contains",
         schema,
         %Dialect{version: version} = dialect,
         vocabularies
       ) do
    minimum = if version == :"2020-12", do: Map.get(schema, "minContains", 1), else: 1

    maximum =
      if version == :"2020-12",
        do: Map.get(schema, "maxContains", :infinity),
        else: :infinity

    child_instruction(schema["contains"], ["contains"], dialect, vocabularies)
    |> map_instruction(&{:contains, &1, minimum, maximum})
  end

  defp compile_instruction(keyword, schema, dialect, vocabularies)
       when keyword in @combinator_keywords do
    case schema[keyword] do
      children when is_list(children) ->
        children
        |> Enum.with_index()
        |> Enum.reduce_while(
          {:ok, [], %{}},
          fn {child, index}, {:ok, instructions, support_cache} ->
            {support, support_cache} =
              child_support(child, dialect, vocabularies, support_cache)

            case support do
              {:boolean, valid} ->
                {:cont, {:ok, [{:boolean, valid} | instructions], support_cache}}

              :always_valid ->
                {:cont, {:ok, [{:boolean, true} | instructions], support_cache}}

              :plan ->
                {:cont, {:ok, [{:plan, [keyword, index]} | instructions], support_cache}}

              :fallback ->
                {:halt, :fallback}
            end
          end
        )
        |> case do
          {:ok, instructions, _support_cache} ->
            {:ok, {combinator_instruction(keyword), Enum.reverse(instructions)}}

          :fallback ->
            :fallback
        end

      _invalid_children ->
        :fallback
    end
  end

  defp compile_instruction("unevaluatedProperties", schema, dialect, vocabularies) do
    case schema["unevaluatedProperties"] do
      true ->
        {:ok, nil}

      child ->
        child_instruction(child, ["unevaluatedProperties"], dialect, vocabularies)
        |> map_instruction(&{:unevaluated_properties, &1})
    end
  end

  defp compile_instruction(keyword, _schema, _dialect, _vocabularies)
       when keyword in [
              "$defs",
              "$comment",
              "definitions",
              "title",
              "description",
              "default",
              "deprecated",
              "readOnly",
              "writeOnly",
              "examples",
              "minContains",
              "maxContains"
            ],
       do: {:ok, nil}

  defp compile_instruction(_keyword, _schema, _dialect, _vocabularies), do: :fallback

  defp compile_validity_plan(schema, dialect, vocabularies, ordinary, []),
    do: compile_validity(schema, dialect, vocabularies, ordinary)

  defp compile_validity_plan(
         schema,
         dialect,
         vocabularies,
         ordinary,
         ["unevaluatedProperties"] = unevaluated
       ) do
    if Enum.any?(ordinary, &(&1 in @combinator_keywords)) do
      :fallback
    else
      compile_validity(schema, dialect, vocabularies, ordinary ++ unevaluated)
    end
  end

  defp compile_validity_plan(_schema, _dialect, _vocabularies, _ordinary, _unevaluated),
    do: :fallback

  defp merge_unevaluated_properties([
         {:properties, properties},
         {:unevaluated_properties, child} | rest
       ]) do
    [{:properties_with_unevaluated, properties, child} | rest]
  end

  defp merge_unevaluated_properties([instruction | rest]),
    do: [instruction | merge_unevaluated_properties(rest)]

  defp merge_unevaluated_properties([]), do: []

  defp simplify_instructions(instructions) do
    Enum.flat_map(instructions, fn
      {:items, {:boolean, true}} ->
        []

      {:properties, properties} ->
        properties = drop_always_valid_properties(properties)
        if map_size(properties) == 0, do: [], else: [{:properties, properties}]

      instruction ->
        [instruction]
    end)
  end

  defp drop_always_valid_properties(properties) do
    Map.reject(properties, fn {_name, child} -> child == {:boolean, true} end)
  end

  defp annotations?(
         schema,
         %Dialect{version: version} = dialect,
         vocabularies,
         ordinary
       ) do
    Enum.any?(ordinary, &(&1 in @annotation_keywords)) or
      (version == :"2020-12" and has_unknown_keyword?(schema)) or
      child_annotations?(schema, dialect, vocabularies, ordinary)
  end

  defp child_annotations?(schema, dialect, vocabularies, ordinary) do
    Enum.any?(ordinary, fn
      keyword when keyword in ["items", "contains", "unevaluatedProperties"] ->
        subschema_annotations?(schema[keyword], dialect, vocabularies)

      "properties" ->
        case schema["properties"] do
          properties when is_map(properties) ->
            properties
            |> Map.values()
            |> subschemata_annotations?(dialect, vocabularies)

          _invalid_properties ->
            false
        end

      keyword when keyword in @combinator_keywords ->
        case schema[keyword] do
          children when is_list(children) ->
            subschemata_annotations?(children, dialect, vocabularies)

          _invalid_children ->
            false
        end

      _keyword ->
        false
    end)
  end

  defp subschema_annotations?(child, dialect, vocabularies) when is_map(child) do
    resource_boundary?(child, dialect) or
      match?(%__MODULE__{annotations?: true}, new(child, dialect, vocabularies))
  end

  defp subschema_annotations?(_child, _dialect, _vocabularies), do: false

  defp subschemata_annotations?(children, dialect, vocabularies) do
    children
    |> Enum.reduce_while({false, %{}}, fn child, {false, cache} ->
      case Map.fetch(cache, child) do
        {:ok, true} ->
          {:halt, {true, cache}}

        {:ok, false} ->
          {:cont, {false, cache}}

        :error ->
          annotations? = subschema_annotations?(child, dialect, vocabularies)
          cache = Map.put(cache, child, annotations?)

          if annotations?,
            do: {:halt, {true, cache}},
            else: {:cont, {false, cache}}
      end
    end)
    |> elem(0)
  end

  defp has_unknown_keyword?(schema) do
    Enum.any?(Map.keys(schema), &(not Map.has_key?(@known_keywords, &1)))
  end

  defp child_instruction(child, _relative_path, _dialect, _vocabularies) when is_boolean(child),
    do: {:ok, {:boolean, child}}

  defp child_instruction(child, relative_path, dialect, vocabularies) when is_map(child) do
    if resource_boundary?(child, dialect) do
      :fallback
    else
      case new(child, dialect, vocabularies) do
        %__MODULE__{validity: {:all, []}} -> {:ok, {:boolean, true}}
        %__MODULE__{validity: :fallback} -> :fallback
        %__MODULE__{} -> {:ok, {:plan, relative_path}}
      end
    end
  end

  defp child_instruction(_child, _relative_path, _dialect, _vocabularies), do: :fallback

  defp child_support(child, _dialect, _vocabularies, cache) when is_boolean(child),
    do: {{:boolean, child}, cache}

  defp child_support(child, dialect, vocabularies, cache) when is_map(child) do
    case Map.fetch(cache, child) do
      {:ok, support} ->
        {support, cache}

      :error ->
        support =
          if resource_boundary?(child, dialect) do
            :fallback
          else
            case new(child, dialect, vocabularies) do
              %__MODULE__{validity: {:all, []}} -> :always_valid
              %__MODULE__{validity: :fallback} -> :fallback
              %__MODULE__{} -> :plan
            end
          end

        {support, Map.put(cache, child, support)}
    end
  end

  defp child_support(_child, _dialect, _vocabularies, cache), do: {:fallback, cache}

  defp resource_boundary?(schema, %Dialect{version: version}) do
    identifier = if version == 4, do: "id", else: "$id"
    Map.has_key?(schema, "$schema") or Map.has_key?(schema, identifier)
  end

  defp map_instruction({:ok, value}, fun), do: {:ok, fun.(value)}
  defp map_instruction(:fallback, _fun), do: :fallback

  defp combinator_instruction("allOf"), do: :all_of
  defp combinator_instruction("anyOf"), do: :any_of
  defp combinator_instruction("oneOf"), do: :one_of
end
