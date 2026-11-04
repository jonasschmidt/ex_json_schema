defmodule ExJsonSchema.Evaluator.OutputTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Evaluator
  alias ExJsonSchema.Evaluator.Output
  alias ExJsonSchema.Evaluator.Result

  test "projects flag output without constructing public hierarchy" do
    result = Result.new(false, error: "failed")
    assert Output.project(result, :flag) == %{"valid" => false}
  end

  test "projects basic output as flattened string-keyed errors" do
    child =
      Result.new(false,
        kind: :assertion,
        keyword: "type",
        schema_location: %Location{
          resource: "https://example.com/schema",
          pointer: ["type"]
        },
        instance_location: %Location{pointer: ["value"]},
        error: "expected string"
      )

    root =
      Result.parent([child],
        schema_location: Location.root("https://example.com/schema")
      )

    assert %{
             "valid" => false,
             "keywordLocation" => "",
             "instanceLocation" => "",
             "errors" => [
               %{
                 "valid" => false,
                 "keywordLocation" => "/type",
                 "absoluteKeywordLocation" => "https://example.com/schema#/type",
                 "instanceLocation" => "/value",
                 "error" => "expected string"
               }
             ]
           } = Output.project(root, :basic)
  end

  test "detailed retains relevant children while verbose retains the complete tree" do
    failed = Result.new(false, keyword: "type", error: "expected string")
    annotation = Result.new(true, kind: :annotation, keyword: "title", annotation: "Example")
    root = Result.parent([failed, annotation])

    detailed = Output.project(root, :detailed)
    verbose = Output.project(root, :verbose)

    assert length(detailed["errors"]) == 1
    refute Map.has_key?(detailed, "annotations")
    assert length(verbose["errors"]) == 1
    assert length(verbose["annotations"]) == 1
    assert hd(verbose["annotations"])["annotation"] == "Example"
  end

  test "basic valid output flattens annotations" do
    annotation = Result.new(true, kind: :annotation, keyword: "default", annotation: 42)
    root = Result.parent([annotation])

    assert [unit] = Output.project(root, :basic)["annotations"]
    assert unit["annotation"] == 42
    assert unit["valid"]
  end

  test "basic compiled output retains annotations from evaluated child schemas" do
    compiled =
      Compiler.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "properties" => %{
            "value" => %{"title" => "Value", "type" => "integer"}
          }
        },
        validate_schema: false
      )

    assert %{"valid" => true, "annotations" => annotations} =
             Evaluator.validate(%{"value" => 1}, compiled, output: :basic)

    assert Enum.any?(annotations, fn annotation ->
             annotation["keywordLocation"] == "/properties/value/title" and
               annotation["annotation"] == "Value"
           end)
  end

  test "basic compiled output preserves applicator and assertion errors" do
    compiled =
      Compiler.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "type" => "array",
          "items" => %{"type" => "integer"}
        },
        validate_schema: false
      )

    assert %{
             "valid" => false,
             "errors" => [
               %{
                 "keywordLocation" => "/items",
                 "instanceLocation" => "",
                 "error" => "items failed"
               },
               %{
                 "keywordLocation" => "/items/type",
                 "instanceLocation" => "/1",
                 "error" => "value does not match type \"integer\""
               }
             ]
           } = Evaluator.validate([1, "two"], compiled, output: :basic)
  end

  test "basic contains output reports only the aggregate match-count failure" do
    for contains <- [%{"const" => 1}, %{"minimum" => 1}] do
      compiled =
        Compiler.compile!(
          %{
            "$schema" => "https://json-schema.org/draft/2020-12/schema",
            "contains" => contains
          },
          validate_schema: false
        )

      assert %{
               "valid" => false,
               "errors" => [
                 %{
                   "keywordLocation" => "/contains",
                   "instanceLocation" => "",
                   "error" => "array contains 0 matching items"
                 }
               ]
             } = Evaluator.validate([0, 0], compiled, output: :basic)
    end
  end

  test "basic output does not report rejected candidates when contains succeeds" do
    compiled =
      Compiler.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "contains" => %{"const" => 1},
          "minItems" => 3
        },
        validate_schema: false
      )

    assert %{"valid" => false, "errors" => errors} =
             Evaluator.validate([1, 0], compiled, output: :basic)

    assert Enum.map(errors, & &1["keywordLocation"]) == ["/minItems"]
  end
end
