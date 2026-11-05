defmodule ExJsonSchema.Compiler.ScannerTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.Compiler.Dialect
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Registry
  alias ExJsonSchema.Compiler.Resource
  alias ExJsonSchema.Compiler.Scanner

  test "discovers nested compound resources without rewriting schema values" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/root",
      "$anchor" => "root",
      "$defs" => %{
        "embedded" => %{
          "$id" => "child",
          "$anchor" => "child",
          "properties" => %{
            "value" => %{"$dynamicAnchor" => "node", "type" => "integer"}
          }
        }
      }
    }

    original = schema
    dialect = Registry.default_dialect()

    assert {:ok, graph} = Scanner.scan(schema, "https://retrieval.example/schema", dialect)
    assert schema == original

    assert Map.keys(graph.resources) |> Enum.sort() ==
             ["https://example.com/child", "https://example.com/root"]

    assert %Resource{
             retrieval_uri: "https://retrieval.example/schema",
             dialect: %Dialect{version: :"2020-12"},
             anchors: root_anchors,
             locations: root_locations
           } = graph.resources["https://example.com/root"]

    assert %Resource{
             locations: child_locations,
             anchors: child_anchors,
             dynamic_anchors: dynamic_anchors
           } = graph.resources["https://example.com/child"]

    assert graph.aliases["https://retrieval.example/schema"] == "https://example.com/root"
    assert root_anchors["root"] == Location.root("https://example.com/root")

    assert root_locations["/$defs/embedded"] ==
             Location.root("https://example.com/child")

    assert root_locations["/$defs/embedded/properties/value"] ==
             %Location{
               resource: "https://example.com/child",
               pointer: ["properties", "value"]
             }

    assert child_locations["/properties/value"] ==
             %Location{
               resource: "https://example.com/child",
               pointer: ["properties", "value"]
             }

    assert child_anchors["child"] == Location.root("https://example.com/child")
    assert %Location{pointer: ["properties", "value"]} = dynamic_anchors["node"]
  end

  test "inherits a dialect and permits an explicit supported dialect at a resource boundary" do
    schema = %{
      "$schema" => "http://json-schema.org/draft-07/schema#",
      "$id" => "https://example.com/root",
      "definitions" => %{
        "modern" => %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "$id" => "modern"
        }
      }
    }

    assert {:ok, graph} = Scanner.scan(schema, nil, Registry.default_dialect())

    assert %Resource{dialect: %Dialect{version: 7}} =
             graph.resources["https://example.com/root"]

    assert %Resource{dialect: %Dialect{version: :"2020-12"}} =
             graph.resources["https://example.com/modern"]
  end

  test "indexes legacy fragment identifiers as named anchors" do
    schema = %{
      "$schema" => "http://json-schema.org/draft-04/schema#",
      "id" => "https://example.com/root",
      "definitions" => %{
        "integer" => %{"id" => "#integer", "type" => "integer"}
      }
    }

    assert {:ok, graph} = Scanner.scan(schema, nil, Registry.default_dialect())

    assert %Resource{anchors: %{"integer" => %Location{pointer: pointer}}} =
             graph.resources["https://example.com/root"]

    assert pointer == ["definitions", "integer"]
    assert Map.keys(graph.resources) == ["https://example.com/root"]
  end

  test "rejects duplicate canonical resource identifiers" do
    schema = %{
      "$id" => "https://example.com/root",
      "$defs" => %{
        "one" => %{"$id" => "duplicate"},
        "two" => %{"$id" => "duplicate"}
      }
    }

    assert {:error,
            %CompileError{
              reason: :invalid_schema,
              uri: "https://example.com/duplicate"
            }} = Scanner.scan(schema, nil, Registry.default_dialect())
  end
end
