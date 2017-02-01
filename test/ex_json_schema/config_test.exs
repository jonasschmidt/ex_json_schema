defmodule ExJsonSchema.ConfigTest do
  use ExUnit.Case

  import ExJsonSchema.Schema, only: [resolve: 1]

  @schema %{"$ref" => "http://somewhere/schema.json"}

  def test_resolver(url), do: %{"foo" => url}

  setup context do
    resolver = Application.get_env(:ex_json_schema, :remote_schema_resolver)
    on_exit fn -> Application.put_env(:ex_json_schema, :remote_schema_resolver, resolver) end
    Map.put(context, :resolver, resolver)
  end

  test "raising an exception when trying to resolve a remote schema and no remote schema resolver is defined" do
    Application.put_env(:ex_json_schema, :remote_schema_resolver, nil)
    assert_raise ExJsonSchema.Schema.UndefinedRemoteSchemaResolverError, fn -> resolve(@schema) end
  end

  test "defining a remote schema resolver with module and function name" do
    Application.put_env(:ex_json_schema, :remote_schema_resolver, {ExJsonSchema.ConfigTest, :test_resolver})
    assert resolve(@schema).refs == %{"http://somewhere/schema.json" => %{"foo" => "http://somewhere/schema.json"}}
  end
end
