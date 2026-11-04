defmodule ExJsonSchema.Evaluator.ObjectTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator
  alias ExJsonSchema.Evaluator.Result

  test "evaluates properties, patterns, and additional properties together" do
    schema = %{
      "properties" => %{"name" => %{"type" => "string"}},
      "patternProperties" => %{"^x-" => %{"type" => "integer"}},
      "additionalProperties" => false
    }

    assert valid?(%{"name" => "Ada", "x-count" => 2}, schema)
    refute valid?(%{"name" => 1}, schema)
    refute valid?(%{"x-count" => "two"}, schema)
    refute valid?(%{"other" => true}, schema)
  end

  test "tracks property annotations only for successful object applicators" do
    schema = %{
      "properties" => %{
        "valid" => %{"type" => "integer"},
        "invalid" => %{"type" => "integer"}
      }
    }

    assert %Result{evaluated_properties: evaluated_properties} =
             Evaluator.evaluate(%{"valid" => 1}, compile(schema))

    assert evaluated_properties == MapSet.new(["valid"])

    assert %Result{evaluated_properties: failed_properties} =
             Evaluator.evaluate(%{"invalid" => "no"}, compile(schema))

    assert failed_properties == MapSet.new()
  end

  test "evaluates propertyNames" do
    schema = %{"propertyNames" => %{"pattern" => "^[a-z]+$"}}
    assert valid?(%{"lower" => true}, schema)
    refute valid?(%{"UPPER" => true}, schema)
    assert valid?("not an object", schema)
  end

  test "evaluates legacy property and schema dependencies" do
    schema = %{
      "dependencies" => %{
        "credit_card" => ["billing_address"],
        "name" => %{"required" => ["surname"]}
      }
    }

    assert valid?(
             %{
               "credit_card" => 1,
               "billing_address" => "somewhere",
               "name" => "Ada",
               "surname" => "Lovelace"
             },
             schema
           )

    refute valid?(%{"credit_card" => 1}, schema)
    refute valid?(%{"name" => "Ada"}, schema)
  end

  test "evaluates dependentRequired and dependentSchemas" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "dependentRequired" => %{"credit_card" => ["billing_address"]},
      "dependentSchemas" => %{"name" => %{"required" => ["surname"]}}
    }

    assert valid?(
             %{
               "credit_card" => 1,
               "billing_address" => "somewhere",
               "name" => "Ada",
               "surname" => "Lovelace"
             },
             schema
           )

    refute valid?(%{"credit_card" => 1}, schema)
    refute valid?(%{"name" => "Ada"}, schema)
  end

  defp valid?(instance, schema), do: Evaluator.valid?(instance, compile(schema))
  defp compile(schema), do: Compiler.compile!(schema, validate_schema: false)
end
