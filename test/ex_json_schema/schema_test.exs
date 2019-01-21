defmodule NExJsonSchema.SchemaTest do
  use ExUnit.Case, async: true

  import NExJsonSchema.Schema, only: [resolve: 1, get_ref_schema: 2]

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
    assert_raise NExJsonSchema.Schema.UnsupportedSchemaVersionError, fn -> resolve(draft3_schema) end
    assert_raise NExJsonSchema.Schema.UnsupportedSchemaVersionError, fn -> resolve(unknown_schema) end
  end

  test "resolves a schema" do
    schema = %{"foo" => 1, "bar" => %{"baz" => 3}}
    assert resolve(schema) == %NExJsonSchema.Schema.Root{refs: %{}, schema: schema}
  end

  test "schema is validated against its meta-schema" do
    schema = %{"properties" => "foo"}

    assert_raise NExJsonSchema.Schema.InvalidSchemaError,
                 "schema did not pass validation against its meta-schema:\n* type mismatch. Expected object but got string (at $.properties)",
                 fn -> resolve(schema) end
  end

  test "resolving an absolute reference in a scoped schema" do
    schema = %{
      "id" => "http://foo.bar/schema.json#",
      "$ref" => "http://localhost:1234/subSchemas.json#/integer"
    }

    resolved = resolve(schema)
    assert get_ref_schema(resolved, resolved.schema["$ref"]) == %{"type" => "integer"}
  end

  test "resolves a reference" do
    schema = %{"foo" => %{"$ref" => "#/bar"}, "bar" => "baz"}
    resolved = resolve(schema)
    path = get_in(resolved.schema, ["foo", "$ref"])
    assert get_ref_schema(resolved, path) == "baz"
  end

  test "resolves a root reference" do
    schema = %{"$ref" => "#"}
    resolved = resolve(schema)
    assert get_ref_schema(resolved, resolved.schema["$ref"]) == resolved.schema
  end

  test "catches references with an invalid property in the path" do
    schema = %{"$ref" => "#/foo"}

    assert_raise NExJsonSchema.Schema.InvalidSchemaError, "reference $.foo could not be resolved", fn ->
      resolve(schema)
    end
  end

  test "catches references with an invalid index in the path" do
    schema = %{"$ref" => "http://json-schema.org/schema#/1"}

    assert_raise NExJsonSchema.Schema.InvalidSchemaError,
                 "reference http://json-schema.org/schema#/1 could not be resolved",
                 fn -> resolve(schema) end
  end

  test "catches invalid references" do
    schema = %{"$ref" => "#definitions/foo"}

    assert_raise NExJsonSchema.Schema.InvalidSchemaError, "invalid reference #definitions/foo", fn ->
      resolve(schema)
    end
  end

  test "changing the resolution scope" do
    schema = %{"id" => "#/foo_scope/", "foo" => %{"$ref" => "bar"}, "foo_scope" => %{"bar" => "baz"}}
    resolved = resolve(schema)
    path = get_in(resolved.schema, ["foo", "$ref"])
    assert get_ref_schema(resolved, path) == "baz"
  end

  test "caching a resolved remote reference" do
    schema = %{"$ref" => "http://localhost:1234/integer.json"}
    assert resolve(schema).refs == %{"http://localhost:1234/integer.json" => %{"type" => "integer"}}
  end

  test "resolving a remote schema" do
    url = "http://localhost:1234/integer.json"
    schema = %{"$ref" => url}
    resolved = resolve(schema)
    path = resolved.schema["$ref"]
    assert get_ref_schema(resolved, path) == %{"type" => "integer"}
  end

  test "using a previously cached remote schema" do
    url = "http://localhost:1234/integer.json"
    refs = Map.put(%{}, url, %{"type" => "boolean"})
    schema = %NExJsonSchema.Schema.Root{refs: refs, schema: %{"$ref" => url}}
    resolved = resolve(schema)
    path = resolved.schema["$ref"]
    assert get_ref_schema(resolved, path) == %{"type" => "boolean"}
  end
end
