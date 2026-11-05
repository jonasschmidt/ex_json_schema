defmodule ExJsonSchema.Evaluator.FormatContentTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator

  test "older drafts assert formats by default" do
    compiled = compile(%{"format" => "date"})
    assert Evaluator.valid?("2026-11-02", compiled)
    refute Evaluator.valid?("not-a-date", compiled)
  end

  test "2020-12 annotates formats by default and supports an assertion override" do
    compiled =
      compile(%{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "format" => "date"
      })

    output = Evaluator.validate("not-a-date", compiled)
    assert output["valid"]
    assert [annotation] = output["annotations"]
    assert annotation["annotation"] == "date"

    refute Evaluator.valid?("not-a-date", compiled, assert_formats?: true)
  end

  test "uses explicit custom format validators and ignores unknown formats" do
    schema = %{"format" => "even"}

    compiled =
      Compiler.compile!(schema,
        formats: %{
          "even" => fn
            "2" -> :ok
            _value -> {:error, :odd}
          end
        },
        validate_schema: false
      )

    assert Evaluator.valid?("2", compiled)
    refute Evaluator.valid?("3", compiled)
    assert Evaluator.valid?("anything", compile(%{"format" => "unknown"}))
  end

  test "legacy draft 7 content assertions use only the explicit decoder" do
    schema = %{
      "$schema" => "http://json-schema.org/draft-07/schema#",
      "contentEncoding" => "base64",
      "contentMediaType" => "application/json"
    }

    compiled =
      Compiler.compile!(schema,
        content_decoder: fn
          "{}" -> {:ok, %{}}
          _other -> {:error, :invalid}
        end,
        validate_schema: false
      )

    assert Evaluator.valid?(Base.encode64("{}"), compiled)
    refute Evaluator.valid?(Base.encode64("not json"), compiled)
    refute Evaluator.valid?("not base64", compiled)
  end

  test "2020-12 content keywords annotate without invoking a decoder" do
    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "contentEncoding" => "base64",
      "contentMediaType" => "application/json",
      "contentSchema" => %{"type" => "object"}
    }

    compiled =
      Compiler.compile!(schema,
        content_decoder: fn _ -> flunk("decoder must not be called") end,
        validate_schema: false
      )

    output = Evaluator.validate("not base64 or json", compiled)
    assert output["valid"]
    assert length(output["annotations"]) == 3
  end

  defp compile(schema), do: Compiler.compile!(schema, validate_schema: false)
end
