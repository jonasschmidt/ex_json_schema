defmodule ExJsonSchema.Compiler.CustomDialectTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator
  alias ExJsonSchema.Test.Support.TestHelpers

  @no_validation_uri "http://localhost:1234/draft2020-12/metaschema-no-validation.json"
  @optional_uri "http://localhost:1234/draft2020-12/metaschema-optional-vocabulary.json"

  test "activates only implemented vocabularies declared by a custom metaschema" do
    schema = %{
      "$schema" => @no_validation_uri,
      "properties" => %{
        "forbidden" => false,
        "number" => %{"minimum" => 10}
      }
    }

    compiled =
      Compiler.compile!(schema,
        resources: TestHelpers.remote_schemas(),
        validate_schema: false
      )

    refute Evaluator.valid?(%{"forbidden" => true}, compiled)
    assert Evaluator.valid?(%{"number" => 1}, compiled)
  end

  test "ignores unknown optional vocabularies" do
    schema = %{"$schema" => @optional_uri, "type" => "number"}

    compiled =
      Compiler.compile!(schema,
        resources: TestHelpers.remote_schemas(),
        validate_schema: false
      )

    assert Evaluator.valid?(1, compiled)
    refute Evaluator.valid?("one", compiled)
  end

  test "rejects unknown required vocabularies" do
    uri = "https://example.com/custom-meta"

    metaschema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => uri,
      "$vocabulary" => %{
        "https://json-schema.org/draft/2020-12/vocab/core" => true,
        "https://example.com/required-vocabulary" => true
      }
    }

    assert {:error,
            %CompileError{
              reason: :unsupported_vocabulary,
              details: %{
                vocabulary: "https://example.com/required-vocabulary"
              }
            }} =
             Compiler.compile(%{"$schema" => uri},
               resources: %{uri => metaschema},
               validate_schema: false
             )
  end
end
