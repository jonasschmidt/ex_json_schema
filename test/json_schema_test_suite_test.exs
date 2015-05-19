defmodule ExJsonSchema.JsonSchemaTestSuiteTest.Helpers do
  use ExUnit.Case, async: true

  @schema_fixtures_path "test/fixtures/JSON-Schema-Test-Suite/tests/draft4/"

  def schema_fixture_path(filename) do
    Path.join(@schema_fixtures_path, filename)
  end

  def load_schema_fixture(name) do
    name <> ".json"
    |> schema_fixture_path
    |> File.read!()
    |> Poison.Parser.parse!
  end
end

defmodule ExJsonSchema.JsonSchemaTestSuiteTest do
  use ExUnit.Case, async: true

  import ExJsonSchema.JsonSchemaTestSuiteTest.Helpers
  import ExJsonSchema.Validator, only: [valid?: 2]

  @tests ~w(dependencies items maximum maxItems minimum minItems required type)

  Enum.each @tests, fn feature ->
    fixture = load_schema_fixture(feature)
    Enum.each fixture, fn fixture ->
      %{"description" => description, "schema" => schema, "tests" => tests} = fixture
      @schema schema
      Enum.each tests, fn t ->
        @test t
        test "[#{feature}] #{description}: #{@test["description"]}" do
          assert valid?(@schema, @test["data"]) == @test["valid"]
        end
      end
    end
  end
end
