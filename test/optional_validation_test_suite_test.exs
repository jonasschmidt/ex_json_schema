defmodule ExJsonSchema.OptionalValidationTestSuiteTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator
  alias ExJsonSchema.Test.Support.OptionalSuiteManifest
  alias ExJsonSchema.Test.Support.TestHelpers

  @root "test/JSON-Schema-Test-Suite/tests/draft2020-12/optional"
  @resources TestHelpers.remote_schemas()
  @enabled OptionalSuiteManifest.enabled_validation()

  for suite <- @enabled do
    test "#{suite} optional validation suite" do
      path = Path.join(@root, unquote(suite) <> ".json")

      for test_case <- Jason.decode!(File.read!(path)),
          test <- test_case["tests"] do
        compiled =
          Compiler.compile!(test_case["schema"],
            resources: @resources,
            content_decoder: &Jason.decode/1,
            validate_schema: false
          )

        assert Evaluator.valid?(test["data"], compiled) == test["valid"],
               "#{test_case["description"]}: #{test["description"]}"
      end
    end
  end

  test "every optional suite is enabled or has a classified skip" do
    present =
      @root
      |> Path.join("**/*.json")
      |> Path.wildcard()
      |> Enum.map(fn path ->
        path
        |> Path.relative_to(@root)
        |> Path.rootname()
      end)
      |> MapSet.new()

    enabled = MapSet.new(OptionalSuiteManifest.enabled_paths())
    skipped = OptionalSuiteManifest.skipped() |> Map.keys() |> MapSet.new()

    assert MapSet.disjoint?(enabled, skipped)
    assert MapSet.union(enabled, skipped) == present

    assert Enum.all?(OptionalSuiteManifest.skipped(), fn
             {_suite, {classification, reason}} ->
               is_atom(classification) and is_binary(reason) and reason != ""
           end)
  end
end
