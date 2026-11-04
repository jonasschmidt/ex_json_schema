defmodule ExJsonSchema.CompilerTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.CompiledSchema
  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Reference
  alias ExJsonSchema.Compiler.Resource
  alias ExJsonSchema.ReferenceError

  test "compiles an eager immutable graph" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/root",
      "definitions" => %{"integer" => %{"type" => "integer"}},
      "$ref" => "#/definitions/integer"
    }

    assert {:ok,
            %CompiledSchema{
              entrypoint: %Location{resource: "https://example.com/root"},
              resources: %{
                "https://example.com/root" => %Resource{
                  schema: ^schema,
                  references: %{
                    "/$ref" => %Reference{
                      target: %Location{pointer: ["definitions", "integer"]}
                    }
                  }
                }
              }
            }} = Compiler.compile(schema, validate_schema: false)
  end

  test "bang and non-bang paths preserve unsupported dialect details" do
    schema = %{"$schema" => "https://example.com/unknown"}

    assert {:error, %CompileError{reason: :unsupported_dialect} = error} =
             Compiler.compile(schema)

    raised = assert_raise CompileError, fn -> Compiler.compile!(schema) end
    assert comparable(raised) == comparable(error)
  end

  test "bang and non-bang paths preserve resolver failures" do
    schema = %{"$ref" => "https://example.com/remote"}
    resolver = fn _uri -> {:error, :offline} end

    assert {:error, error} =
             Compiler.compile(schema, resolver: resolver, validate_schema: false)

    assert %CompileError{reason: :resolver} = error

    raised =
      assert_raise CompileError, fn ->
        Compiler.compile!(schema, resolver: resolver, validate_schema: false)
      end

    assert comparable(raised) == comparable(error)
  end

  test "bang and non-bang paths preserve invalid reference failures" do
    schema = %{"$ref" => "#/missing"}

    assert {:error, error} = Compiler.compile(schema, validate_schema: false)
    assert %CompileError{reason: :invalid_reference} = error

    raised =
      assert_raise CompileError, fn ->
        Compiler.compile!(schema, validate_schema: false)
      end

    assert comparable(raised) == comparable(error)
  end

  test "bang and non-bang paths preserve invalid schema failures" do
    assert {:error, error} = Compiler.compile(%{type: "string"})
    assert %CompileError{reason: :invalid_schema} = error

    raised = assert_raise CompileError, fn -> Compiler.compile!(%{type: "string"}) end
    assert comparable(raised) == comparable(error)

    invalid_2020 = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "type" => "not-a-type"
    }

    assert {:error, %CompileError{reason: :invalid_schema, output: output}} =
             Compiler.compile(invalid_2020)

    refute output["valid"]

    assert {:ok, _compiled} =
             Compiler.compile(invalid_2020, validate_schema: false)
  end

  test "fetch_schema creates scoped handles for pointers and anchors without copying the graph" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/root",
      "$defs" => %{
        "child" => %{"$anchor" => "child", "type" => "integer"}
      }
    }

    assert {:ok, compiled} = Compiler.compile(schema, validate_schema: false)
    assert {:ok, pointer} = Compiler.fetch_schema(compiled, "#/$defs/child")
    assert {:ok, anchor} = Compiler.fetch_schema(compiled, "#child")

    assert %CompiledSchema{
             entrypoint: %Location{pointer: ["$defs", "child"]} = entrypoint,
             resources: resources,
             aliases: aliases
           } = pointer

    assert %CompiledSchema{entrypoint: ^entrypoint} = anchor
    assert %CompiledSchema{resources: ^resources, aliases: ^aliases} = compiled
  end

  test "fetch_schema accepts retrieval aliases, canonical locations, and resource URIs" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://canonical.example/root",
      "$defs" => %{"child" => %{"$id" => "child", "type" => "integer"}}
    }

    assert {:ok, compiled} =
             Compiler.compile(schema,
               retrieval_uri: "https://retrieval.example/root",
               validate_schema: false
             )

    assert {:ok, via_retrieval} =
             Compiler.fetch_schema(compiled, "https://retrieval.example/root#/$defs/child")

    assert {:ok, via_canonical} =
             Compiler.fetch_schema(compiled, "https://canonical.example/child")

    assert %CompiledSchema{entrypoint: entrypoint} = via_retrieval
    assert %CompiledSchema{entrypoint: ^entrypoint} = via_canonical
    assert %Location{resource: "https://canonical.example/child"} = entrypoint
  end

  test "fetch_schema and fetch_schema! return equivalent missing-target errors" do
    compiled = Compiler.compile!(true, validate_schema: false)

    assert {:error, error} = Compiler.fetch_schema(compiled, "#missing")

    raised =
      assert_raise ReferenceError, fn -> Compiler.fetch_schema!(compiled, "#missing") end

    assert Map.take(raised, [:reference, :base_uri, :message]) ==
             Map.take(error, [:reference, :base_uri, :message])
  end

  defp comparable(error) do
    Map.take(error, [:reason, :message, :uri, :details, :output])
  end
end
