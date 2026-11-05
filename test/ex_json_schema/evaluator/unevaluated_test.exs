defmodule ExJsonSchema.Evaluator.UnevaluatedTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator

  test "unevaluatedProperties consumes successful property annotations" do
    schema =
      modern(%{
        "properties" => %{"name" => %{"type" => "string"}},
        "unevaluatedProperties" => false
      })

    assert valid?(%{"name" => "Ada"}, schema)
    refute valid?(%{"name" => "Ada", "extra" => true}, schema)
  end

  test "combines successful applicator annotations without leaking failed branches" do
    successful =
      modern(%{
        "anyOf" => [
          %{"properties" => %{"a" => %{"type" => "integer"}}},
          %{"properties" => %{"b" => %{"type" => "integer"}}}
        ],
        "unevaluatedProperties" => false
      })

    assert valid?(%{"a" => 1, "b" => 2}, successful)

    failed_branch =
      modern(%{
        "anyOf" => [
          %{
            "properties" => %{"a" => %{"type" => "integer"}},
            "required" => ["missing"]
          },
          true
        ],
        "unevaluatedProperties" => false
      })

    refute valid?(%{"a" => 1}, failed_branch)
  end

  test "negated branches do not leak evaluated properties" do
    schema =
      modern(%{
        "not" => %{
          "properties" => %{"a" => true},
          "required" => ["forbidden"]
        },
        "unevaluatedProperties" => false
      })

    refute valid?(%{"a" => 1}, schema)
  end

  test "unevaluatedItems combines prefix, items, and contains annotations" do
    prefix_schema =
      modern(%{
        "prefixItems" => [%{"type" => "integer"}],
        "items" => %{"type" => "string"},
        "unevaluatedItems" => false
      })

    assert valid?([1, "two"], prefix_schema)

    contains_schema =
      modern(%{
        "contains" => %{"type" => "integer"},
        "unevaluatedItems" => false
      })

    assert valid?([1, 2], contains_schema)
    refute valid?([1, "two"], contains_schema)
  end

  test "references propagate evaluated property annotations" do
    schema =
      modern(%{
        "$defs" => %{
          "named" => %{"properties" => %{"name" => true}}
        },
        "$ref" => "#/$defs/named",
        "unevaluatedProperties" => false
      })

    assert valid?(%{"name" => "Ada"}, schema)
    refute valid?(%{"other" => true}, schema)
  end

  defp modern(schema),
    do: Map.put(schema, "$schema", "https://json-schema.org/draft/2020-12/schema")

  defp valid?(instance, schema),
    do: Evaluator.valid?(instance, Compiler.compile!(schema, validate_schema: false))
end
