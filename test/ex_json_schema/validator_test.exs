defmodule NExJsonSchema.ValidatorTest do
  # , async: true
  use ExUnit.Case

  import NExJsonSchema.Validator, only: [validate: 2, valid?: 2]

  test "empty schema is valid" do
    assert valid?(%{}, %{"foo" => "bar"}) == true
  end

  test "required properties are not validated when the data is not a map" do
    assert_validation_errors(%{"required" => ["foo"], "type" => "object"}, "foo", [
      {%{
         raw_description: "type mismatch. Expected %{expected} but got %{actual}",
         description: "type mismatch. Expected object but got string",
         params: [expected: "object", actual: "string"],
         rule: :cast
       }, "$"}
    ])
  end

  test "validation errors with a reference" do
    assert_validation_errors(
      %{"foo" => %{"type" => "object"}, "properties" => %{"bar" => %{"$ref" => "#/foo"}}},
      %{"bar" => "baz"},
      [
        {%{
           raw_description: "type mismatch. Expected %{expected} but got %{actual}",
           description: "type mismatch. Expected object but got string",
           params: [expected: "object", actual: "string"],
           rule: :cast
         }, "$.bar"}
      ]
    )
  end

  test "validation path errors in nested map" do
    schema = %{
      "$schema" => "http://json-schema.org/draft-04/schema#",
      "type" => "object",
      "definitions" => %{
        "item" => %{
          "type" => "object",
          "required" => ["required"],
          "properties" => %{
            "string" => %{"type" => "string"},
            "required" => %{"type" => "string"}
          }
        }
      },
      "properties" => %{
        "bar" => %{
          "type" => "object",
          "additionalProperties" => false,
          "properties" => %{
            "max" => %{"maximum" => 2},
            "array" => %{
              "type" => "array",
              "items" => %{
                "$ref" => "#/definitions/item"
              }
            },
            "pattern" => %{"pattern" => "^b..$"},
            "minLength" => %{"minLength" => 10}
          }
        }
      }
    }

    data = %{
      "bar" => %{
        "int" => "string",
        "max" => 3,
        "array" => [%{"string" => "string", "required" => "yes"}, %{"string" => "string"}],
        "pattern" => "",
        "minLength" => "short"
      }
    }

    {:error, errors} = validate(schema, data)

    Enum.each(errors, fn {%{rule: rule}, path} ->
      expected_path =
        case rule do
          :cast -> "$.bar.array.[0].string"
          :number -> "$.bar.max"
          :length -> "$.bar.minLength"
          :format -> "$.bar.pattern"
          :schema -> "$.bar.int"
          :required -> "$.bar.array.[1].required"
        end

      assert expected_path == path
    end)
  end

  test "validation errors with a remote reference within a remote reference" do
    assert_validation_errors(%{"$ref" => "http://localhost:8000/subschema.json#/foo"}, "foo", [
      {%{
         raw_description: "type mismatch. Expected %{expected} but got %{actual}",
         description: "type mismatch. Expected integer but got string",
         params: [expected: "integer", actual: "string"],
         rule: :cast
       }, "$"}
    ])
  end

  test "validation errors for not matching all of the schemata" do
    assert_validation_errors(%{"allOf" => [%{"type" => "number"}, %{"type" => "integer"}]}, "foo", [
      {%{
         raw_description:
           "expected all of the schemata to match, but the schemata at the following indexes did not: %{indexes}",
         description: "expected all of the schemata to match, but the schemata at the following indexes did not: 0, 1",
         params: [indexes: [0, 1]],
         rule: :schemata
       }, "$"}
    ])
  end

  test "validation errors for not matching any of the schemata" do
    assert_validation_errors(%{"anyOf" => [%{"type" => "number"}, %{"type" => "integer"}]}, "foo", [
      {%{
         raw_description: "expected any of the schemata to match but none did",
         description: "expected any of the schemata to match but none did",
         params: [],
         rule: :schemata
       }, "$"}
    ])
  end

  test "validation errors for matching more than one of the schemata when exactly one should be matched" do
    assert_validation_errors(%{"oneOf" => [%{"type" => "number"}, %{"type" => "integer"}]}, 5, [
      {%{
         raw_description:
           "expected exactly one of the schemata to match, but the schemata at the following indexes did: %{indexes}",
         description:
           "expected exactly one of the schemata to match, but the schemata at the following indexes did: 0, 1",
         params: [indexes: [0, 1]],
         rule: :schemata
       }, "$"}
    ])
  end

  test "validation errors for matching none of the schemata when exactly one should be matched" do
    assert_validation_errors(%{"oneOf" => [%{"type" => "number"}, %{"type" => "integer"}]}, "foo", [
      {%{
         raw_description: "expected exactly one of the schemata to match, but none of them did",
         description: "expected exactly one of the schemata to match, but none of them did",
         params: [],
         rule: :schemata
       }, "$"}
    ])
  end

  test "validation errors for matching a schema when it should not be matched" do
    assert_validation_errors(%{"not" => %{"type" => "object"}}, %{}, [
      {%{
         raw_description: "expected schema not to match but it did",
         description: "expected schema not to match but it did",
         params: [],
         rule: :schema
       }, "$"}
    ])
  end

  test "validation errors for a wrong type" do
    assert_validation_errors(%{"type" => ["integer", "number"]}, "foo", [
      {%{
         raw_description: "type mismatch. Expected %{expected} but got %{actual}",
         description: "type mismatch. Expected integer, number but got string",
         params: [expected: ["integer", "number"], actual: "string"],
         rule: :cast
       }, "$"}
    ])
  end

  test "validation errors for invalid properties" do
    assert_validation_errors(
      %{
        "properties" => %{"foo" => %{"type" => "string"}},
        "patternProperties" => %{"^b.*$" => %{"type" => "boolean"}},
        "additionalProperties" => false
      },
      %{"foo" => true, "bar" => true, "baz" => 1, "xyz" => false},
      [
        {%{
           raw_description: "type mismatch. Expected %{expected} but got %{actual}",
           description: "type mismatch. Expected string but got boolean",
           params: [expected: "string", actual: "boolean"],
           rule: :cast
         }, "$.foo"},
        {%{
           raw_description: "type mismatch. Expected %{expected} but got %{actual}",
           description: "type mismatch. Expected boolean but got integer",
           params: [expected: "boolean", actual: "integer"],
           rule: :cast
         }, "$.baz"},
        {%{
           raw_description: "schema does not allow additional properties",
           description: "schema does not allow additional properties",
           params: [properties: %{"xyz" => false}],
           rule: :schema
         }, "$.xyz"}
      ]
    )
  end

  test "validation errors for invalid additional properties" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"type" => "string"}}, "additionalProperties" => %{"type" => "boolean"}},
      %{"foo" => "bar", "bar" => "baz"},
      [
        {%{
           raw_description: "type mismatch. Expected %{expected} but got %{actual}",
           description: "type mismatch. Expected boolean but got string",
           params: [expected: "boolean", actual: "string"],
           rule: :cast
         }, "$.bar"}
      ]
    )
  end

  test "validation errors for minimum properties" do
    assert_validation_errors(%{"minProperties" => 2}, %{"foo" => 1}, [
      {%{
         raw_description: "expected a minimum of %{min} properties but got %{actual}",
         description: "expected a minimum of 2 properties but got 1",
         params: [min: 2, actual: 1],
         rule: :length
       }, "$"}
    ])
  end

  test "validation errors for maximum properties" do
    assert_validation_errors(%{"maxProperties" => 1}, %{"foo" => 1, "bar" => 2}, [
      {%{
         raw_description: "expected a maximum of %{max} properties but got %{actual}",
         description: "expected a maximum of 1 properties but got 2",
         params: [max: 1, actual: 2],
         rule: :length
       }, "$"}
    ])
  end

  test "validation errors for missing required properties" do
    assert_validation_errors(%{"required" => ["foo", "bar", "baz"]}, %{"foo" => 1}, [
      {%{
         raw_description: "required property %{property} was not present",
         description: "required property bar was not present",
         params: [property: "bar"],
         rule: :required
       }, "$.bar"},
      {%{
         raw_description: "required property %{property} was not present",
         description: "required property baz was not present",
         params: [property: "baz"],
         rule: :required
       }, "$.baz"}
    ])
  end

  test "validation errors for dependent properties" do
    assert_validation_errors(%{"dependencies" => %{"foo" => ["bar", "baz"]}}, %{"foo" => 1, "bar" => 2}, [
      {%{
         raw_description: "property %{property} depends on %{dependency} to be present but it was not",
         description: "property foo depends on baz to be present but it was not",
         params: [property: "foo", dependency: "baz"],
         rule: :dependency
       }, "$.foo"}
    ])
  end

  test "validation errors for schema dependencies" do
    assert_validation_errors(
      %{"dependencies" => %{"foo" => %{"properties" => %{"bar" => %{"type" => "boolean"}}}}},
      %{"foo" => 1, "bar" => 2},
      [
        {%{
           raw_description: "type mismatch. Expected %{expected} but got %{actual}",
           description: "type mismatch. Expected boolean but got integer",
           params: [expected: "boolean", actual: "integer"],
           rule: :cast
         }, "$.bar"}
      ]
    )
  end

  test "validation errors for invalid items" do
    assert_validation_errors(%{"items" => %{"type" => "string"}}, ["foo", "bar", 1, %{}], [
      {%{
         raw_description: "type mismatch. Expected %{expected} but got %{actual}",
         description: "type mismatch. Expected string but got integer",
         params: [expected: "string", actual: "integer"],
         rule: :cast
       }, "$.[2]"},
      {%{
         raw_description: "type mismatch. Expected %{expected} but got %{actual}",
         description: "type mismatch. Expected string but got object",
         params: [expected: "string", actual: "object"],
         rule: :cast
       }, "$.[3]"}
    ])
  end

  test "validation errors for an invalid item with a list of item schemata and an invalid additional item" do
    assert_validation_errors(
      %{
        "items" => [%{"type" => "string"}, %{"type" => "integer"}, %{"type" => "integer"}],
        "additionalItems" => %{"type" => "boolean"}
      },
      [%{}, 1, "foo", true, 2.2],
      [
        {%{
           raw_description: "type mismatch. Expected %{expected} but got %{actual}",
           description: "type mismatch. Expected string but got object",
           params: [expected: "string", actual: "object"],
           rule: :cast
         }, "$.[0]"},
        {%{
           raw_description: "type mismatch. Expected %{expected} but got %{actual}",
           description: "type mismatch. Expected integer but got string",
           params: [expected: "integer", actual: "string"],
           rule: :cast
         }, "$.[2]"},
        {%{
           raw_description: "type mismatch. Expected %{expected} but got %{actual}",
           description: "type mismatch. Expected boolean but got number",
           params: [expected: "boolean", actual: "number"],
           rule: :cast
         }, "$.[4]"}
      ]
    )
  end

  test "validation errors for disallowed additional items" do
    assert_validation_errors(%{"items" => [%{"type" => "boolean"}], "additionalItems" => false}, [true, false, "foo"], [
      {%{
         raw_description: "schema does not allow additional items",
         description: "schema does not allow additional items",
         params: [],
         rule: :schema
       }, "$.[1]"},
      {%{
         raw_description: "schema does not allow additional items",
         description: "schema does not allow additional items",
         params: [],
         rule: :schema
       }, "$.[2]"}
    ])
  end

  test "validation errors for minimum items" do
    assert_validation_errors(%{"minItems" => 2}, ["foo"], [
      {%{
         raw_description: "expected a minimum of %{min} items but got %{actual}",
         description: "expected a minimum of 2 items but got 1",
         params: [min: 2, actual: 1],
         rule: :length
       }, "$"}
    ])
  end

  test "validation errors for maximum items" do
    assert_validation_errors(%{"maxItems" => 2}, ["foo", "bar", "baz"], [
      {%{
         raw_description: "expected a maximum of %{max} items but got %{actual}",
         description: "expected a maximum of 2 items but got 3",
         params: [max: 2, actual: 3],
         rule: :length
       }, "$"}
    ])
  end

  test "validation errors for non-unique items" do
    assert_validation_errors(%{"uniqueItems" => true}, [1, 2, 3, 3], [
      {%{
         raw_description: "expected items to be unique but they were not",
         description: "expected items to be unique but they were not",
         params: [],
         rule: :unique
       }, "$"}
    ])
  end

  test "validation errors for value not allowed in enum" do
    assert_validation_errors(%{"enum" => ["foo", "bar"]}, %{"baz" => 1}, [
      {%{
         raw_description: "value is not allowed in enum",
         description: "value is not allowed in enum",
         params: [values: ["foo", "bar"]],
         rule: :inclusion
       }, "$"}
    ])
  end

  test "validation errors for minimum values" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"minimum" => 2}, "bar" => %{"minimum" => 2, "exclusiveMinimum" => true}}},
      %{"foo" => 1, "bar" => 2},
      [
        {%{
           raw_description: "expected the value to be > %{greater_than}",
           description: "expected the value to be > 2",
           params: [greater_than: 2],
           rule: :number
         }, "$.bar"},
        {%{
           raw_description: "expected the value to be >= %{greater_than_or_equal_to}",
           description: "expected the value to be >= 2",
           params: [greater_than_or_equal_to: 2],
           rule: :number
         }, "$.foo"}
      ]
    )
  end

  test "validation errors for maximum values" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"maximum" => 2}, "bar" => %{"maximum" => 2, "exclusiveMaximum" => true}}},
      %{"foo" => 3, "bar" => 2},
      [
        {%{
           raw_description: "expected the value to be < %{less_than}",
           description: "expected the value to be < 2",
           params: [less_than: 2],
           rule: :number
         }, "$.bar"},
        {%{
           raw_description: "expected the value to be <= %{less_than_or_equal_to}",
           description: "expected the value to be <= 2",
           params: [less_than_or_equal_to: 2],
           rule: :number
         }, "$.foo"}
      ]
    )
  end

  test "validation errors for multiples of" do
    assert_validation_errors(%{"multipleOf" => 2}, 5, [
      {%{
         raw_description: "expected value to be a multiple of %{multiple_of} but got %{actual}",
         description: "expected value to be a multiple of 2 but got 5",
         params: [multiple_of: 2, actual: 5],
         rule: :number
       }, "$"}
    ])
  end

  test "validation errors for minimum length" do
    assert_validation_errors(%{"minLength" => 4}, "foo", [
      {%{
         raw_description: "expected value to have a minimum length of %{min} but was %{actual}",
         description: "expected value to have a minimum length of 4 but was 3",
         params: [min: 4, actual: 3],
         rule: :length
       }, "$"}
    ])
  end

  test "validation errors for maximum length" do
    assert_validation_errors(%{"maxLength" => 2}, "foo", [
      {%{
         raw_description: "expected value to have a maximum length of %{max} but was %{actual}",
         description: "expected value to have a maximum length of 2 but was 3",
         params: [max: 2, actual: 3],
         rule: :length
       }, "$"}
    ])
  end

  test "validation errors for pattern mismatch" do
    assert_validation_errors(%{"pattern" => "^b..$"}, "foo", [
      {%{
         raw_description: "string does not match pattern %{pattern}",
         description: "string does not match pattern ^b..$",
         params: [pattern: "^b..$"],
         rule: :format
       }, "$"}
    ])
  end

  test "validation errors for nested objects" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"items" => %{"properties" => %{"bar" => %{"type" => "integer"}}}}}},
      %{"foo" => [%{"bar" => 1}, %{"bar" => "baz"}]},
      [
        {%{
           raw_description: "type mismatch. Expected %{expected} but got %{actual}",
           description: "type mismatch. Expected integer but got string",
           params: [expected: "integer", actual: "string"],
           rule: :cast
         }, "$.foo.[1].bar"}
      ]
    )
  end

  test "format validation always succeeds for non-string values" do
    assert :ok == validate(%{"format" => "date-time"}, false)
  end

  test "validation errors for date-time format" do
    assert_validation_errors(%{"format" => "date-time"}, "2012-12-12 12:12:12", [
      {%{
         raw_description: "expected %{actual} to be a valid ISO 8601 date-time",
         description: "expected \"2012-12-12 12:12:12\" to be a valid ISO 8601 date-time",
         params: [
           pattern:
             "^(-?(?:[1-9][0-9]*)?[0-9]{4})-(1[0-2]|0[1-9])-(3[01]|0[1-9]|[12][0-9])T(2[0-3]|[01][0-9]):([0-5][0-9]):([0-5][0-9])(\\.[0-9]+)?(Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])?$",
           actual: "\"2012-12-12 12:12:12\""
         ],
         rule: :datetime
       }, "$"}
    ])
  end

  test "validation errors for date format" do
    assert_validation_errors(%{"format" => "date"}, "1988.12.12", [
      {%{
         raw_description: "expected %{actual} to be a valid ISO 8601 date",
         description: "expected \"1988.12.12\" to be a valid ISO 8601 date",
         params: [
           pattern:
             "^([\\+-]?\\d{4}(?!\\d{2}\\b))((-?)((0[1-9]|1[0-2])(\\3([12]\\d|0[1-9]|3[01]))?|W([0-4]\\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\\d|[12]\\d{2}|3([0-5]\\d|6[1-6])))?)?$",
           actual: "\"1988.12.12\""
         ],
         rule: :date
       }, "$"}
    ])
  end

  test "validation errors for date-time existence" do
    assert_validation_errors(%{"format" => "date-time"}, "1942-02-29T12:12:12", [
      {%{
         raw_description: "expected %{actual} to be an existing date-time",
         description: "expected \"1942-02-29T12:12:12\" to be an existing date-time",
         params: [actual: "\"1942-02-29T12:12:12\""],
         rule: :datetime
       }, "$"}
    ])
  end

  test "validation success for date-time existence" do
    assert :ok == validate(%{"format" => "date-time"}, "1944-02-29T12:12:12Z")
  end

  test "validation errors for date existence" do
    assert_validation_errors(%{"format" => "date"}, "1942-02-29", [
      {%{
         raw_description: "expected %{actual} to be an existing date",
         description: "expected \"1942-02-29\" to be an existing date",
         params: [actual: "\"1942-02-29\""],
         rule: :date
       }, "$"}
    ])
  end

  test "validation success for date existence" do
    assert :ok == validate(%{"format" => "date"}, "1944-02-29")
  end

  test "validation errors for email format" do
    assert_validation_errors(%{"format" => "email"}, "foo@", [
      {%{
         raw_description: "expected %{actual} to be an email address",
         description: "expected \"foo@\" to be an email address",
         params: [
           pattern: "^[\\w!#$%&'*+/=?`{|}~^-]+(?:\\.[\\w!#$%&'*+/=?`{|}~^-]+)*@(?:[A-Z0-9-]+\\.)+[A-Z]{2,6}$",
           actual: "\"foo@\""
         ],
         rule: :email
       }, "$"}
    ])
  end

  test "validation errors for hostname format" do
    assert_validation_errors(%{"format" => "hostname"}, "foo-bar", [
      {%{
         raw_description: "expected %{actual} to be a host name",
         description: "expected \"foo-bar\" to be a host name",
         params: [
           pattern: "^((?=[a-z0-9-]{1,63}\\.)(xn--)?[a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,63}$",
           actual: "\"foo-bar\""
         ],
         rule: :format
       }, "$"}
    ])
  end

  test "validation errors for ipv4 format" do
    assert_validation_errors(%{"format" => "ipv4"}, "12.12.12", [
      {%{
         raw_description: "expected %{actual} to be an IPv4 address",
         description: "expected \"12.12.12\" to be an IPv4 address",
         params: [
           pattern: "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",
           actual: "\"12.12.12\""
         ],
         rule: :format
       }, "$"}
    ])
  end

  test "validation errors for ipv6 format" do
    assert_validation_errors(%{"format" => "ipv6"}, "12:12:12", [
      {%{
         raw_description: "expected %{actual} to be an IPv6 address",
         description: "expected \"12:12:12\" to be an IPv6 address",
         params: [
           pattern: "^(?:(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}|(?=(?:[A-F0-9]{0,4}:){0,7}[A-F0-9]{0,4}$)(([0-9A-F]{1,4}:){1,7}|:)((:[0-9A-F]{1,4}){1,7}|:)|(?:[A-F0-9]{1,4}:){7}:|:(:[A-F0-9]{1,4}){7})$",
           actual: "\"12:12:12\""
         ],
         rule: :format
       }, "$"}
    ])
  end

  defp assert_validation_errors(schema, data, expected_errors) do
    {:error, errors} = validate(schema, data)
    assert errors == expected_errors
  end
end
