defmodule ExJsonSchema.Evaluator.ResultTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Evaluator.Result

  test "constructs deterministic hierarchical nodes with canonical locations" do
    schema_location = %Location{
      resource: "https://example.com/schema",
      pointer: ["properties", "name", "type"]
    }

    child =
      Result.new(false,
        kind: :assertion,
        keyword: "type",
        schema_location: schema_location,
        instance_location: %Location{pointer: ["name"]},
        error: "value is not a string"
      )

    parent =
      Result.parent([child],
        kind: :schema,
        schema_location: Location.root("https://example.com/schema")
      )

    assert %Result{valid: false, children: [^child]} = parent

    assert %Result{
             keyword_location: "/properties/name/type",
             absolute_keyword_location: "https://example.com/schema#/properties/name/type",
             instance_location: "/name"
           } = child
  end

  test "combines evaluated locations from successful children only" do
    successful =
      Result.new(true,
        evaluated_properties: MapSet.new(["name"]),
        evaluated_items: MapSet.new([0])
      )

    failed =
      Result.new(false,
        evaluated_properties: MapSet.new(["secret"]),
        evaluated_items: MapSet.new([1])
      )

    result = Result.parent([successful, failed], valid: true)

    assert %Result{
             evaluated_properties: evaluated_properties,
             evaluated_items: evaluated_items
           } = result

    assert evaluated_properties == MapSet.new(["name"])
    assert evaluated_items == MapSet.new([0])
  end
end
