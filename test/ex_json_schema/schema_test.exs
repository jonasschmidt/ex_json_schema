defmodule ExJsonSchema.SchemaTest do
  use ExUnit.Case, async: true

  import ExJsonSchema.Schema, only: [resolve: 1]

  test "only resolves draft 4 schemata" do
    versionless_schema = %{}
    current_schema = %{"$schema" => "http://json-schema.org/schema#"}
    draft4_schema = %{"$schema" => "http://json-schema.org/draft-04/schema#"}
    draft3_schema = %{"$schema" => "http://json-schema.org/draft-03/schema#"}
    unknown_schema = %{"$schema" => "http://foo.schema.org/schema#"}
    assert is_map(resolve(versionless_schema)) == true
    assert is_map(resolve(current_schema)) == true
    assert is_map(resolve(draft4_schema)) == true
    assert_raise ExJsonSchema.Schema.UnsupportedSchemaVersionError, fn -> resolve(draft3_schema) end
    assert_raise ExJsonSchema.Schema.UnsupportedSchemaVersionError, fn -> resolve(unknown_schema) end
  end

  test "resolves a schema" do
    schema = %{"foo" => 1, "bar" => %{"baz" => 3}}
    assert resolve(schema) == %ExJsonSchema.Schema.Root{refs: %{}, schema: schema}
  end

  test "schema is validated against its meta-schema" do
    schema = %{"properties" => "foo"}
    assert_raise ExJsonSchema.Schema.InvalidSchemaError, "schema did not pass validation against its meta-schema", fn -> resolve(schema) end
  end

  test "resolves a reference" do
    schema = %{"foo" => %{"$ref" => "#/bar"}, "bar" => "baz"}
    resolved = resolve(schema)
    ref = get_in(resolved.schema, ["foo", "$ref"])
    assert ref.(resolved) == {resolved, "baz"}
  end

  test "resolves a root reference" do
    schema = %{"$ref" => "#"}
    resolved = resolve(schema)
    assert resolved.schema["$ref"].(resolved) == {resolved, resolved.schema}
  end

  test "catches invalid references" do
    schema = %{"$ref" => "#/foo"}
    assert_raise ExJsonSchema.Schema.InvalidSchemaError, "reference #/foo could not be resolved", fn -> resolve(schema) end
  end

  test "changing the resolution scope" do
    schema = %{"id" => "#/foo_scope/", "foo" => %{"$ref" => "bar"}, "foo_scope" => %{"bar" => "baz"}}
    resolved = resolve(schema)
    ref = get_in(resolved.schema, ["foo", "$ref"])
    assert ref.(resolved) == {resolved, "baz"}
  end

  test "caching a resolved remote reference" do
    schema = %{"$ref" => "http://localhost:1234/integer.json"}
    assert resolve(schema).refs == %{"http://localhost:1234/integer.json" => %{"type" => "integer"}}
  end

  test "resolving a remote schema" do
    url = "http://localhost:1234/integer.json"
    schema = %{"$ref" => url}
    resolved = resolve(schema)
    ref = resolved.schema["$ref"]
    assert ref.(resolved) == {%ExJsonSchema.Schema.Root{resolved | schema: %{"type" => "integer"}}, %{"type" => "integer"}}
  end

  test "using a previously cached remote schema" do
    url = "http://localhost:1234/integer.json"
    refs = Map.put(%{}, url, %{"type" => "boolean"})
    schema = %ExJsonSchema.Schema.Root{refs: refs, schema: %{"$ref" => url}}
    resolved = resolve(schema)
    ref = resolved.schema["$ref"]
    assert ref.(resolved) == {%ExJsonSchema.Schema.Root{resolved | schema: %{"type" => "boolean"}}, %{"type" => "boolean"}}
  end
end
