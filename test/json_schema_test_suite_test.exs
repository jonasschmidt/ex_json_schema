defmodule ExJsonSchema.JsonSchemaTestSuiteTest.Helpers do
  use ExUnit.Case, async: true

  @schema_tests_path "test/JSON-Schema-Test-Suite/tests/draft4/"

  def schema_tests_path do
    @schema_tests_path
  end

  def schema_test_path(filename) do
    Path.join(schema_tests_path(), filename)
  end

  def load_schema_test(name) do
    (name <> ".json")
    |> schema_test_path
    |> File.read!()
    |> Poison.Parser.parse!()
  end
end

defmodule ExJsonSchema.JsonSchemaTestSuiteTest do
  use ExUnit.Case, async: true

  import ExJsonSchema.JsonSchemaTestSuiteTest.Helpers
  import ExJsonSchema.Validator, only: [valid?: 2]

  @tests Path.wildcard("#{schema_tests_path()}**/*.json")
         |> Enum.map(fn path ->
           path |> String.replace(schema_tests_path(), "") |> String.replace(".json", "")
         end)

  @ignored_tests %{
    "optional/format" => %{
      "validation of URIs" => true
    },
    "optional/ecmascript-regex" => %{
      "ECMA 262 regex non-compliance" => true,
      "ECMA 262 \\w matches everything but ascii letters" => true,
      "ECMA 262 \\S matches everything but ascii whitespace" => true,
      "ECMA 262 regex $ does not match trailing newline" => true,
      "ECMA 262 \\D matches everything but ascii digits" => true
    },
    "ref" => %{
      "ref overrides any sibling keywords" => ["ref valid, maxItems ignored"],
      "Recursive references between schemas" => ["valid tree", "invalid tree"],
      "Location-independent identifier" => true,
      "Location-independent identifier with base URI change in subschema" => true,
      "Location-independent identifier with absolute URI" => true
    }
  }

  Enum.each(@tests, fn feature ->
    fixture = load_schema_test(feature)

    Enum.each(fixture, fn fixture ->
      %{"description" => description, "schema" => schema, "tests" => tests} = fixture
      @schema schema
      Enum.each(tests, fn t ->
        @test t
        case @ignored_tests[feature] do
          true ->
            nil

          ignored_group ->
            case ignored_group[description] do
              true ->
                nil

              ignored_tests ->
                unless ignored_tests && Enum.member?(ignored_tests, @test["description"]) do
                  test "[#{feature}] #{description}: #{@test["description"]}" do
                    if @test["valid"] do
                      assert valid?(ExJsonSchema.Schema.resolve(@schema), @test["data"])
                    else
                      refute valid?(ExJsonSchema.Schema.resolve(@schema), @test["data"])
                    end
                  end
                end
            end
        end
      end)
    end)
  end)
end
