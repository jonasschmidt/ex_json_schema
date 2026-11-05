defmodule ExJsonSchema.Evaluator.DispatcherTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Compiler.Dialect
  alias ExJsonSchema.Compiler.EvaluationPlan
  alias ExJsonSchema.Evaluator.Context
  alias ExJsonSchema.Evaluator.Dispatcher

  test "orders references, ordinary keywords, and unevaluated keywords in phases" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/root",
      "$ref" => "#",
      "type" => "object",
      "properties" => %{},
      "unevaluatedProperties" => false
    }

    context =
      schema
      |> Compiler.compile!(validate_schema: false)
      |> Context.new()

    assert %Context{keyword_plan: keyword_plan} = context

    assert %EvaluationPlan{
             identifiers: ["$schema", "$id", "$ref"],
             ordinary: ["type", "properties"],
             unevaluated: ["unevaluatedProperties"]
           } = phases = Dispatcher.phases(context, schema)

    assert phases == keyword_plan
  end

  test "omitted vocabularies omit their keyword dispatch" do
    schema = %{"type" => "integer", "properties" => %{}}

    context =
      true
      |> Compiler.compile!(validate_schema: false)
      |> Context.new()

    applicator = "https://json-schema.org/draft/2020-12/vocab/applicator"

    assert %Context{dialect: %Dialect{} = dialect} = context

    context = %Context{
      context
      | dialect: %Dialect{dialect | version: :"2020-12"},
        vocabularies: MapSet.new([applicator])
    }

    assert %EvaluationPlan{ordinary: ["properties"]} = Dispatcher.phases(context, schema)
  end
end
