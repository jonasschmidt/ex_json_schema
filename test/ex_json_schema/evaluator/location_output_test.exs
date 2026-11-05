defmodule ExJsonSchema.Evaluator.LocationOutputTest do
  use ExUnit.Case, async: true

  test "reports escaped instance and canonical keyword locations through remote refs" do
    external = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.com/external",
      "$anchor" => "integer",
      "type" => "integer"
    }

    compiled =
      ExJsonSchema.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "$id" => "https://example.com/root",
          "properties" => %{
            "a/b~c" => %{"$ref" => "external#integer"}
          }
        },
        resources: %{"https://example.com/external" => external},
        validate_schema: false
      )

    output = ExJsonSchema.validate(%{"a/b~c" => "one"}, compiled, output: :verbose)
    units = output_units(output)

    assert Enum.any?(units, fn unit ->
             unit["keywordLocation"] == "/properties/a~1b~0c/$ref" and
               unit["absoluteKeywordLocation"] ==
                 "https://example.com/root#/properties/a~1b~0c/$ref" and
               unit["instanceLocation"] == "/a~1b~0c"
           end)

    assert Enum.any?(units, fn unit ->
             unit["keywordLocation"] == "/properties/a~1b~0c/$ref/type" and
               unit["absoluteKeywordLocation"] == "https://example.com/external#/type"
           end)
  end

  test "fetched and dynamic targets retain canonical absolute locations" do
    compiled =
      ExJsonSchema.compile!(
        %{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "$id" => "https://example.com/root",
          "$defs" => %{
            "integer" => %{
              "$dynamicAnchor" => "value",
              "type" => "integer"
            }
          },
          "$dynamicRef" => "#value"
        },
        validate_schema: false
      )

    output = ExJsonSchema.validate("one", compiled, output: :verbose)

    assert Enum.any?(output_units(output), fn unit ->
             unit["absoluteKeywordLocation"] == "https://example.com/root#/$dynamicRef"
           end)

    fetched = ExJsonSchema.fetch_schema!(compiled, "#/$defs/integer")
    fetched_output = ExJsonSchema.validate("one", fetched, output: :basic)

    assert [error] = fetched_output["errors"]
    assert error["keywordLocation"] == "/$defs/integer/type"

    assert error["absoluteKeywordLocation"] ==
             "https://example.com/root#/$defs/integer/type"

    assert ExJsonSchema.validate(1, fetched, output: :basic) == %{
             "valid" => true,
             "keywordLocation" => "/$defs/integer",
             "absoluteKeywordLocation" => "https://example.com/root#/$defs/integer",
             "instanceLocation" => ""
           }
  end

  defp output_units(output) do
    children = Map.get(output, "errors", []) ++ Map.get(output, "annotations", [])
    [output | Enum.flat_map(children, &output_units/1)]
  end
end
