defmodule ExJsonSchema.JsonSchemaDraft4TestSuiteTest.Helpers do
  use ExUnit.Case, async: true

  @schema_tests_path "test/JSON-Schema-Test-Suite/tests/draft4/"

  def schema_tests_path do
    @schema_tests_path
  end

  def schema_test_path(filename) do
    Path.join(schema_tests_path(), filename)
  end

  def load_schema_test(name) do
    name <> ".json"
    |> schema_test_path
    |> File.read!
    |> Poison.Parser.parse!
  end
end

defmodule ExJsonSchema.JsonSchemaDraft4TestSuiteTest do
  use ExUnit.Case, async: true

  import ExJsonSchema.JsonSchemaDraft4TestSuiteTest.Helpers
  import ExJsonSchema.Validator, only: [valid?: 2]

  @tests Path.wildcard("#{schema_tests_path()}**/*.json")
    |> Enum.map(fn path ->
      path |> String.replace(schema_tests_path(), "") |> String.replace(".json", "")
    end)

  @ignored_tests %{
    "optional/ecmascript-regex" => %{
      "ECMA 262 regex non-compliance" => true
    },
    "optional/format" => %{
      "validation of URIs" => true
    },

    # FIXME:
    # The below are genuine errors and ways in which we don't yet fully support draft04
    "ref" => %{
      "Recursive references between schemas" => true,
      "ref overrides any sibling keywords" => ["ref valid, maxItems ignored"]
    },
    "refRemote" => %{
      "base URI change - change folder" => true,
      "base URI change - change folder in subschema" => true,
      "root ref in remote ref" => true
    }
  }

  Enum.each @tests, fn feature ->
    fixture = load_schema_test(feature)
    Enum.each fixture, fn fixture ->
      %{"description" => description, "schema" => schema, "tests" => tests} = fixture
      @schema schema
      Enum.each tests, fn t ->
        @test t
        case @ignored_tests[feature] do
          true -> nil
          ignored_group ->
            case ignored_group[description] do
              true -> nil
              ignored_tests ->
                unless ignored_tests && Enum.member?(ignored_tests, @test["description"]) do
                  test "[#{feature}] #{description}: #{@test["description"]}" do
                    assert valid?(ExJsonSchema.Schema.resolve(@schema), @test["data"]) == @test["valid"]
                  end
                end
            end
        end
      end
    end
  end
end
