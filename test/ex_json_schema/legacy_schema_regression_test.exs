defmodule ExJsonSchema.LegacySchemaRegressionTest do
  use ExUnit.Case, async: true

  # Preserves every historical config/schema test from master. Tests labeled
  # "replacement" assert the 1.0 contract that superseded a removed API;
  # "correction" records behavior intentionally changed for conformance.

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.ReferenceError

  @integer_url "http://localhost:1234/integer.json"
  @subschemas_url "http://localhost:1234/subSchemas.json"
  @subschema_url "http://localhost:1234/subschema.json"
  @subsubschema_url "http://localhost:1234/subsubschema.json"

  @resources %{
    @integer_url => %{"type" => "integer"},
    @subschemas_url => %{"integer" => %{"type" => "integer"}},
    @subschema_url => %{"foo" => %{"$ref" => "subsubschema.json#/foo"}},
    @subsubschema_url => %{"foo" => %{"type" => "integer"}}
  }

  def resolve(uri), do: Map.fetch(@resources, uri)

  test "legacy regression: raising an exception when trying to resolve a remote schema and no remote schema resolver is defined" do
    assert {:error,
            %CompileError{
              reason: :invalid_reference,
              details: %{
                reason: :resolver_not_configured,
                reference: "http://somewhere/schema.json"
              }
            }} =
             ExJsonSchema.compile(
               %{"$ref" => "http://somewhere/schema.json"},
               validate_schema: false
             )
  end

  test "legacy regression: defining a remote schema resolver with module and function name" do
    assert {:ok, compiled} =
             ExJsonSchema.compile(
               %{"$ref" => @integer_url},
               resolver: {__MODULE__, :resolve},
               validate_schema: false
             )

    assert ExJsonSchema.valid?(1, compiled)
    refute ExJsonSchema.valid?("one", compiled)
  end

  test "legacy regression: fails when trying to resolve something that is not a schema" do
    assert {:error, %CompileError{reason: :invalid_schema}} = ExJsonSchema.compile("foo")
  end

  test "legacy replacement: only resolves draft 4 schemata" do
    for dialect <- [
          "http://json-schema.org/draft-04/schema#",
          "http://json-schema.org/draft-06/schema#",
          "http://json-schema.org/draft-07/schema#",
          "https://json-schema.org/draft/2020-12/schema"
        ] do
      assert {:ok, _compiled} =
               ExJsonSchema.compile(%{"$schema" => dialect}, validate_schema: false)
    end

    assert {:error, %CompileError{reason: :unsupported_dialect}} =
             ExJsonSchema.compile(
               %{"$schema" => "http://json-schema.org/draft-03/schema#"},
               validate_schema: false
             )
  end

  test "legacy replacement: resolves a schema" do
    compiled =
      ExJsonSchema.compile!(
        %{"foo" => 1, "bar" => %{"baz" => 3}},
        validate_schema: false
      )

    assert ExJsonSchema.dialect(compiled) == "http://json-schema.org/draft-07/schema"
    assert ExJsonSchema.schema_location(compiled) == ""
  end

  test "legacy regression: accepts both http:// and https:// forms of the JSON Schema URI" do
    for draft <- ["draft-04", "draft-06", "draft-07"] do
      http =
        ExJsonSchema.compile!(
          %{"$schema" => "http://json-schema.org/#{draft}/schema#"},
          validate_schema: false
        )

      https =
        ExJsonSchema.compile!(
          %{"$schema" => "https://json-schema.org/#{draft}/schema#"},
          validate_schema: false
        )

      assert ExJsonSchema.dialect(http) == ExJsonSchema.dialect(https)
    end
  end

  test "legacy regression: schema is validated against its meta-schema" do
    for schema <- [
          %{"properties" => "foo"},
          %{
            "$schema" => "http://json-schema.org/draft-04/schema#",
            "properties" => "foo"
          },
          %{
            "$schema" => "http://json-schema.org/draft-06/schema#",
            "properties" => "foo"
          },
          %{
            "$schema" => "http://json-schema.org/draft-07/schema#",
            "properties" => "foo"
          }
        ] do
      assert {:error, %CompileError{reason: :invalid_schema}} =
               ExJsonSchema.compile(schema)
    end
  end

  test "legacy regression: resolving an absolute reference in a scoped schema" do
    compiled =
      ExJsonSchema.compile!(
        %{
          "id" => "http://foo.bar/schema.json#",
          "$ref" => @subschemas_url <> "#/integer"
        },
        resources: @resources,
        validate_schema: false
      )

    assert ExJsonSchema.valid?(1, compiled)
    refute ExJsonSchema.valid?("one", compiled)
  end

  test "legacy correction: resolves a reference" do
    compiled =
      ExJsonSchema.compile!(
        %{"foo" => %{"$ref" => "#/bar"}, "bar" => "baz"},
        validate_schema: false
      )

    assert {:error, %ReferenceError{reference: "#/bar"}} =
             ExJsonSchema.fetch_schema(compiled, "#/bar")
  end

  test "legacy regression: resolves a root reference" do
    compiled = ExJsonSchema.compile!(%{"$ref" => "#"}, validate_schema: false)
    assert ExJsonSchema.valid?("anything", compiled)
  end

  test "legacy regression: catches references with an invalid property in the path" do
    assert {:error, %CompileError{reason: :invalid_reference}} =
             ExJsonSchema.compile(%{"$ref" => "#/foo"}, validate_schema: false)
  end

  test "legacy regression: resolves a reference to a sibling definition" do
    compiled =
      ExJsonSchema.compile!(
        %{
          "$ref" => "#/definitions/foo",
          "definitions" => %{"foo" => %{"type" => "string"}}
        },
        validate_schema: false
      )

    assert ExJsonSchema.valid?("value", compiled)
    refute ExJsonSchema.valid?(1, compiled)
  end

  test "legacy regression: catches references with an invalid index in the path" do
    assert {:error, %CompileError{reason: :invalid_reference}} =
             ExJsonSchema.compile(
               %{"$ref" => "http://json-schema.org/schema#/1"},
               validate_schema: false
             )
  end

  test "legacy regression: catches invalid references" do
    assert {:error,
            %CompileError{
              reason: :invalid_reference,
              details: %{reference: "#definitions/foo"}
            }} =
             ExJsonSchema.compile(
               %{"$ref" => "#definitions/foo"},
               validate_schema: false
             )
  end

  test "legacy replacement: caching a resolved remote reference" do
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    resolver = fn @integer_url ->
      Agent.update(calls, &(&1 + 1))
      {:ok, %{"type" => "integer"}}
    end

    compiled =
      ExJsonSchema.compile!(
        %{"$ref" => @integer_url},
        resolver: resolver,
        validate_schema: false
      )

    assert ExJsonSchema.valid?(1, compiled)
    refute ExJsonSchema.valid?("one", compiled)
    assert ExJsonSchema.valid?(2, compiled)
    assert Agent.get(calls, & &1) == 1
  end

  test "legacy regression: resolving a remote schema" do
    compiled =
      ExJsonSchema.compile!(
        %{"$ref" => @integer_url},
        resources: @resources,
        validate_schema: false
      )

    assert ExJsonSchema.valid?(1, compiled)
    refute ExJsonSchema.valid?(true, compiled)
  end

  test "legacy replacement: using a previously cached remote schema" do
    compiled =
      ExJsonSchema.compile!(
        %{"$ref" => @integer_url},
        resources: %{@integer_url => %{"type" => "boolean"}},
        resolver: fn _uri -> flunk("preloaded resource must take precedence") end,
        validate_schema: false
      )

    assert ExJsonSchema.valid?(true, compiled)
    refute ExJsonSchema.valid?(1, compiled)
  end

  test "legacy regression: fetching a ref schema with an invalid reference" do
    compiled =
      ExJsonSchema.compile!(
        %{"foo" => 1, "bar" => %{"baz" => 3}},
        validate_schema: false
      )

    assert {:error, error} = ExJsonSchema.fetch_schema(compiled, "#/baz")
    assert %ReferenceError{reference: "#/baz"} = error

    assert_raise ReferenceError, fn ->
      ExJsonSchema.fetch_schema!(compiled, "#/baz")
    end
  end

  test "legacy replacement: fetching a ref schema with a path" do
    compiled =
      ExJsonSchema.compile!(
        %{"properties" => %{"foo" => %{"$ref" => @subschema_url <> "#/foo"}}},
        resources: @resources,
        validate_schema: false
      )

    fragment = ExJsonSchema.fetch_schema!(compiled, "#/properties/foo")
    assert ExJsonSchema.valid?(1, fragment)
    refute ExJsonSchema.valid?("one", fragment)
  end

  test "legacy replacement: fetching a ref schema with a URL" do
    compiled =
      ExJsonSchema.compile!(
        %{"$ref" => @subschema_url <> "#/foo"},
        resources: @resources,
        validate_schema: false
      )

    fragment = ExJsonSchema.fetch_schema!(compiled, @subschema_url <> "#/foo")
    assert ExJsonSchema.valid?(1, fragment)
    refute ExJsonSchema.valid?("one", fragment)
  end
end
