defmodule NExJsonSchema.ValidatorTest do
  use ExUnit.Case#, async: true

  import NExJsonSchema.Validator, only: [validate: 2, valid?: 2]

  test "empty schema is valid" do
    assert valid?(%{}, %{"foo" => "bar"}) == true
  end

  test "required properties are not validated when the data is not a map" do
    assert_validation_errors(
      %{"required" => ["foo"], "type" => "object"},
      "foo",
      [{%{description: "type mismatch. Expected Object but got String", params: ["object"], rule: :cast}, "$"}])
  end

  test "validation errors with a reference" do
    assert_validation_errors(
      %{"foo" => %{"type" => "object"}, "properties" => %{"bar" => %{"$ref" => "#/foo"}}},
      %{"bar" => "baz"},
      [{%{description: "type mismatch. Expected Object but got String", params: ["object"], rule: :cast}, "$.bar"}])
  end

  test "validation errors with a remote reference within a remote reference" do
    assert_validation_errors(
      %{"$ref" => "http://localhost:8000/subschema.json#/foo"},
      "foo",
      [{%{description: "type mismatch. Expected Integer but got String", params: ["integer"], rule: :cast}, "$"}])
  end

  test "validation errors for not matching all of the schemata" do
    assert_validation_errors(
      %{"allOf" => [%{"type" => "number"}, %{"type" => "integer"}]},
      "foo",
      [{%{description: "expected all of the schemata to match, but the schemata at the following indexes did not: 0, 1", params: [], rule: :schemata}, "$"}])
  end

  test "validation errors for not matching any of the schemata" do
    assert_validation_errors(
      %{"anyOf" => [%{"type" => "number"}, %{"type" => "integer"}]},
      "foo",
      [{%{description: "expected any of the schemata to match but none did", params: [], rule: :schemata}, "$"}])
  end

  test "validation errors for matching more than one of the schemata when exactly one should be matched" do
    assert_validation_errors(
      %{"oneOf" => [%{"type" => "number"}, %{"type" => "integer"}]},
      5,
      [{%{description: "expected exactly one of the schemata to match, but the schemata at the following indexes did: 0, 1", params: [], rule: :schemata}, "$"}])
  end

  test "validation errors for matching none of the schemata when exactly one should be matched" do
    assert_validation_errors(
      %{"oneOf" => [%{"type" => "number"}, %{"type" => "integer"}]},
      "foo",
      [{%{description: "expected exactly one of the schemata to match, but none of them did", params: [], rule: :schemata}, "$"}])
  end

  test "validation errors for matching a schema when it should not be matched" do
    assert_validation_errors(
      %{"not" => %{"type" => "object"}},
      %{},
      [{%{description: "expected schema not to match but it did", params: [], rule: :schema}, "$"}])
  end

  test "validation errors for a wrong type" do
    assert_validation_errors(
      %{"type" => ["integer", "number"]},
      "foo",
      [{%{description: "type mismatch. Expected Integer, Number but got String", params: [["integer", "number"]], rule: :cast}, "$"}])
  end

  test "validation errors for invalid properties" do
    assert_validation_errors(%{
        "properties" => %{"foo" => %{"type" => "string"}},
        "patternProperties" => %{"^b.*$" => %{"type" => "boolean"}},
        "additionalProperties" => false},
      %{"foo" => true, "bar" => true, "baz" => 1, "xyz" => false}, [
        {%{description: "type mismatch. Expected String but got Boolean", params: ["string"], rule: :cast}, "$.foo"},
        {%{description: "type mismatch. Expected Boolean but got Integer", params: ["boolean"], rule: :cast}, "$.baz"},
        {%{description: "schema does not allow additional properties", params: %{"xyz" => false}, rule: :schema}, "$.xyz"}])
  end

  test "validation errors for invalid additional properties" do
    assert_validation_errors(%{
        "properties" => %{"foo" => %{"type" => "string"}},
        "additionalProperties" => %{"type" => "boolean"}},
      %{"foo" => "bar", "bar" => "baz"},
      [{%{description: "type mismatch. Expected Boolean but got String", params: ["boolean"], rule: :cast}, "$.bar"}])
  end

  test "validation errors for minimum properties" do
    assert_validation_errors(
      %{"minProperties" => 2},
      %{"foo" => 1},
      [{%{description: "expected a minimum of 2 properties but got 1", params: %{min: 2}, rule: :length}, "$"}])
  end

  test "validation errors for maximum properties" do
    assert_validation_errors(
      %{"maxProperties" => 1},
      %{"foo" => 1, "bar" => 2},
      [{%{description: "expected a maximum of 1 properties but got 2", params: %{max: 1}, rule: :length}, "$"}])
  end

  test "validation errors for missing required properties" do
    assert_validation_errors(
      %{"required" => ["foo", "bar", "baz"]},
      %{"foo" => 1}, [
        {%{description: "required property bar was not present", params: [], rule: :required}, "$"},
        {%{description: "required property baz was not present", params: [], rule: :required}, "$"}])
  end

  test "validation errors for dependent properties" do
    assert_validation_errors(
      %{"dependencies" => %{"foo" => ["bar", "baz"]}},
      %{"foo" => 1, "bar" => 2},
      [{%{description: "property foo depends on baz to be present but it was not", params: ["baz"], rule: :dependency}, "$"}])
  end

  test "validation errors for schema dependencies" do
    assert_validation_errors(
      %{"dependencies" => %{"foo" => %{"properties" => %{"bar" => %{"type" => "boolean"}}}}},
      %{"foo" => 1, "bar" => 2},
      [{%{description: "type mismatch. Expected Boolean but got Integer", params: ["boolean"], rule: :cast}, "$.bar"}])
  end

  test "validation errors for invalid items" do
    assert_validation_errors(
      %{"items" => %{"type" => "string"}},
      ["foo", "bar", 1, %{}], [
        {%{description: "type mismatch. Expected String but got Integer", params: ["string"], rule: :cast}, "$.[2]"},
        {%{description: "type mismatch. Expected String but got Object", params: ["string"], rule: :cast}, "$.[3]"}])
  end

  test "validation errors for an invalid item with a list of item schemata and an invalid additional item" do
    assert_validation_errors(%{
        "items" => [%{"type" => "string"}, %{"type" => "integer"}, %{"type" => "integer"}],
        "additionalItems" => %{"type" => "boolean"}},
      [%{}, 1, "foo", true, 2.2], [
        {%{description: "type mismatch. Expected String but got Object", params: ["string"], rule: :cast}, "$.[0]"},
        {%{description: "type mismatch. Expected Integer but got String", params: ["integer"], rule: :cast}, "$.[2]"},
        {%{description: "type mismatch. Expected Boolean but got Number", params: ["boolean"], rule: :cast}, "$.[4]"}])
  end

  test "validation errors for disallowed additional items" do
    assert_validation_errors(
      %{"items" => [%{"type" => "boolean"}], "additionalItems" => false},
      [true, false, "foo"], [
        {%{description: "schema does not allow additional items", params: [], rule: :schema}, "$.[1]"},
        {%{description: "schema does not allow additional items", params: [], rule: :schema}, "$.[2]"}])
  end

  test "validation errors for minimum items" do
    assert_validation_errors(
      %{"minItems" => 2},
      ["foo"],
      [{%{description: "expected a minimum of 2 items but got 1", params: %{min: 2}, rule: :length}, "$"}])
  end

  test "validation errors for maximum items" do
    assert_validation_errors(
      %{"maxItems" => 2},
      ["foo", "bar", "baz"],
      [{%{description: "expected a maximum of 2 items but got 3", params: %{max: 2}, rule: :length}, "$"}])
  end

  test "validation errors for non-unique items" do
    assert_validation_errors(
      %{"uniqueItems" => true},
      [1, 2, 3, 3],
      [{%{description: "expected items to be unique but they were not", params: [], rule: :unique}, "$"}])
  end

  test "validation errors for value not allowed in enum" do
    assert_validation_errors(
      %{"enum" => ["foo", "bar"]},
      %{"baz" => 1},
      [{%{description: "value is not allowed in enum", params: ["foo", "bar"], rule: :inclusion}, "$"}])
  end

  test "validation errors for minimum values" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"minimum" => 2}, "bar" => %{"minimum" => 2, "exclusiveMinimum" => true}}},
      %{"foo" => 1, "bar" => 2}, [
        {%{description: "expected the value to be > 2", params: %{greater_than: 2}, rule: :number}, "$.bar"},
        {%{description: "expected the value to be >= 2", params: %{greater_than_or_equal_to: 2}, rule: :number}, "$.foo"}])
  end

  test "validation errors for maximum values" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"maximum" => 2}, "bar" => %{"maximum" => 2, "exclusiveMaximum" => true}}},
      %{"foo" => 3, "bar" => 2}, [
        {%{description: "expected the value to be < 2", params: %{less_than: 2}, rule: :number}, "$.bar"},
        {%{description: "expected the value to be <= 2", params: %{less_than_or_equal_to: 2}, rule: :number}, "$.foo"}])
  end

  test "validation errors for multiples of" do
    assert_validation_errors(
      %{"multipleOf" => 2},
      5,
      [{%{description: "expected value to be a multiple of 2 but got 5", params: %{multiple_of: 2}, rule: :number}, "$"}])
  end

  test "validation errors for minimum length" do
    assert_validation_errors(
      %{"minLength" => 4},
      "foo",
      [{%{description: "expected value to have a minimum length of 4 but was 3", params: %{min: 4}, rule: :length}, "$"}])
  end

  test "validation errors for maximum length" do
    assert_validation_errors(
      %{"maxLength" => 2},
      "foo",
      [{%{description: "expected value to have a maximum length of 2 but was 3", params: %{max: 2}, rule: :length}, "$"}])
  end

  test "validation errors for pattern mismatch" do
    assert_validation_errors(
      %{"pattern" => "^b..$"},
      "foo",
      [{%{description: "string does not match pattern \"^b..$\"", params: ["^b..$"], rule: :format}, "$"}])
  end

  test "validation errors for nested objects" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"items" => %{"properties" => %{"bar" => %{"type" => "integer"}}}}}},
      %{"foo" => [%{"bar" => 1}, %{"bar" => "baz"}]},
      [{%{description: "type mismatch. Expected Integer but got String", params: ["integer"], rule: :cast}, "$.foo.[1].bar"}])
  end

  test "format validation always succeeds for non-string values" do
    assert :ok == validate(%{"format" => "date-time"}, false)
  end

  test "validation errors for date-time format" do
    assert_validation_errors(
      %{"format" => "date-time"},
      "2012-12-12 12:12:12",
      [{%{description: "expected \"2012-12-12 12:12:12\" to be a valid ISO 8601 date-time", params: ["~r/^(-?(?:[1-9][0-9]*)?[0-9]{4})-(1[0-2]|0[1-9])-(3[01]|0[1-9]|[12][0-9])T(2[0-3]|[01][0-9]):([0-5][0-9]):([0-5][0-9])(\\.[0-9]+)?(Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])?$/"], rule: :datetime}, "$"}])
  end

  test "validation errors for date format" do
    assert_validation_errors(
      %{"format" => "date"},
      "1988.12.12",
      [{%{description: "expected \"1988.12.12\" to be a valid ISO 8601 date", params: ["~r/^([\\+-]?\\d{4}(?!\\d{2}\\b))((-?)((0[1-9]|1[0-2])(\\3([12]\\d|0[1-9]|3[01]))?|W([0-4]\\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\\d|[12]\\d{2}|3([0-5]\\d|6[1-6])))?)?$/"], rule: :date}, "$"}])
  end

  test "validation errors for email format" do
    assert_validation_errors(
      %{"format" => "email"},
      "foo@",
      [{%{description: "expected \"foo@\" to be an email address", params: ["~r/^[\\w!#$%&'*+\\/=?`{|}~^-]+(?:\\.[\\w!#$%&'*+\\/=?`{|}~^-]+)*@(?:[A-Z0-9-]+\\.)+[A-Z]{2,6}$/i"], rule: :email}, "$"}])
  end

  test "validation errors for hostname format" do
    assert_validation_errors(
      %{"format" => "hostname"},
      "foo-bar",
      [{%{description: "expected \"foo-bar\" to be a host name", params: ["~r/^((?=[a-z0-9-]{1,63}\\.)(xn--)?[a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,63}$/i"], rule: :format}, "$"}])
  end

  test "validation errors for ipv4 format" do
    assert_validation_errors(
      %{"format" => "ipv4"},
      "12.12.12",
      [{%{description: "expected \"12.12.12\" to be an IPv4 address", params: ["~r/^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/"], rule: :format}, "$"}])
  end

  test "validation errors for ipv6 format" do
    assert_validation_errors(
      %{"format" => "ipv6"},
      "12:12:12",
      [{%{description: "expected \"12:12:12\" to be an IPv6 address", params: ["~r/^(?:(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}|(?=(?:[A-F0-9]{0,4}:){0,7}[A-F0-9]{0,4}$)(([0-9A-F]{1,4}:){1,7}|:)((:[0-9A-F]{1,4}){1,7}|:)|(?:[A-F0-9]{1,4}:){7}:|:(:[A-F0-9]{1,4}){7})$/i"], rule: :format}, "$"}])
  end

  defp assert_validation_errors(schema, data, expected_errors) do
    {:error, errors} = validate(schema, data)
    assert errors == expected_errors
  end
end
