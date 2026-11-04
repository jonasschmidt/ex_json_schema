defmodule ExJsonSchemaTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.CompiledSchema

  test "top-level facade compiles, validates, and checks booleans payload-first" do
    assert {:ok, compiled} =
             ExJsonSchema.compile(%{"type" => "integer"}, validate_schema: false)

    assert %{"valid" => true} = ExJsonSchema.validate(1, compiled, output: :flag)
    assert %{"valid" => false} = ExJsonSchema.validate("one", compiled)
    assert ExJsonSchema.valid?(1, compiled)
    refute ExJsonSchema.valid?("one", compiled)
  end

  test "compile accepts only decoded object and boolean schemas" do
    assert {:ok, _compiled} = ExJsonSchema.compile(true)
    assert {:ok, _compiled} = ExJsonSchema.compile(%{})

    assert {:error, %CompileError{reason: :invalid_schema}} =
             ExJsonSchema.compile(~s({"type":"integer"}))
  end

  test "top-level fetch_schema returns reusable scoped handles" do
    compiled =
      ExJsonSchema.compile!(
        %{
          "$id" => "https://example.com/root",
          "definitions" => %{"integer" => %{"type" => "integer"}}
        },
        validate_schema: false
      )

    assert {:ok, integer} = ExJsonSchema.fetch_schema(compiled, "#/definitions/integer")
    assert ExJsonSchema.valid?(1, integer)
    refute ExJsonSchema.valid?("one", integer)

    assert %CompiledSchema{entrypoint: integer_entrypoint} = integer

    assert %CompiledSchema{entrypoint: ^integer_entrypoint} =
             ExJsonSchema.fetch_schema!(compiled, "#/definitions/integer")
  end

  test "metadata accessors do not expose graph structs" do
    compiled =
      ExJsonSchema.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "$id" => "https://example.com/root"
        },
        validate_schema: false
      )

    assert ExJsonSchema.dialect(compiled) ==
             "https://json-schema.org/draft/2020-12/schema"

    assert ExJsonSchema.schema_location(compiled) == "https://example.com/root"
    assert ExJsonSchema.resource_uris(compiled) == ["https://example.com/root"]
  end

  test "validation options reject unknown or malformed values" do
    compiled = ExJsonSchema.compile!(true)

    assert_raise ArgumentError, fn -> ExJsonSchema.validate(nil, compiled, output: :unknown) end
    assert_raise ArgumentError, fn -> ExJsonSchema.valid?(nil, compiled, unknown: true) end

    assert_raise ArgumentError, ~r/assert_formats\? must be a boolean/, fn ->
      ExJsonSchema.valid?(nil, compiled, assert_formats?: :default)
    end
  end
end
