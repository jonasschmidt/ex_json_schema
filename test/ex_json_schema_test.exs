defmodule ExJsonSchemaTest do
  use ExUnit.Case, async: true

  import ExJsonSchema.Validator, only: [valid?: 2]

  test "empty schema is valid" do
    assert valid?(%{}, %{"foo" => "bar"}) == true
  end

  test "ignores unknown schema rules" do
    schema = %{"unknown" => "something"}
    assert valid?(schema, %{"foo" => "bar"})
  end

  test "is not invalid if a property is not there" do
    schema = %{"properties" => %{"foo" => %{"type" => "string"}}}
    assert valid?(schema, %{}) == true
  end

  test "validates a string property" do
    schema = %{"properties" => %{"foo" => %{"type" => "string"}}}
    assert valid?(schema, %{"foo" => "bar"}) == true
    assert valid?(schema, %{"foo" => 1}) == false
  end

  test "validates an integer property" do
    schema = %{"properties" => %{"foo" => %{"type" => "integer"}}}
    assert valid?(schema, %{"foo" => 1}) == true
    assert valid?(schema, %{"foo" => "bar"}) == false
    assert valid?(schema, %{"foo" => 1.0}) == false
  end

  test "validates a float property" do
    schema = %{"properties" => %{"foo" => %{"type" => "number"}}}
    assert valid?(schema, %{"foo" => 1.0}) == true
    assert valid?(schema, %{"foo" => 1}) == true
    assert valid?(schema, %{"foo" => "bar"}) == false
  end

  test "validates an array" do
    schema = %{"properties" => %{"foo" => %{"type" => "array", "items" => %{"type" => "integer"}, "minItems" => 2, "maxItems" => 3}}}
    assert valid?(schema, %{"foo" => [1, 2, 3]}) == true
    assert valid?(schema, %{"foo" => [1, 2, 3, 4]}) == false
    assert valid?(schema, %{"foo" => [1]}) == false
    assert valid?(schema, %{"foo" => ["foo", "bar", "baz"]}) == false
    assert valid?(schema, %{"foo" => 1}) == false
  end

  test "validates a minimum value" do
    schema = %{"properties" => %{"foo" => %{"type" => "number", "minimum" => 2}}}
    assert valid?(schema, %{"foo" => 2}) == true
    assert valid?(schema, %{"foo" => 2.0}) == true
    assert valid?(schema, %{"foo" => 1.9}) == false
    assert valid?(schema, %{"foo" => 1}) == false
  end

  test "validates a minimum value with exclusive minimum" do
    schema = %{"properties" => %{"foo" => %{"type" => "number", "minimum" => 2, "exclusiveMinimum" => true}}}
    assert valid?(schema, %{"foo" => 2.1}) == true
    assert valid?(schema, %{"foo" => 2}) == false
    assert valid?(schema, %{"foo" => 2.0}) == false
  end

  test "validates a maximum value" do
    schema = %{"properties" => %{"foo" => %{"type" => "number", "maximum" => 2}}}
    assert valid?(schema, %{"foo" => 2}) == true
    assert valid?(schema, %{"foo" => 2.0}) == true
    assert valid?(schema, %{"foo" => 2.1}) == false
    assert valid?(schema, %{"foo" => 3}) == false
  end

  test "validates a maximum value with exclusive maximum" do
    schema = %{"properties" => %{"foo" => %{"type" => "number", "maximum" => 2, "exclusiveMaximum" => true}}}
    assert valid?(schema, %{"foo" => 1.9}) == true
    assert valid?(schema, %{"foo" => 2}) == false
    assert valid?(schema, %{"foo" => 2.0}) == false
  end

  test "validates a required property" do
    schema = %{"required" => "foo"}
    assert valid?(schema, %{"foo" => 1}) == true
    assert valid?(schema, %{"bar" => 2}) == false
  end

  test "validates multiple required properties" do
    schema = %{"required" => ["foo", "bar"]}
    assert valid?(schema, %{"foo" => 1, "bar" => 2}) == true
    assert valid?(schema, %{"foo" => 1}) == false
    assert valid?(schema, %{"baz" => 3}) == false
  end

  test "checks dependent property" do
    schema = %{"dependencies" => %{"foo" => "bar"}}
    assert valid?(schema, %{"foo" => 1, "bar" => 2}) == true
    assert valid?(schema, %{"foo" => 1, "baz" => 3}) == false
  end

  test "checks dependent properties" do
    schema = %{"dependencies" => %{"foo" => ["bar", "baz"]}}
    assert valid?(schema, %{"foo" => 1, "bar" => 2, "baz" => 3}) == true
    assert valid?(schema, %{"foo" => 1, "bar" => 2}) == false
  end

  test "checks schema for dependent property" do
    schema = %{"dependencies" => %{"foo" => %{"required" => "bar"}}}
    assert valid?(schema, %{"foo" => 1, "bar" => 2}) == true
    assert valid?(schema, %{"foo" => 1, "baz" => 3}) == false
  end

  test "checks multiple requirements" do
    schema = %{"required" => "foo", "dependencies" => %{"foo" => "bar"}}
    assert valid?(schema, %{"foo" => 1, "bar" => 2}) == true
    assert valid?(schema, %{"foo" => 1, "baz" => 3}) == false
  end
end
