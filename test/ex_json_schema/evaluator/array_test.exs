defmodule ExJsonSchema.Evaluator.ArrayTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator
  alias ExJsonSchema.Evaluator.Result

  test "evaluates legacy tuple items and additionalItems" do
    schema = %{
      "$schema" => "http://json-schema.org/draft-07/schema#",
      "items" => [%{"type" => "integer"}, %{"type" => "string"}],
      "additionalItems" => false
    }

    assert valid?([1, "two"], schema)
    refute valid?(["one", "two"], schema)
    refute valid?([1, "two", 3], schema)
  end

  test "evaluates a uniform legacy items schema" do
    schema = %{"items" => %{"type" => "integer"}}
    assert valid?([1, 2, 3], schema)
    refute valid?([1, "two"], schema)
    assert valid?("not an array", schema)
  end

  test "uses prefixItems and schema-only items for 2020-12" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "prefixItems" => [%{"type" => "integer"}, %{"type" => "string"}],
      "items" => %{"type" => "boolean"},
      "additionalItems" => false
    }

    assert valid?([1, "two", true, false], schema)
    refute valid?([1, "two", 3], schema)
  end

  test "evaluates contains bounds and records matching indexes" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "contains" => %{"type" => "integer"},
      "minContains" => 2,
      "maxContains" => 3
    }

    compiled = compile(schema)

    assert %Result{valid: true, evaluated_items: evaluated_items} =
             Evaluator.evaluate([1, "two", 3], compiled)

    assert evaluated_items == MapSet.new([0, 2])
    refute Evaluator.valid?([1, "two"], compiled)
    refute Evaluator.valid?([1, 2, 3, 4], compiled)
  end

  defp valid?(instance, schema), do: Evaluator.valid?(instance, compile(schema))
  defp compile(schema), do: Compiler.compile!(schema, validate_schema: false)
end
