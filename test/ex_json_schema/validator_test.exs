defmodule ExJsonSchema.ValidatorTest do
  use ExUnit.Case, async: true

  import ExJsonSchema.Validator, only: [validate: 2, valid?: 2]

  test "empty schema is valid" do
    assert valid?(%{}, %{"foo" => "bar"}) == true
  end

  test "required properties are not validated when the data is not a map" do
    assert_validation_errors(
      %{"required" => ["foo"], "type" => "object"},
      "foo",
      [{"Type mismatch. Expected Object but got String.", "#"}])
  end

  test "validation errors with a reference" do
    assert_validation_errors(
      %{"foo" => %{"type" => "object"}, "properties" => %{"bar" => %{"$ref" => "#/foo"}}},
      %{"bar" => "baz"},
      [{"Type mismatch. Expected Object but got String.", "#/bar"}])
  end

  test "validation errors with a remote reference within a remote reference" do
    assert_validation_errors(
      %{"$ref" => "http://localhost:8000/subschema.json#/foo"},
      "foo",
      [{"Type mismatch. Expected Integer but got String.", "#"}])
  end

  test "validation errors for not matching all of the schemata" do
    assert_validation_errors(
      %{"allOf" => [%{"type" => "number"}, %{"type" => "integer"}]},
      "foo",
      [{"Expected all of the schemata to match, but the schemata at the following indexes did not: 0, 1.", "#"}])
  end

  test "validation errors for not matching any of the schemata" do
    assert_validation_errors(
      %{"anyOf" => [%{"type" => "number"}, %{"type" => "integer"}]},
      "foo",
      [{"Expected any of the schemata to match but none did.", "#"}])
  end

  test "validation errors for matching more than one of the schemata when exactly one should be matched" do
    assert_validation_errors(
      %{"oneOf" => [%{"type" => "number"}, %{"type" => "integer"}]},
      5,
      [{"Expected exactly one of the schemata to match, but the schemata at the following indexes did: 0, 1.", "#"}])
  end

  test "validation errors for matching none of the schemata when exactly one should be matched" do
    assert_validation_errors(
      %{"oneOf" => [%{"type" => "number"}, %{"type" => "integer"}]},
      "foo",
      [{"Expected exactly one of the schemata to match, but none of them did.", "#"}])
  end

  test "validation errors for matching a schema when it should not be matched" do
    assert_validation_errors(
      %{"not" => %{"type" => "object"}},
      %{},
      [{"Expected schema not to match but it did.", "#"}])
  end

  test "validation errors for a wrong type" do
    assert_validation_errors(
      %{"type" => ["integer", "number"]},
      "foo",
      [{"Type mismatch. Expected Integer, Number but got String.", "#"}])
  end

  test "validation errors for invalid properties" do
    assert_validation_errors(%{
        "properties" => %{"foo" => %{"type" => "string"}},
        "patternProperties" => %{"^b.*$" => %{"type" => "boolean"}},
        "additionalProperties" => false},
      %{"foo" => true, "bar" => true, "baz" => 1, "xyz" => false}, [
        {"Type mismatch. Expected String but got Boolean.", "#/foo"},
        {"Type mismatch. Expected Boolean but got Integer.", "#/baz"},
        {"Schema does not allow additional properties.", "#/xyz"}])
  end

  test "validation errors for invalid additional properties" do
    assert_validation_errors(%{
        "properties" => %{"foo" => %{"type" => "string"}},
        "additionalProperties" => %{"type" => "boolean"}},
      %{"foo" => "bar", "bar" => "baz"},
      [{"Type mismatch. Expected Boolean but got String.", "#/bar"}])
  end

  test "validation errors for minimum properties" do
    assert_validation_errors(
      %{"minProperties" => 2},
      %{"foo" => 1},
      [{"Expected a minimum of 2 properties but got 1", "#"}])
  end

  test "validation errors for maximum properties" do
    assert_validation_errors(
      %{"maxProperties" => 1},
      %{"foo" => 1, "bar" => 2},
      [{"Expected a maximum of 1 properties but got 2", "#"}])
  end

  test "validation errors for missing required properties" do
    assert_validation_errors(
      %{"required" => ["foo", "bar", "baz"]},
      %{"foo" => 1}, [
        {"Required property bar was not present.", "#"},
        {"Required property baz was not present.", "#"}])
  end

  test "validation errors for dependent properties" do
    assert_validation_errors(
      %{"dependencies" => %{"foo" => ["bar", "baz"]}},
      %{"foo" => 1, "bar" => 2},
      [{"Property foo depends on baz to be present but it was not.", "#"}])
  end

  test "validation errors for schema dependencies" do
    assert_validation_errors(
      %{"dependencies" => %{"foo" => %{"properties" => %{"bar" => %{"type" => "boolean"}}}}},
      %{"foo" => 1, "bar" => 2},
      [{"Type mismatch. Expected Boolean but got Integer.", "#/bar"}])
  end

  test "validation errors for invalid items" do
    assert_validation_errors(
      %{"items" => %{"type" => "string"}},
      ["foo", "bar", 1, %{}, {"foo", "bar"}], [
        {"Type mismatch. Expected String but got Integer.", "#/2"},
        {"Type mismatch. Expected String but got Object.", "#/3"},
        {"Type mismatch. Expected String but got Unknown.", "#/4"}])
  end

  test "validation errors for an invalid item with a list of item schemata and an invalid additional item" do
    assert_validation_errors(%{
        "items" => [%{"type" => "string"}, %{"type" => "integer"}, %{"type" => "integer"}],
        "additionalItems" => %{"type" => "boolean"}},
      [%{}, 1, "foo", true, 2.2], [
        {"Type mismatch. Expected String but got Object.", "#/0"},
        {"Type mismatch. Expected Integer but got String.", "#/2"},
        {"Type mismatch. Expected Boolean but got Number.", "#/4"}])
  end

  test "validation errors for disallowed additional items" do
    assert_validation_errors(
      %{"items" => [%{"type" => "boolean"}], "additionalItems" => false},
      [true, false, "foo"], [
        {"Schema does not allow additional items.", "#/1"},
        {"Schema does not allow additional items.", "#/2"}])
  end

  test "validation errors for minimum items" do
    assert_validation_errors(
      %{"minItems" => 2},
      ["foo"],
      [{"Expected a minimum of 2 items but got 1.", "#"}])
  end

  test "validation errors for maximum items" do
    assert_validation_errors(
      %{"maxItems" => 2},
      ["foo", "bar", "baz"],
      [{"Expected a maximum of 2 items but got 3.", "#"}])
  end

  test "validation errors for non-unique items" do
    assert_validation_errors(
      %{"uniqueItems" => true},
      [1, 2, 3, 3],
      [{"Expected items to be unique but they were not.", "#"}])
  end

  test "validation errors for value not allowed in enum" do
    assert_validation_errors(
      %{"enum" => ["foo", "bar"]},
      %{"baz" => 1},
      [{~s(Value %{"baz" => 1} is not allowed in enum.), "#"}])
  end

  test "validation errors for minimum values" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"minimum" => 2}, "bar" => %{"minimum" => 2, "exclusiveMinimum" => true}}},
      %{"foo" => 1, "bar" => 2}, [
        {"Expected the value to be > 2", "#/bar"},
        {"Expected the value to be >= 2", "#/foo"}])
  end

  test "validation errors for maximum values" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"maximum" => 2}, "bar" => %{"maximum" => 2, "exclusiveMaximum" => true}}},
      %{"foo" => 3, "bar" => 2}, [
        {"Expected the value to be < 2", "#/bar"},
        {"Expected the value to be <= 2", "#/foo"}])
  end

  test "validation errors for multiples of" do
    assert_validation_errors(
      %{"multipleOf" => 2},
      5,
      [{"Expected value to be a multiple of 2 but got 5.", "#"}])
  end

  test "validation errors for minimum length" do
    assert_validation_errors(
      %{"minLength" => 4},
      "foo",
      [{"Expected value to have a minimum length of 4 but was 3.", "#"}])
  end

  test "validation errors for maximum length" do
    assert_validation_errors(
      %{"maxLength" => 2},
      "foo",
      [{"Expected value to have a maximum length of 2 but was 3.", "#"}])
  end

  test "validation errors for pattern mismatch" do
    assert_validation_errors(
      %{"pattern" => "^b..$"},
      "foo",
      [{~s(String "foo" does not match pattern "^b..$".), "#"}])
  end

  test "validation errors for nested objects" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"items" => %{"properties" => %{"bar" => %{"type" => "integer"}}}}}},
      %{"foo" => [%{"bar" => 1}, %{"bar" => "baz"}]},
      [{"Type mismatch. Expected Integer but got String.", "#/foo/1/bar"}])
  end

  test "format validation always succeeds for non-string values" do
    assert :ok == validate(%{"format" => "date-time"}, false)
  end

  test "validation errors for date-time format" do
    assert_validation_errors(
      %{"format" => "date-time"},
      "2012-12-12 12:12:12",
      [{"Expected \"2012-12-12 12:12:12\" to be a valid ISO 8601 date-time.", "#"}])
  end

  test "validation errors for email format" do
    assert_validation_errors(
      %{"format" => "email"},
      "foo@",
      [{"Expected \"foo@\" to be an email address.", "#"}])
  end

  test "validation errors for hostname format" do
    assert_validation_errors(
      %{"format" => "hostname"},
      "foo-bar",
      [{"Expected \"foo-bar\" to be a host name.", "#"}])
  end

  test "validation errors for ipv4 format" do
    assert_validation_errors(
      %{"format" => "ipv4"},
      "12.12.12",
      [{"Expected \"12.12.12\" to be an IPv4 address.", "#"}])
  end

  test "validation errors for ipv6 format" do
    assert_validation_errors(
      %{"format" => "ipv6"},
      "12:12:12",
      [{"Expected \"12:12:12\" to be an IPv6 address.", "#"}])
  end

  defp assert_validation_errors(schema, data, expected_errors) do
    {:error, errors} = validate(schema, data)
    assert errors == expected_errors
  end
end
