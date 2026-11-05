defmodule ExJsonSchema.Evaluator.ScalarTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator

  test "evaluates types with draft-specific integer semantics" do
    draft4 = %{
      "$schema" => "http://json-schema.org/draft-04/schema#",
      "type" => "integer"
    }

    draft7 = %{
      "$schema" => "http://json-schema.org/draft-07/schema#",
      "type" => "integer"
    }

    refute valid?(1.0, draft4)
    assert valid?(1.0, draft7)
    assert valid?(1, draft4)
    refute valid?("1", draft7)
  end

  test "uses JSON equality for enum, const, and uniqueItems" do
    assert valid?(1.0, %{"enum" => [1]})
    assert valid?(%{"value" => 1.0}, %{"const" => %{"value" => 1}})
    refute valid?([%{"value" => 1}, %{"value" => 1.0}], %{"uniqueItems" => true})
    refute valid?([-0.0, 0], %{"uniqueItems" => true})
  end

  test "evaluates numeric boundaries and multiples" do
    schema = %{
      "multipleOf" => 0.1,
      "minimum" => 1,
      "exclusiveMaximum" => 2
    }

    assert valid?(1.5, schema)
    refute valid?(0.5, schema)
    refute valid?(2, schema)
    refute valid?(1.55, schema)
  end

  test "evaluates string and collection counts, patterns, and required properties" do
    assert valid?("αβ", %{"minLength" => 2, "maxLength" => 2, "pattern" => "^α"})
    refute valid?("α", %{"minLength" => 2})
    assert valid?([1, 2], %{"minItems" => 2, "maxItems" => 2})
    refute valid?([1], %{"minItems" => 2})
    assert valid?(%{"name" => "A"}, %{"required" => ["name"], "minProperties" => 1})
    refute valid?(%{}, %{"required" => ["name"]})
  end

  test "collects metadata annotations without affecting validity" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "title" => "Example",
      "default" => 42
    }

    output =
      schema
      |> compile()
      |> then(&Evaluator.validate("anything", &1))

    assert output["valid"]
    assert Enum.map(output["annotations"], & &1["annotation"]) == ["Example", 42]
  end

  defp valid?(instance, schema), do: Evaluator.valid?(instance, compile(schema))

  defp compile(schema), do: Compiler.compile!(schema, validate_schema: false)
end
