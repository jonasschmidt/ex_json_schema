defmodule ExJsonSchema.Evaluator.ContextTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Compiler.Dialect
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Evaluator.Context
  alias ExJsonSchema.Evaluator.Options

  test "tracks schema, instance, dialect, vocabulary, and policy transitions" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/root",
      "$defs" => %{
        "legacy" => %{
          "$schema" => "http://json-schema.org/draft-07/schema#",
          "$id" => "legacy"
        }
      }
    }

    compiled = Compiler.compile!(schema, validate_schema: false)

    context =
      Context.new(
        compiled,
        %Options{output: :flag, assert_formats?: true}
      )

    assert %Context{
             resource: "https://example.com/root",
             dialect: %Dialect{version: :"2020-12"},
             instance_location: instance_location,
             output_format: :flag,
             assert_formats?: true,
             collect_annotations?: false
           } = context

    assert instance_location == Location.root()

    context =
      context
      |> Context.at_schema(Location.root("https://example.com/legacy"))
      |> Context.at_schema_child("type")
      |> Context.at_instance_child("payload")
      |> Context.at_keyword("type")

    assert %Context{
             dialect: %Dialect{version: 7},
             schema_location: %Location{pointer: ["type", "type"]},
             instance_location: %Location{pointer: ["payload"]},
             evaluation_path: ["type"]
           } = context
  end

  test "dynamic scope does not duplicate the current resource" do
    compiled = Compiler.compile!(true, validate_schema: false)
    context = Context.new(compiled)

    context =
      context
      |> Context.push_dynamic_scope("")
      |> Context.push_dynamic_scope("")

    assert %Context{dynamic_scope: [""]} = context
  end
end
