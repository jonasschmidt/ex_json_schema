defmodule ExJsonSchema.OptionalFormatTestSuiteTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator
  alias ExJsonSchema.Test.Support.OptionalSuiteManifest

  @root "test/JSON-Schema-Test-Suite/tests/draft2020-12/optional/format"
  @enabled OptionalSuiteManifest.enabled_formats()

  for format <- @enabled do
    test "#{format} optional format suite" do
      path = Path.join(@root, unquote(format) <> ".json")

      for test_case <- Jason.decode!(File.read!(path)),
          test <- test_case["tests"] do
        schema =
          test_case["schema"]
          |> Map.put_new("$schema", "https://json-schema.org/draft/2020-12/schema")
          |> Compiler.compile!(validate_schema: false)

        assert Evaluator.valid?(test["data"], schema, assert_formats?: true) == test["valid"],
               "#{test_case["description"]}: #{test["description"]}"
      end
    end
  end
end
