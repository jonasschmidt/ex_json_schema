defmodule ExJsonSchema.JsonSchemaTestSuiteTest.Helpers do
  use ExUnit.Case, async: true

  @schema_tests_path "test/JSON-Schema-Test-Suite/tests/draft4/"

  def schema_test_path(filename) do
    Path.join(@schema_tests_path, filename)
  end

  def load_schema_test(name) do
    name <> ".json"
    |> schema_test_path
    |> File.read!()
    |> Poison.Parser.parse!
  end
end

defmodule ExJsonSchema.JsonSchemaTestSuiteTest do
  use ExUnit.Case, async: true

  import ExJsonSchema.JsonSchemaTestSuiteTest.Helpers
  import ExJsonSchema.Validator, only: [valid?: 2]

  @tests ~w(
    additionalItems
    additionalProperties
    allOf
    anyOf
    default
    definitions
    dependencies
    enum
    items
    maximum
    maxItems
    maxLength
    maxProperties
    minimum
    minItems
    minLength
    minProperties
    multipleOf
    not
    oneOf
    pattern
    patternProperties
    properties
    ref
    refRemote
    required
    type
    uniqueItems
    optional/bignum
    optional/zeroTerminatedFloats
  )

  # MISSING TESTS
  #
  # optional/format

  Enum.each @tests, fn feature ->
    fixture = load_schema_test(feature)
    Enum.each fixture, fn fixture ->
      %{"description" => description, "schema" => schema, "tests" => tests} = fixture
      @schema schema
      Enum.each tests, fn t ->
        @test t
        test "[#{feature}] #{description}: #{@test["description"]}" do
          assert valid?(ExJsonSchema.Schema.resolve(@schema), @test["data"]) == @test["valid"]
        end
      end
    end
  end
end
