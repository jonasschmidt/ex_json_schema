defmodule ExJsonSchema.Compiler.ReferenceResolverTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.Compiler.Loader
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Options
  alias ExJsonSchema.Compiler.Reference
  alias ExJsonSchema.Compiler.ReferenceResolver
  alias ExJsonSchema.Compiler.Resource

  test "compiles local pointers and named anchors into static targets" do
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

    assert {:ok, graph} = load_and_resolve(schema)

    assert %Resource{references: references, anchors: anchors} =
             graph.resources["https://example.com/root"]

    assert %Reference{
             target: %Location{
               resource: "https://example.com/root",
               pointer: ["$defs", "integer"]
             }
           } = references["/allOf/0/$ref"]

    assert %Reference{target: anchor_target} = references["/allOf/1/$ref"]
    assert anchor_target == anchors["integer"]
  end

  test "resolves relative external resources through retrieval URI aliases" do
    schema = %{"$ref" => "external#value"}

    options = %Options{
      retrieval_uri: "https://example.com/root",
      resources: %{
        "https://example.com/external" => %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "$id" => "https://canonical.example/external",
          "$anchor" => "value",
          "type" => "string"
        }
      },
      validate_schema: false
    }

    assert {:ok, graph} = Loader.load(schema, options)
    assert {:ok, graph} = ReferenceResolver.resolve(graph)

    assert %Resource{
             references: %{
               "/$ref" => %Reference{target: target}
             }
           } = graph.resources["https://example.com/root"]

    assert target == Location.root("https://canonical.example/external")
  end

  test "records the static target and anchor name for dynamic references" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/tree",
      "$dynamicAnchor" => "node",
      "$dynamicRef" => "#node"
    }

    assert {:ok, graph} = load_and_resolve(schema)

    assert %Resource{
             references: %{
               "/$dynamicRef" => %Reference{
                 target: target,
                 dynamic_anchor: "node"
               }
             }
           } = graph.resources["https://example.com/tree"]

    assert target == Location.root("https://example.com/tree")
  end

  test "indexes referenced schemas beneath unknown keywords and eagerly loads their references" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/root",
      "unknown-keyword" => %{
        "allOf" => [%{"$ref" => "remote"}]
      },
      "properties" => %{
        "value" => %{"$ref" => "#/unknown-keyword"}
      }
    }

    options = %Options{
      resources: %{
        "https://example.com/remote" => %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "type" => "integer"
        }
      },
      validate_schema: false
    }

    assert {:ok, graph} = Loader.load(schema, options)
    assert {:ok, graph} = ReferenceResolver.resolve(graph)

    assert %Resource{
             locations: %{
               "/unknown-keyword" => %Location{
                 resource: "https://example.com/root",
                 pointer: ["unknown-keyword"]
               }
             },
             references: references
           } = graph.resources["https://example.com/root"]

    assert %Reference{
             target: %Location{
               resource: "https://example.com/remote",
               pointer: []
             }
           } = references["/unknown-keyword/allOf/0/$ref"]
  end

  test "indexes array and boolean targets in external resources" do
    schema = %{"$ref" => "external#/examples/0"}

    options = %Options{
      retrieval_uri: "https://example.com/root",
      resources: %{
        "https://example.com/external" => %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "examples" => [false]
        }
      },
      validate_schema: false
    }

    assert {:ok, graph} = Loader.load(schema, options)
    assert {:ok, graph} = ReferenceResolver.resolve(graph)

    assert %Resource{
             references: %{
               "/$ref" => %Reference{
                 target: %Location{
                   resource: "https://example.com/external",
                   pointer: ["examples", 0]
                 }
               }
             }
           } = graph.resources["https://example.com/root"]
  end

  test "preserves the nearest schema base URI for promoted targets" do
    schema = %{
      "$schema" => "http://json-schema.org/draft-07/schema#",
      "$id" => "https://example.com/root.json",
      "definitions" => %{
        "scope" => %{
          "$id" => "folder/#scope",
          "unknown-keyword" => %{"$ref" => "child.json"}
        }
      },
      "properties" => %{
        "value" => %{"$ref" => "#/definitions/scope/unknown-keyword"}
      }
    }

    options = %Options{
      resources: %{
        "https://example.com/folder/child.json" => %{"type" => "integer"}
      },
      validate_schema: false
    }

    assert {:ok, graph} = Loader.load(schema, options)
    assert {:ok, graph} = ReferenceResolver.resolve(graph)

    assert %Resource{references: references} =
             graph.resources["https://example.com/root.json"]

    assert %Reference{
             base_uri: "https://example.com/folder/#scope",
             target: %Location{
               resource: "https://example.com/folder/child.json"
             }
           } = references["/definitions/scope/unknown-keyword/$ref"]
  end

  test "defers missing anchors until pointer targets have been promoted" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/root",
      "unknown-keyword" => %{
        "$anchor" => "promoted",
        "type" => "integer"
      },
      "allOf" => [
        %{"$ref" => "#promoted"},
        %{"$ref" => "#/unknown-keyword"}
      ]
    }

    assert {:ok, graph} = Loader.load(schema, %Options{validate_schema: false})

    assert %Resource{references: references} =
             graph.resources["https://example.com/root"]

    assert %Reference{target: target} = references["/allOf/0/$ref"]
    assert %Reference{target: ^target} = references["/allOf/1/$ref"]
  end

  test "promotes local resource identifiers before attempting external loading" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/root",
      "unknown-keyword" => %{
        "$id" => "promoted",
        "type" => "integer"
      },
      "allOf" => [
        %{"$ref" => "promoted"},
        %{"$ref" => "#/unknown-keyword"}
      ]
    }

    resolver = fn uri ->
      send(self(), {:resolver_called, uri})
      {:error, :unexpected}
    end

    options = %Options{resolver: resolver, validate_schema: false}

    assert {:ok, graph} = Loader.load(schema, options)
    refute_received {:resolver_called, _uri}

    assert %Resource{references: references} =
             graph.resources["https://example.com/root"]

    assert %Reference{target: target} = references["/allOf/0/$ref"]
    assert %Reference{target: ^target} = references["/allOf/1/$ref"]
  end

  test "returns a structured error for absent resources and fragments" do
    options = %Options{
      retrieval_uri: "https://example.com/root",
      validate_schema: false
    }

    assert {:error, %CompileError{reason: :invalid_reference}} =
             Loader.load(%{"$ref" => "missing"}, options)

    assert {:error,
            %CompileError{
              reason: :invalid_reference,
              details: %{reference: "#/missing"}
            }} = Loader.load(%{"$ref" => "#/missing"}, options)
  end

  defp load_and_resolve(schema) do
    options = %Options{validate_schema: false}

    with {:ok, graph} <- Loader.load(schema, options),
         {:ok, graph} <- ReferenceResolver.resolve(graph) do
      {:ok, graph}
    end
  end
end
