defmodule ExJsonSchema.ValidatorTest do
  use ExUnit.Case, async: true

  import ExJsonSchema.Validator

  alias ExJsonSchema.Validator.Error
  alias ExJsonSchema.Schema

  @schema_with_ref Schema.resolve(%{"properties" => %{"foo" => %{"$ref" => "http://localhost:8000/subschema.json#/foo"}}})

  test "empty schema is valid" do
    assert valid?(%{}, %{"foo" => "bar"}) == true
  end

  test "trying to validate a fragment with an invalid path" do
    assert validate(@schema_with_ref, "#/properties/bar", "foo") == {:error, :invalid_reference}
    assert valid?(@schema_with_ref, "#/properties/bar", 123) == {:error, :invalid_reference}
  end

  test "validating a fragment with a path" do
    assert validate(@schema_with_ref, "#/properties/foo", "foo") == {:error, [%Error{error: %Error.Type{actual: "String", expected: ["Integer"]}, path: "#"}]}
    assert valid?(@schema_with_ref, "#/properties/foo", 123)
  end

  test "validating a fragment with a partial schema" do
    fragment = Schema.get_fragment!(@schema_with_ref, "#/properties/foo")
    assert validate(@schema_with_ref, fragment, "foo") == {:error, [%Error{error: %Error.Type{actual: "String", expected: ["Integer"]}, path: "#"}]}
    assert valid?(@schema_with_ref, fragment, 123)
  end

  test "required properties are not validated when the data is not a map" do
    assert_validation_errors(
      %{"required" => ["foo"], "type" => "object"},
      "foo",
      [%Error{error: %Error.Type{expected: ["Object"], actual: "String"}, path: "#"}])
  end

  test "validation errors with a reference" do
    assert_validation_errors(
      %{"foo" => %{"type" => "object"}, "properties" => %{"bar" => %{"$ref" => "#/foo"}}},
      %{"bar" => "baz"},
      [%Error{error: %Error.Type{expected: ["Object"], actual: "String"}, path: "#/bar"}])
  end

  test "validation errors with a remote reference within a remote reference" do
    assert_validation_errors(
      %{"$ref" => "http://localhost:8000/subschema.json#/foo"},
      "foo",
      [%Error{error: %Error.Type{expected: ["Integer"], actual: "String"}, path: "#"}])
  end

  test "validation errors for not matching all of the schemata" do
    assert_validation_errors(
      %{"allOf" => [%{"type" => "number"}, %{"type" => "integer"}]},
      "foo",
      [%Error{error: %Error.AllOf{invalid_indices: [0, 1]}, path: "#"}])
  end

  test "validation errors for not matching any of the schemata" do
    assert_validation_errors(
      %{"anyOf" => [%{"type" => "number"}, %{"type" => "integer"}]},
      "foo",
      [%Error{error: %Error.AnyOf{}, path: "#"}])
  end

  test "validation errors for matching more than one of the schemata when exactly one should be matched" do
    assert_validation_errors(
      %{"oneOf" => [%{"type" => "number"}, %{"type" => "integer"}]},
      5,
      [%Error{error: %Error.OneOf{valid_indices: [0, 1]}, path: "#"}])
  end

  test "validation errors for matching none of the schemata when exactly one should be matched" do
    assert_validation_errors(
      %{"oneOf" => [%{"type" => "number"}, %{"type" => "integer"}]},
      "foo",
      [%Error{error: %Error.OneOf{valid_indices: []}, path: "#"}])
  end

  test "validation errors for matching a schema when it should not be matched" do
    assert_validation_errors(
      %{"not" => %{"type" => "object"}},
      %{},
      [%Error{error: %Error.Not{}, path: "#"}])
  end

  test "validation errors for a wrong type" do
    assert_validation_errors(
      %{"type" => ["integer", "number"]},
      "foo",
      [%Error{error: %Error.Type{expected: ["Integer", "Number"], actual: "String"}, path: "#"}])
  end

  test "validation errors for invalid properties" do
    assert_validation_errors(%{
        "properties" => %{"foo" => %{"type" => "string"}},
        "patternProperties" => %{"^b.*$" => %{"type" => "boolean"}},
        "additionalProperties" => false},
      %{"foo" => true, "bar" => true, "baz" => 1, "xyz" => false}, [
        %Error{error: %Error.Type{expected: ["String"], actual: "Boolean"}, path: "#/foo"},
        %Error{error: %Error.Type{expected: ["Boolean"], actual: "Integer"}, path: "#/baz"},
        %Error{error: %Error.AdditionalProperties{}, path: "#/xyz"}])
  end

  test "validation errors for invalid additional properties" do
    assert_validation_errors(%{
        "properties" => %{"foo" => %{"type" => "string"}},
        "additionalProperties" => %{"type" => "boolean"}},
      %{"foo" => "bar", "bar" => "baz"},
      [%Error{error: %Error.Type{expected: ["Boolean"], actual: "String"}, path: "#/bar"}])
  end

  test "validation errors for minimum properties" do
    assert_validation_errors(
      %{"minProperties" => 2},
      %{"foo" => 1},
      [%Error{error: %Error.MinProperties{expected: 2, actual: 1}, path: "#"}])
  end

  test "validation errors for maximum properties" do
    assert_validation_errors(
      %{"maxProperties" => 1},
      %{"foo" => 1, "bar" => 2},
      [%Error{error: %Error.MaxProperties{expected: 1, actual: 2}, path: "#"}])
  end

  test "validation errors for missing required properties" do
    assert_validation_errors(
      %{"required" => ["foo", "bar", "baz"]},
      %{"foo" => 1},
      [%Error{error: %Error.Required{missing: ["bar", "baz"]}, path: "#"}])
  end

  test "validation errors for dependent properties" do
    assert_validation_errors(
      %{"dependencies" => %{"foo" => ["bar", "baz", "qux"]}},
      %{"foo" => 1, "bar" => 2},
      [%Error{error: %Error.Dependencies{property: "foo", missing: ["baz", "qux"]}, path: "#"}])
  end

  test "validation errors for schema dependencies" do
    assert_validation_errors(
      %{"dependencies" => %{"foo" => %{"properties" => %{"bar" => %{"type" => "boolean"}}}}},
      %{"foo" => 1, "bar" => 2},
      [%Error{error: %Error.Type{expected: ["Boolean"], actual: "Integer"}, path: "#/bar"}])
  end

  test "validation errors for invalid items" do
    assert_validation_errors(
      %{"items" => %{"type" => "string"}},
      ["foo", "bar", 1, %{}], [
        %Error{error: %Error.Type{expected: ["String"], actual: "Integer"}, path: "#/2"},
        %Error{error: %Error.Type{expected: ["String"], actual: "Object"}, path: "#/3"}])
  end

  test "validation errors for an invalid item with a list of item schemata and an invalid additional item" do
    assert_validation_errors(%{
        "items" => [%{"type" => "string"}, %{"type" => "integer"}, %{"type" => "integer"}],
        "additionalItems" => %{"type" => "boolean"}},
      [%{}, 1, "foo", true, 2.2], [
        %Error{error: %Error.Type{expected: ["String"], actual: "Object"}, path: "#/0"},
        %Error{error: %Error.Type{expected: ["Integer"], actual: "String"}, path: "#/2"},
        %Error{error: %Error.Type{expected: ["Boolean"], actual: "Number"}, path: "#/4"}])
  end

  test "validation errors for disallowed additional items" do
    assert_validation_errors(
      %{"items" => [%{"type" => "boolean"}, %{"type" => "string"}], "additionalItems" => false},
      [true, "foo", true, "bar", 5],
      [%Error{error: %Error.AdditionalItems{additional_indices: 2..4}, path: "#"}])
  end

  test "validation errors for minimum items" do
    assert_validation_errors(
      %{"minItems" => 2},
      ["foo"],
      [%Error{error: %Error.MinItems{expected: 2, actual: 1}, path: "#"}])
  end

  test "validation errors for maximum items" do
    assert_validation_errors(
      %{"maxItems" => 2},
      ["foo", "bar", "baz"],
      [%Error{error: %Error.MaxItems{expected: 2, actual: 3}, path: "#"}])
  end

  test "validation errors for non-unique items" do
    assert_validation_errors(
      %{"uniqueItems" => true},
      [1, 2, 3, 3],
      [%Error{error: %Error.UniqueItems{}, path: "#"}])
  end

  test "validation errors for value not allowed in enum" do
    assert_validation_errors(
      %{"enum" => ["foo", "bar"]},
      %{"baz" => 1},
      [%Error{error: %Error.Enum{}, path: "#"}])
  end

  test "validation errors for minimum values" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"minimum" => 2}, "bar" => %{"minimum" => 2, "exclusiveMinimum" => true}}},
      %{"foo" => 1, "bar" => 2}, [
        %Error{error: %Error.Minimum{expected: 2, exclusive?: true}, path: "#/bar"},
        %Error{error: %Error.Minimum{expected: 2, exclusive?: false}, path: "#/foo"}])
  end

  test "validation errors for maximum values" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"maximum" => 2}, "bar" => %{"maximum" => 2, "exclusiveMaximum" => true}}},
      %{"foo" => 3, "bar" => 2}, [
        %Error{error: %Error.Maximum{expected: 2, exclusive?: true}, path: "#/bar"},
        %Error{error: %Error.Maximum{expected: 2, exclusive?: false}, path: "#/foo"}])
  end

  test "validation errors for multiples of" do
    assert_validation_errors(
      %{"multipleOf" => 2},
      5,
      [%Error{error: %Error.MultipleOf{expected: 2}, path: "#"}])
  end

  test "validation errors for minimum length" do
    assert_validation_errors(
      %{"minLength" => 4},
      "foo",
      [%Error{error: %Error.MinLength{expected: 4, actual: 3}, path: "#"}])
  end

  test "validation errors for maximum length" do
    assert_validation_errors(
      %{"maxLength" => 2},
      "foo",
      [%Error{error: %Error.MaxLength{expected: 2, actual: 3}, path: "#"}])
  end

  test "validation errors for pattern mismatch" do
    assert_validation_errors(
      %{"pattern" => "^b..$"},
      "foo",
      [%Error{error: %Error.Pattern{expected: "^b..$"}, path: "#"}])
  end

  test "validation errors for nested objects" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"items" => %{"properties" => %{"bar" => %{"type" => "integer"}}}}}},
      %{"foo" => [%{"bar" => 1}, %{"bar" => "baz"}]},
      [%Error{error: %Error.Type{expected: ["Integer"], actual: "String"}, path: "#/foo/1/bar"}])
  end

  test "format validation always succeeds for non-string values" do
    assert :ok == validate(%{"format" => "date-time"}, false)
  end

  test "validation errors for date-time format" do
    assert_validation_errors(
      %{"format" => "date-time"},
      "2012-12-12 12:12:12",
      [%Error{error: %Error.Format{expected: "date-time"}, path: "#"}])
  end

  test "validation errors for email format" do
    assert_validation_errors(
      %{"format" => "email"},
      "foo@",
      [%Error{error: %Error.Format{expected: "email"}, path: "#"}])
  end

  test "validation errors for hostname format" do
    assert_validation_errors(
      %{"format" => "hostname"},
      "foo-bar",
      [%Error{error: %Error.Format{expected: "hostname"}, path: "#"}])
  end

  test "validation errors for ipv4 format" do
    assert_validation_errors(
      %{"format" => "ipv4"},
      "12.12.12",
      [%Error{error: %Error.Format{expected: "ipv4"}, path: "#"}])
  end

  test "validation errors for ipv6 format" do
    assert_validation_errors(
      %{"format" => "ipv6"},
      "12:12:12",
      [%Error{error: %Error.Format{expected: "ipv6"}, path: "#"}])
  end

  defp assert_validation_errors(schema, data, expected_errors) do
    {:error, errors} = validate(schema, data)
    assert errors == expected_errors
  end
end
