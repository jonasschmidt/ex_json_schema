defmodule ExJsonSchema.Evaluator.NumberTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator
  alias ExJsonSchema.Evaluator.Number

  @multiple_cases [
    {0, 7, true},
    {12, 3, true},
    {12, 5, false},
    {-12, 3, true},
    {1, 0.1, true},
    {1, 0.3, false},
    {1.5, 0.5, true},
    {-1.5, 0.5, true},
    {-0.0, 0.1, true},
    {0.3, 0.1, true},
    {0.30000000000000004, 0.1, false},
    {4.02, 0.01, true},
    {4.021, 0.01, false},
    {1.0e308, 0.5, true},
    {1.0e308, 3, false},
    {1.0e-300, 1.0e-301, true},
    {1.0e-300, 3.0e-301, false},
    {5.0e-324, 5.0e-324, true},
    {1.7976931348623157e308, 1.7976931348623157e308, true},
    {123_456_789_012_345_678_901_234_567_890, 10, true},
    {123_456_789_012_345_678_901_234_567_891, 10, false}
  ]

  test "calculates exact divisibility across native numeric representations" do
    for {number, divisor, expected} <- @multiple_cases do
      assert Number.multiple_of?(number, divisor) == expected,
             "expected #{inspect(number)} multipleOf #{inspect(divisor)} to be #{expected}"
    end
  end

  test "rejects non-positive and non-numeric divisors" do
    refute Number.multiple_of?(1, 0)
    refute Number.multiple_of?(1, 0.0)
    refute Number.multiple_of?(1, -1)
    refute Number.multiple_of?(1, "1")
    refute Number.multiple_of?("1", 1)
  end

  test "uses identical arithmetic in flag, basic, and full evaluation paths" do
    for {number, divisor, expected} <- @multiple_cases do
      compiled =
        Compiler.compile!(
          %{
            "$schema" => "https://json-schema.org/draft/2020-12/schema",
            "multipleOf" => divisor
          },
          validate_schema: false
        )

      assert Evaluator.valid?(number, compiled) == expected
      assert Evaluator.validate(number, compiled)["valid"] == expected
      assert Evaluator.validate(number, compiled, output: :verbose)["valid"] == expected
    end
  end
end
