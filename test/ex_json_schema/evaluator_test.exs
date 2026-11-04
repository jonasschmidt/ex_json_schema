defmodule ExJsonSchema.EvaluatorTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator

  test "boolean schemas have a flag fast path and all output formats remain correct" do
    true_schema = Compiler.compile!(true, validate_schema: false)
    false_schema = Compiler.compile!(false, validate_schema: false)

    assert Evaluator.valid?(%{"anything" => true}, true_schema)
    refute Evaluator.valid?(%{"anything" => true}, false_schema)

    assert Evaluator.validate(nil, true_schema, output: :flag) == %{"valid" => true}
    assert Evaluator.validate(nil, false_schema, output: :flag) == %{"valid" => false}

    for format <- [:basic, :detailed, :verbose] do
      assert Evaluator.validate(nil, true_schema, output: format)["valid"]
      refute Evaluator.validate(nil, false_schema, output: format)["valid"]
    end
  end
end
