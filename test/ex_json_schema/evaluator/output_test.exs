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

  test "basic output retains boolean applicator branch locations" do
    compiled =
      Compiler.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "allOf" => [false, false]
        },
        validate_schema: false
      )

    assert %{"valid" => false, "errors" => errors} =
             Evaluator.validate(nil, compiled, output: :basic)

    assert Enum.map(errors, & &1["keywordLocation"]) == [
             "/allOf",
             "/allOf/0",
             "/allOf/1"
           ]
  end

  test "detailed recursively prunes successful leaves while verbose retains them" do
    compiled =
      Compiler.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "allOf" => [true, false]
        },
        validate_schema: false
      )

    detailed = Evaluator.validate(nil, compiled, output: :detailed)
    verbose = Evaluator.validate(nil, compiled, output: :verbose)

    refute Enum.any?(output_units(detailed), &(&1["keywordLocation"] == "/allOf/0"))
    assert Enum.any?(output_units(verbose), &(&1["keywordLocation"] == "/allOf/0"))
  end

  test "detailed output matches the Draft 2020-12 normative hierarchy" do
    compiled =
      Compiler.compile!(
        %{
          "$id" => "https://example.com/polygon",
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "$defs" => %{
            "point" => %{
              "type" => "object",
              "properties" => %{
                "x" => %{"type" => "number"},
                "y" => %{"type" => "number"}
              },
              "additionalProperties" => false,
              "required" => ["x", "y"]
            }
          },
          "type" => "array",
          "items" => %{"$ref" => "#/$defs/point"},
          "minItems" => 3
        },
        validate_schema: false
      )

    output =
      Evaluator.validate(
        [%{"x" => 2.5, "y" => 1.3}, %{"x" => 1, "z" => 6.7}],
        compiled,
        output: :detailed
      )

    assert %{"valid" => false, "errors" => errors} = output

    assert %{
             "absoluteKeywordLocation" => "https://example.com/polygon#/$defs/point",
             "errors" => reference_errors
           } = Enum.find(errors, &(&1["keywordLocation"] == "/items/$ref"))

    assert MapSet.new(Enum.map(reference_errors, & &1["keywordLocation"])) ==
             MapSet.new([
               "/items/$ref/required",
               "/items/$ref/additionalProperties"
             ])

    assert Enum.any?(errors, &(&1["keywordLocation"] == "/minItems"))
    refute Enum.any?(output_units(output), &(&1["keywordLocation"] == "/items"))
  end

  defp output_units(unit) do
    children = Map.get(unit, "errors", []) ++ Map.get(unit, "annotations", [])
    [unit | Enum.flat_map(children, &output_units/1)]
  end
end
