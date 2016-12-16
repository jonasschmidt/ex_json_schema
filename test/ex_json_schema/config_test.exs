defmodule ExJsonSchema.ConfigTest do
  use ExUnit.Case

  import ExJsonSchema.Schema, only: [resolve: 1]

  test "raising an exception when trying to resolve a remote schema and no remote schema resolver is defined" do
    resolver = Application.get_env(:ex_json_schema, :remote_schema_resolver)
    Application.put_env(:ex_json_schema, :remote_schema_resolver, nil)
    schema = %{"$ref" => "http://somewhere/schema.json"}
    assert_raise ExJsonSchema.Schema.UndefinedRemoteSchemaResolverError, fn -> resolve(schema) end
    Application.put_env(:ex_json_schema, :remote_schema_resolver, resolver)
  end
end
