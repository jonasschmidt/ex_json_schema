defmodule ExJsonSchema.Evaluator.ApplicatorTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator
  alias ExJsonSchema.Evaluator.Result

  test "evaluates allOf, anyOf, and oneOf branches" do
    assert valid?(2, %{"allOf" => [%{"type" => "integer"}, %{"minimum" => 1}]})
    refute valid?(0, %{"allOf" => [%{"type" => "integer"}, %{"minimum" => 1}]})

    assert valid?("value", %{"anyOf" => [%{"type" => "integer"}, %{"type" => "string"}]})
    refute valid?(true, %{"anyOf" => [%{"type" => "integer"}, %{"type" => "string"}]})

    assert valid?(2, %{"oneOf" => [%{"type" => "integer"}, %{"minimum" => 3}]})
    refute valid?(4, %{"oneOf" => [%{"type" => "integer"}, %{"minimum" => 3}]})
  end

  test "not reverses validity and suppresses evaluated annotations" do
    schema = %{"not" => %{"properties" => %{"name" => true}}}

    assert %Result{valid: false, evaluated_properties: evaluated_properties} =
             Evaluator.evaluate(%{"name" => "Ada"}, compile(schema))

    assert evaluated_properties == MapSet.new()
  end

  test "evaluates only the selected conditional branch" do
    schema = %{
      "if" => %{"properties" => %{"kind" => %{"const" => "number"}}},
      "then" => %{"properties" => %{"value" => %{"type" => "number"}}},
      "else" => %{"properties" => %{"value" => %{"type" => "string"}}}
    }

    assert valid?(%{"kind" => "number", "value" => 1}, schema)
    refute valid?(%{"kind" => "number", "value" => "one"}, schema)
    assert valid?(%{"kind" => "text", "value" => "one"}, schema)
    refute valid?(%{"kind" => "text", "value" => 1}, schema)
  end

  test "retains branch hierarchy in verbose output" do
    schema = %{"anyOf" => [%{"type" => "integer"}, %{"type" => "string"}]}
    output = Evaluator.validate(true, compile(schema), output: :verbose)

    assert [any_of] = output["errors"]
    assert any_of["keywordLocation"] == "/anyOf"
    assert length(any_of["errors"]) == 2
  end

  defp valid?(instance, schema), do: Evaluator.valid?(instance, compile(schema))
  defp compile(schema), do: Compiler.compile!(schema, validate_schema: false)
end
