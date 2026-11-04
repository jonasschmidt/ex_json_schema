defmodule ExJsonSchema.Evaluator.ReferenceTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator

  test "evaluates local pointers and named anchors" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/root",
      "$defs" => %{
        "integer" => %{"$anchor" => "integer", "type" => "integer"}
      },
      "allOf" => [
        %{"$ref" => "#/$defs/integer"},
        %{"$ref" => "#integer"}
      ]
    }

    assert valid?(1, schema)
    refute valid?("one", schema)
  end

  test "loads and evaluates external references without validation-time resolver calls" do
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    resolver = fn "https://example.com/integer" ->
      Agent.update(calls, &(&1 + 1))
      {:ok, %{"type" => "integer"}}
    end

    compiled =
      Compiler.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "$id" => "https://example.com/root",
          "$ref" => "integer"
        },
        resolver: resolver,
        validate_schema: false
      )

    assert Agent.get(calls, & &1) == 1
    assert Evaluator.valid?(1, compiled)
    refute Evaluator.valid?("one", compiled)
    assert Evaluator.valid?(2, compiled)
    assert Agent.get(calls, & &1) == 1
  end

  test "draft 2020-12 evaluates sibling keywords next to $ref" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$defs" => %{"integer" => %{"type" => "integer"}},
      "$ref" => "#/$defs/integer",
      "minimum" => 2
    }

    assert valid?(2, schema)
    refute valid?(1, schema)
  end

  test "older drafts ignore sibling keywords next to $ref" do
    schema = %{
      "$schema" => "http://json-schema.org/draft-07/schema#",
      "definitions" => %{"integer" => %{"type" => "integer"}},
      "$ref" => "#/definitions/integer",
      "minimum" => 2
    }

    assert valid?(1, schema)
    refute valid?("one", schema)
  end

  test "target resources evaluate with their own dialect" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/root",
      "$defs" => %{
        "legacy" => %{
          "$schema" => "http://json-schema.org/draft-04/schema#",
          "id" => "legacy",
          "type" => "integer"
        }
      },
      "$ref" => "legacy"
    }

    refute valid?(1.0, schema)
    assert valid?(1, schema)
  end

  test "non-progressing self references terminate" do
    schema = %{"$id" => "https://example.com/loop", "$ref" => "#"}
    assert valid?("anything", schema)
  end

  defp valid?(instance, schema),
    do: Evaluator.valid?(instance, Compiler.compile!(schema, validate_schema: false))
end
