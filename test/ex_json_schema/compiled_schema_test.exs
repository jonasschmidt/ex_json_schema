defmodule ExJsonSchema.CompiledSchemaTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.CompiledSchema
  alias ExJsonSchema.Compiler.EvaluationPlan
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Resource

  defmodule TupleCallbacks do
    def validate_even(value) when is_binary(value) do
      if rem(String.length(value), 2) == 0, do: :ok, else: {:error, :odd_length}
    end

    def validate_even(_value), do: {:error, :not_a_string}
    def decode_json(encoded), do: Jason.decode(encoded)

    def resolve("https://example.com/even-string"),
      do: {:ok, %{"format" => "even-string"}}
  end

  defmodule EmbeddedCompiledSchema do
    @compiled ExJsonSchema.compile!(
                %{
                  "$schema" => "https://json-schema.org/draft/2020-12/schema",
                  "type" => "array",
                  "items" => %{"type" => "integer"}
                },
                validate_schema: false
              )

    def compiled, do: @compiled

    @optimized ExJsonSchema.compile!(
                 %{
                   "$schema" => "https://json-schema.org/draft/2020-12/schema",
                   "properties" => %{
                     "code" => %{"type" => "string", "pattern" => "^[A-Z]+$"},
                     "values" => %{"type" => "array", "uniqueItems" => true}
                   },
                   "unevaluatedProperties" => false
                 },
                 validate_schema: false
               )

    def optimized, do: @optimized

    @resolver {ExJsonSchema.CompiledSchemaTest.TupleCallbacks, :resolve}
    @formats %{
      "even-string" => {ExJsonSchema.CompiledSchemaTest.TupleCallbacks, :validate_even}
    }
    @content_decoder {ExJsonSchema.CompiledSchemaTest.TupleCallbacks, :decode_json}

    @with_callbacks ExJsonSchema.compile!(
                      %{"$ref" => "https://example.com/even-string"},
                      resolver: @resolver,
                      formats: @formats,
                      content_decoder: @content_decoder,
                      validate_schema: false
                    )

    def with_callbacks, do: @with_callbacks
  end

  test "the compiled schema type is opaque" do
    assert {:ok, types} = Code.Typespec.fetch_types(ExJsonSchema.CompiledSchema)
    assert {:opaque, {:t, _, _}} = List.keyfind(types, :opaque, 0)
  end

  test "records whether the resource graph needs evaluated-location tracking" do
    plain =
      ExJsonSchema.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "properties" => %{"value" => true}
        },
        validate_schema: false
      )

    tracked =
      ExJsonSchema.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "$defs" => %{
            "tracked" => %{"unevaluatedProperties" => false}
          }
        },
        validate_schema: false
      )

    refute ExJsonSchema.CompiledSchema.track_evaluated?(plain)
    assert ExJsonSchema.CompiledSchema.track_evaluated?(tracked)
  end

  test "records whether successful basic output can contain annotations" do
    plain =
      ExJsonSchema.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "type" => "integer"
        },
        validate_schema: false
      )

    annotated =
      ExJsonSchema.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "$defs" => %{"value" => %{"title" => "Value"}}
        },
        validate_schema: false
      )

    refute ExJsonSchema.CompiledSchema.annotations?(plain)
    assert ExJsonSchema.CompiledSchema.annotations?(annotated)
  end

  test "compiled schemas are release-safe module attributes and serializable data" do
    for compiled <- [
          EmbeddedCompiledSchema.compiled(),
          EmbeddedCompiledSchema.optimized(),
          EmbeddedCompiledSchema.with_callbacks()
        ] do
      assert release_safe_term?(compiled)

      restored = compiled |> :erlang.term_to_binary() |> :erlang.binary_to_term()
      assert restored == compiled
    end

    assert ExJsonSchema.valid?([1, 2, 3], EmbeddedCompiledSchema.compiled())
    refute ExJsonSchema.valid?([1, "2", 3], EmbeddedCompiledSchema.compiled())

    assert ExJsonSchema.valid?(%{"values" => [1, 2, 3]}, EmbeddedCompiledSchema.optimized())
    refute ExJsonSchema.valid?(%{"values" => [1, 1]}, EmbeddedCompiledSchema.optimized())
    assert ExJsonSchema.valid?(%{"code" => "ABC"}, EmbeddedCompiledSchema.optimized())
    refute ExJsonSchema.valid?(%{"code" => "abc"}, EmbeddedCompiledSchema.optimized())
    refute ExJsonSchema.valid?(%{"extra" => true}, EmbeddedCompiledSchema.optimized())

    assert ExJsonSchema.valid?("12", EmbeddedCompiledSchema.with_callbacks())
    refute ExJsonSchema.valid?("1", EmbeddedCompiledSchema.with_callbacks())
  end

  test "compiles common assertions into the fast validity plan" do
    compiled =
      ExJsonSchema.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "enum" => [1, 2, 3],
          "minimum" => 1,
          "maximum" => 3,
          "multipleOf" => 1
        },
        validate_schema: false
      )

    assert %EvaluationPlan{validity: {:all, instructions}} =
             evaluation_plan(compiled, [])

    assert Enum.any?(instructions, &match?({:enum, _values}, &1))
    assert Enum.any?(instructions, &match?({:minimum, _, _, _}, &1))
    assert Enum.any?(instructions, &match?({:maximum, _, _, _}, &1))
    assert Enum.any?(instructions, &match?({:multiple_of, _divisor}, &1))
  end

  test "tracks annotations and unevaluated work per schema location" do
    compiled =
      ExJsonSchema.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "type" => "integer",
          "$defs" => %{
            "annotated" => %{"title" => "Value"},
            "tracked" => %{"unevaluatedProperties" => false}
          }
        },
        validate_schema: false
      )

    assert %EvaluationPlan{annotations?: false, unevaluated: []} =
             evaluation_plan(compiled, [])

    assert %EvaluationPlan{annotations?: true} =
             evaluation_plan(compiled, ["$defs", "annotated"])

    assert %EvaluationPlan{unevaluated: ["unevaluatedProperties"]} =
             evaluation_plan(compiled, ["$defs", "tracked"])
  end

  test "removes trivial applicators from fast validity plans" do
    compiled =
      ExJsonSchema.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "items" => true,
          "properties" => %{"anything" => true},
          "required" => [],
          "unevaluatedProperties" => true
        },
        validate_schema: false
      )

    assert %EvaluationPlan{validity: {:all, []}} = evaluation_plan(compiled, [])
  end

  test "compiler graph modules are hidden from public documentation" do
    internal_modules = [
      ExJsonSchema.Compiler.Dialect,
      ExJsonSchema.Compiler.EvaluationPlan,
      ExJsonSchema.Compiler.Location,
      ExJsonSchema.Compiler.Resource,
      ExJsonSchema.Compiler.Vocabulary,
      ExJsonSchema.Evaluator.BasicEngine,
      ExJsonSchema.Evaluator.FlagEngine
    ]

    for module <- internal_modules do
      assert {:docs_v1, _, :elixir, _, :hidden, _, _} = Code.fetch_docs(module)
    end
  end

  defp release_safe_term?(term)
       when is_atom(term) or is_binary(term) or is_number(term),
       do: true

  defp release_safe_term?(term) when is_list(term),
    do: Enum.all?(term, &release_safe_term?/1)

  defp release_safe_term?(term) when is_tuple(term),
    do: term |> Tuple.to_list() |> Enum.all?(&release_safe_term?/1)

  defp release_safe_term?(term) when is_map(term) do
    term = if is_struct(term), do: Map.from_struct(term), else: term

    Enum.all?(term, fn {key, value} ->
      release_safe_term?(key) and release_safe_term?(value)
    end)
  end

  defp release_safe_term?(_term), do: false

  defp evaluation_plan(compiled, pointer) do
    %Location{resource: resource_uri} = CompiledSchema.entrypoint(compiled)

    %Resource{evaluation_plans: evaluation_plans} =
      Map.fetch!(CompiledSchema.resources(compiled), resource_uri)

    Map.fetch!(evaluation_plans, pointer)
  end
end
