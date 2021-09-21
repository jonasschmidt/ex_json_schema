defmodule ExComponentSchema.SchemaTest do
  use ExUnit.Case, async: true

  import ExComponentSchema.Schema, only: [resolve: 1, get_fragment: 2, get_fragment!: 2]

  test "fails when trying to resolve something that is not a schema" do
    assert_raise FunctionClauseError, fn -> resolve("foo") end
  end

  test "only resolves draft 4 schemata" do
    versionless_schema = %{}
    current_schema = %{"$schema" => "http://json-schema.org/schema#"}
    draft4_schema = %{"$schema" => "http://json-schema.org/draft-04/schema#"}
    draft3_schema = %{"$schema" => "http://json-schema.org/draft-03/schema#"}
    unknown_schema = %{"$schema" => "http://foo.schema.org/schema#"}
    assert is_map(resolve(versionless_schema)) == true
    assert is_map(resolve(current_schema)) == true
    assert is_map(resolve(draft4_schema)) == true

    assert_raise ExComponentSchema.Schema.UnsupportedSchemaVersionError, fn ->
      resolve(draft3_schema)
    end

    assert_raise ExComponentSchema.Schema.UnsupportedSchemaVersionError, fn ->
      resolve(unknown_schema)
    end
  end

  test "resolves a schema" do
    schema = %{"foo" => 1, "bar" => %{"baz" => 3}}

    assert resolve(schema) == %ExComponentSchema.Schema.Root{
             refs: %{},
             schema: schema,
             version: 7
           }
  end

  test "schema is validated against its meta-schema" do
    schema = %{"properties" => "foo"}

    assert_raise ExComponentSchema.Schema.InvalidSchemaError,
                 ~s(schema did not pass validation against its meta-schema: [%ExComponentSchema.Validator.Error{error: %ExComponentSchema.Validator.Error.Type{actual: "string", expected: ["object"]}, path: "#/properties"}]),
                 fn -> resolve(schema) end
  end

  test "resolving an absolute reference in a scoped schema" do
    schema = %{
      "id" => "http://foo.bar/schema.json#",
      "$ref" => "http://localhost:1234/subSchemas.json#/integer"
    }

    resolved = resolve(schema)
    assert get_fragment!(resolved, resolved.schema["$ref"]) == %{"type" => "integer"}
  end

  test "resolves a reference" do
    schema = %{"foo" => %{"$ref" => "#/bar"}, "bar" => "baz"}
    resolved = resolve(schema)
    path = get_in(resolved.schema, ["foo", "$ref"])
    assert get_fragment!(resolved, path) == "baz"
  end

  test "resolves a root reference" do
    schema = %{"$ref" => "#"}
    resolved = resolve(schema)
    assert get_fragment!(resolved, resolved.schema["$ref"]) == resolved.schema
  end

  test "catches references with an invalid property in the path" do
    schema = %{"$ref" => "#/foo"}

    assert_raise ExComponentSchema.Schema.InvalidReferenceError, "invalid reference #/foo", fn ->
      resolve(schema)
    end
  end

  test "catches references with an invalid index in the path" do
    schema = %{"$ref" => "http://json-schema.org/schema#/1"}

    assert_raise ExComponentSchema.Schema.InvalidReferenceError,
                 "invalid reference http://json-schema.org/schema#/1",
                 fn -> resolve(schema) end
  end

  test "catches invalid references" do
    schema = %{"$ref" => "#definitions/foo"}

    assert_raise ExComponentSchema.Schema.InvalidReferenceError,
                 "invalid reference #definitions/foo",
                 fn -> resolve(schema) end
  end

  test "caching a resolved remote reference" do
    schema = %{"$ref" => "http://localhost:1234/integer.json"}

    assert resolve(schema).refs == %{
             "http://localhost:1234/integer.json" => %{"type" => "integer"}
           }
  end

  test "resolving a remote schema" do
    url = "http://localhost:1234/integer.json"
    schema = %{"$ref" => url}
    resolved = resolve(schema)
    path = resolved.schema["$ref"]
    assert get_fragment!(resolved, path) == %{"type" => "integer"}
  end

  test "using a previously cached remote schema" do
    url = "http://localhost:1234/integer.json"
    refs = Map.put(%{}, url, %{"type" => "boolean"})
    schema = %ExComponentSchema.Schema.Root{refs: refs, schema: %{"$ref" => url}}
    resolved = resolve(schema)
    path = resolved.schema["$ref"]
    assert get_fragment!(resolved, path) == %{"type" => "boolean"}
  end

  test "fetching a ref schema with an invalid reference" do
    schema = resolve(%{"foo" => 1, "bar" => %{"baz" => 3}})
    assert {:error, :invalid_reference} == get_fragment(schema, "#/baz")

    assert_raise ExComponentSchema.Schema.InvalidReferenceError, "invalid reference #/baz", fn ->
      get_fragment!(schema, "#/baz")
    end
  end

  test "fetching a ref schema with a path" do
    schema =
      resolve(%{
        "properties" => %{"foo" => %{"$ref" => "http://localhost:8000/subschema.json#/foo"}}
      })

    assert get_fragment!(schema, "#/properties/foo") == %{
             "$ref" => ["http://localhost:8000/subschema.json", "foo"]
           }
  end

  test "fetching a ref schema with a URL" do
    schema = resolve(%{"$ref" => "http://localhost:8000/subschema.json#/foo"})

    assert get_fragment!(schema, "http://localhost:8000/subschema.json#/foo") == %{
             "$ref" => ["http://localhost:8000/subsubschema.json", "foo"]
           }
  end
end
