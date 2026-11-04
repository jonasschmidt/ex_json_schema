defmodule ExJsonSchema.OutputTestSuiteTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator
  alias ExJsonSchema.Test.Support.TestHelpers

  @root "test/JSON-Schema-Test-Suite/output-tests/draft2020-12"
  @output_schema_uri "https://json-schema.org/draft/2020-12/output/schema"
  @output_schema @root |> Path.join("output-schema.json") |> File.read!() |> Jason.decode!()
  @resources Map.put(TestHelpers.remote_schemas(), @output_schema_uri, @output_schema)

  test "draft 2020-12 basic content output passes upstream output constraints" do
    for path <- Path.wildcard(Path.join(@root, "content/*.json")),
        test_case <- Jason.decode!(File.read!(path)),
        test <- test_case["tests"],
        {format, expected_schema} <- test["output"] || %{} do
      schema = Compiler.compile!(test_case["schema"], resources: @resources, validate_schema: false)
      output = Evaluator.validate(test["data"], schema, output: String.to_existing_atom(format))

      expected =
        expected_schema
        |> Map.put_new("$schema", "https://json-schema.org/draft/2020-12/schema")
        |> Compiler.compile!(
          resources: @resources,
          validate_schema: false
        )

      assert Evaluator.valid?(output, expected),
             "#{Path.basename(path)} / #{test_case["description"]} / #{test["description"]}"
    end
  end

  test "project-owned flag, detailed, and verbose trees conform to the output schema" do
    schema =
      Compiler.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "$id" => "https://example.com/applicator",
          "anyOf" => [
            %{"type" => "integer", "title" => "Integer"},
            %{"type" => "string", "title" => "String"}
          ]
        },
        validate_schema: false
      )

    output_schema =
      Compiler.compile!(@output_schema,
        resources: @resources,
        validate_schema: false
      )

    for instance <- [1, true],
        format <- [:flag, :detailed, :verbose] do
      output = Evaluator.validate(instance, schema, output: format)
      assert Evaluator.valid?(output, output_schema)
    end
  end
end
