defmodule ExJsonSchema.EvaluatorTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator

  test "boolean schemas have a flag fast path and all output formats remain correct" do
    true_schema = Compiler.compile!(true, validate_schema: false)
    false_schema = Compiler.compile!(false, validate_schema: false)

    assert Evaluator.valid?(%{"anything" => true}, true_schema)
    refute Evaluator.valid?(%{"anything" => true}, false_schema)

    assert Evaluator.validate(nil, true_schema, output: :flag) == %{"valid" => true}
    assert Evaluator.validate(nil, false_schema, output: :flag) == %{"valid" => false}

    for format <- [:basic, :detailed, :verbose] do
      assert Evaluator.validate(nil, true_schema, output: format)["valid"]
      refute Evaluator.validate(nil, false_schema, output: format)["valid"]
    end
  end

  test "flag and basic output use equivalent compiled-plan semantics" do
    cases = [
      {%{"type" => "integer", "minimum" => 2, "maximum" => 4, "multipleOf" => 2}, 2, true},
      {%{"type" => "integer", "minimum" => 2, "maximum" => 4, "multipleOf" => 2}, 3, false},
      {%{"minLength" => 2, "maxLength" => 4, "pattern" => "^a"}, "ab", true},
      {%{"minLength" => 2, "maxLength" => 4, "pattern" => "^a"}, "b", false},
      {
        %{
          "minItems" => 2,
          "uniqueItems" => true,
          "items" => %{"type" => "integer"},
          "contains" => %{"const" => 2},
          "minContains" => 1,
          "maxContains" => 1
        },
        [1, 2],
        true
      },
      {
        %{
          "minItems" => 2,
          "uniqueItems" => true,
          "items" => %{"type" => "integer"},
          "contains" => %{"const" => 2},
          "minContains" => 1,
          "maxContains" => 1
        },
        [2, 2],
        false
      },
      {
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "required" => ["id"],
          "properties" => %{"id" => %{"type" => "integer"}},
          "unevaluatedProperties" => false
        },
        %{"id" => 1},
        true
      },
      {
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "required" => ["id"],
          "properties" => %{"id" => %{"type" => "integer"}},
          "unevaluatedProperties" => false
        },
        %{"id" => 1, "extra" => true},
        false
      },
      {
        %{
          "allOf" => [%{"type" => "integer"}],
          "anyOf" => [%{"minimum" => 1}, %{"maximum" => -1}],
          "oneOf" => [%{"multipleOf" => 2}, %{"multipleOf" => 3}]
        },
        2,
        true
      },
      {
        %{
          "allOf" => [%{"type" => "integer"}],
          "anyOf" => [%{"minimum" => 1}, %{"maximum" => -1}],
          "oneOf" => [%{"multipleOf" => 2}, %{"multipleOf" => 3}]
        },
        6,
        false
      }
    ]

    for {{schema, instance, expected}, index} <- Enum.with_index(cases) do
      compiled = Compiler.compile!(schema, validate_schema: false)

      assert Evaluator.valid?(instance, compiled) == expected, "flag mismatch in case #{index}"

      assert Evaluator.validate(instance, compiled, output: :basic)["valid"] == expected,
             "basic mismatch in case #{index}"
    end
  end
end
