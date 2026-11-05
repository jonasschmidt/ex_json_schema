defmodule ExJsonSchema.Evaluator.DynamicReferenceTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator

  test "outer dynamic anchors override a dynamic reference's static target" do
    tree = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/tree",
      "$dynamicAnchor" => "node",
      "type" => "object",
      "properties" => %{
        "children" => %{
          "type" => "array",
          "items" => %{"$dynamicRef" => "#node"}
        }
      }
    }

    strict_tree = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/strict-tree",
      "$dynamicAnchor" => "node",
      "$ref" => "https://example.com/tree",
      "properties" => %{
        "data" => %{"type" => "string"}
      }
    }

    compiled =
      Compiler.compile!(strict_tree,
        resources: %{"https://example.com/tree" => tree},
        validate_schema: false
      )

    assert Evaluator.valid?(
             %{"data" => "root", "children" => [%{"data" => "child"}]},
             compiled
           )

    refute Evaluator.valid?(
             %{"data" => "root", "children" => [%{"data" => 123}]},
             compiled
           )
  end

  test "dynamic references fall back to a non-dynamic static anchor" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/root",
      "$defs" => %{
        "integer" => %{"$anchor" => "value", "type" => "integer"}
      },
      "$dynamicRef" => "#value"
    }

    compiled = Compiler.compile!(schema, validate_schema: false)
    assert Evaluator.valid?(1, compiled)
    refute Evaluator.valid?("one", compiled)
  end

  test "non-progressing dynamic cycles terminate while recursive instances progress" do
    loop = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/loop",
      "$dynamicAnchor" => "node",
      "$dynamicRef" => "#node"
    }

    assert Evaluator.valid?("anything", Compiler.compile!(loop, validate_schema: false))

    recursive = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/list",
      "$dynamicAnchor" => "node",
      "type" => "object",
      "properties" => %{
        "next" => %{"$dynamicRef" => "#node"}
      }
    }

    compiled = Compiler.compile!(recursive, validate_schema: false)
    assert Evaluator.valid?(%{"next" => %{"next" => %{}}}, compiled)
    refute Evaluator.valid?(%{"next" => 1}, compiled)

    deep_instance =
      Enum.reduce(1..200, %{}, fn _index, next ->
        %{"next" => next}
      end)

    assert Evaluator.valid?(deep_instance, compiled)
  end
end
