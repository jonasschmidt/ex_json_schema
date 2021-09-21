defmodule ExComponentSchema.ValidatorTest do
  use ExUnit.Case, async: true

  import ExComponentSchema.Validator

  alias ExComponentSchema.Schema
  alias ExComponentSchema.Validator.Error

  @schema_with_ref Schema.resolve(%{
                     "properties" => %{
                       "foo" => %{"$ref" => "http://localhost:8000/subschema.json#/foo"}
                     }
                   })

  test "empty schema is valid" do
    assert valid?(%{}, %{"foo" => "bar"}) == true
  end

  test "trying to validate a fragment with an invalid path" do
    assert validate_fragment(@schema_with_ref, "#/properties/bar", "foo") ==
             {:error, :invalid_reference}

    assert valid_fragment?(@schema_with_ref, "#/properties/bar", 123) ==
             {:error, :invalid_reference}
  end

  test "validating a fragment with a path" do
    assert validate_fragment(@schema_with_ref, "#/properties/foo", "foo", error_formatter: false) ==
             {:error,
              [
                %Error{error: %Error.Type{actual: "string", expected: ["integer"]}, path: "#"}
              ]}

    assert valid_fragment?(@schema_with_ref, "#/properties/foo", 123)
  end

  test "validating a fragment with a partial schema" do
    fragment = Schema.get_fragment!(@schema_with_ref, "#/properties/foo")

    assert validate_fragment(@schema_with_ref, fragment, "foo", error_formatter: false) ==
             {:error,
              [
                %Error{error: %Error.Type{actual: "string", expected: ["integer"]}, path: "#"}
              ]}

    assert valid_fragment?(@schema_with_ref, fragment, 123)
  end

  test "required properties are not validated when the data is not a map" do
    assert_validation_errors(
      %{"required" => ["foo"], "type" => "object"},
      "foo",
      [{"Type mismatch. Expected Object but got String.", "#"}],
      [%Error{error: %Error.Type{expected: ["object"], actual: "string"}, path: "#"}]
    )
  end

  test "validation errors with a reference" do
    assert_validation_errors(
      %{"foo" => %{"type" => "object"}, "properties" => %{"bar" => %{"$ref" => "#/foo"}}},
      %{"bar" => "baz"},
      [{"Type mismatch. Expected Object but got String.", "#/bar"}],
      [%Error{error: %Error.Type{expected: ["object"], actual: "string"}, path: "#/bar"}]
    )
  end

  test "validation errors with a remote reference within a remote reference" do
    assert_validation_errors(
      %{"$ref" => "http://localhost:8000/subschema.json#/foo"},
      "foo",
      [{"Type mismatch. Expected Integer but got String.", "#"}],
      [%Error{error: %Error.Type{expected: ["integer"], actual: "string"}, path: "#"}]
    )
  end

  test "validation errors for not matching all of the schemata" do
    assert_validation_errors(
      %{
        "properties" => %{
          "foo" => %{
            "allOf" => [%{"type" => "number"}, %{"type" => "string"}, %{"type" => "integer"}]
          }
        }
      },
      %{"foo" => "foo"},
      [
        {"Expected all of the schemata to match, but the schemata at the following indexes did not: 0, 2.",
         "#/foo"}
      ],
      [
        %Error{
          error: %Error.AllOf{
            invalid: [
              %Error.InvalidAtIndex{
                errors: [
                  %Error{
                    error: %Error.Type{expected: ["number"], actual: "string"},
                    path: "#/foo"
                  }
                ],
                index: 0
              },
              %Error.InvalidAtIndex{
                errors: [
                  %Error{
                    error: %Error.Type{expected: ["integer"], actual: "string"},
                    path: "#/foo"
                  }
                ],
                index: 2
              }
            ]
          },
          path: "#/foo"
        }
      ]
    )
  end

  test "validation errors for not matching any of the schemata" do
    assert_validation_errors(
      %{
        "properties" => %{"foo" => %{"anyOf" => [%{"type" => "number"}, %{"type" => "integer"}]}}
      },
      %{"foo" => "foo"},
      [{"Expected any of the schemata to match but none did.", "#/foo"}],
      [
        %Error{
          error: %Error.AnyOf{
            invalid: [
              %Error.InvalidAtIndex{
                errors: [
                  %Error{
                    error: %Error.Type{expected: ["number"], actual: "string"},
                    path: "#/foo"
                  }
                ],
                index: 0
              },
              %Error.InvalidAtIndex{
                errors: [
                  %Error{
                    error: %Error.Type{expected: ["integer"], actual: "string"},
                    path: "#/foo"
                  }
                ],
                index: 1
              }
            ]
          },
          path: "#/foo"
        }
      ]
    )
  end

  test "validation errors for matching more than one of the schemata when exactly one should be matched" do
    assert_validation_errors(
      %{"oneOf" => [%{"type" => "number"}, %{"type" => "string"}, %{"type" => "integer"}]},
      5,
      [
        {
          "Expected exactly one of the schemata to match, but the schemata at the following indexes did: 0, 2.",
          "#"
        }
      ],
      [%Error{error: %Error.OneOf{valid_indices: [0, 2], invalid: []}, path: "#"}]
    )
  end

  test "validation errors for matching none of the schemata when exactly one should be matched" do
    assert_validation_errors(
      %{"items" => %{"oneOf" => [%{"type" => "number"}, %{"type" => "integer"}]}},
      ["foo"],
      [
        {
          "Expected exactly one of the schemata to match, but none of them did.",
          "#/0"
        }
      ],
      [
        %Error{
          error: %Error.OneOf{
            valid_indices: [],
            invalid: [
              %Error.InvalidAtIndex{
                errors: [
                  %Error{error: %Error.Type{expected: ["number"], actual: "string"}, path: "#/0"}
                ],
                index: 0
              },
              %Error.InvalidAtIndex{
                errors: [
                  %Error{error: %Error.Type{expected: ["integer"], actual: "string"}, path: "#/0"}
                ],
                index: 1
              }
            ]
          },
          path: "#/0"
        }
      ]
    )
  end

  test "validation errors for matching a schema when it should not be matched" do
    assert_validation_errors(
      %{"not" => %{"type" => "object"}},
      %{},
      [{"Expected schema not to match but it did.", "#"}],
      [%Error{error: %Error.Not{}, path: "#"}]
    )
  end

  test "validation errors for a wrong type" do
    assert_validation_errors(
      %{"type" => ["integer", "number"]},
      "foo",
      [{"Type mismatch. Expected Integer, Number but got String.", "#"}],
      [%Error{error: %Error.Type{expected: ["integer", "number"], actual: "string"}, path: "#"}]
    )
  end

  test "validation errors for an unknown type" do
    assert_validation_errors(
      %{"type" => "string"},
      {:foo, "bar"},
      [{"Type mismatch. Expected String but got Unknown.", "#"}],
      [%Error{error: %Error.Type{expected: ["string"], actual: "unknown"}, path: "#"}]
    )
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
        {"Type mismatch. Expected String but got Boolean.", "#/foo"},
        {"Type mismatch. Expected Boolean but got Integer.", "#/baz"},
        {"Schema does not allow additional properties.", "#/xyz"}
      ],
      [
        %Error{error: %Error.Type{expected: ["string"], actual: "boolean"}, path: "#/foo"},
        %Error{error: %Error.Type{expected: ["boolean"], actual: "integer"}, path: "#/baz"},
        %Error{error: %Error.AdditionalProperties{}, path: "#/xyz"}
      ]
    )
  end

  test "validation errors for invalid additional properties" do
    assert_validation_errors(
      %{
        "properties" => %{"foo" => %{"type" => "string"}},
        "additionalProperties" => %{"type" => "boolean"}
      },
      %{"foo" => "bar", "bar" => "baz"},
      [{"Type mismatch. Expected Boolean but got String.", "#/bar"}],
      [%Error{error: %Error.Type{expected: ["boolean"], actual: "string"}, path: "#/bar"}]
    )
  end

  test "validation errors for minimum properties" do
    assert_validation_errors(
      %{"minProperties" => 2},
      %{"foo" => 1},
      [{"Expected a minimum of 2 properties but got 1", "#"}],
      [%Error{error: %Error.MinProperties{expected: 2, actual: 1}, path: "#"}]
    )
  end

  test "validation errors for maximum properties" do
    assert_validation_errors(
      %{"maxProperties" => 1},
      %{"foo" => 1, "bar" => 2},
      [{"Expected a maximum of 1 properties but got 2", "#"}],
      [%Error{error: %Error.MaxProperties{expected: 1, actual: 2}, path: "#"}]
    )
  end

  test "validation errors for missing required property" do
    assert_validation_errors(
      %{"required" => ["foo", "bar", "baz"]},
      %{"foo" => 1, "bar" => 2},
      [
        {"Required property baz was not present.", "#"}
      ],
      [%Error{error: %Error.Required{missing: ["baz"]}, path: "#"}]
    )
  end

  test "validation errors for missing required properties" do
    assert_validation_errors(
      %{"required" => ["foo", "bar", "baz"]},
      %{"foo" => 1},
      [
        {"Required properties bar, baz were not present.", "#"}
      ],
      [%Error{error: %Error.Required{missing: ["bar", "baz"]}, path: "#"}]
    )
  end

  test "validation errors for dependent property" do
    assert_validation_errors(
      %{"dependencies" => %{"foo" => ["bar", "baz", "qux"]}},
      %{"foo" => 1, "bar" => 2, "baz" => 3},
      [{"Property foo depends on property qux to be present but it was not.", "#"}],
      [%Error{error: %Error.Dependencies{property: "foo", missing: ["qux"]}, path: "#"}]
    )
  end

  test "validation errors for dependent properties" do
    assert_validation_errors(
      %{"dependencies" => %{"foo" => ["bar", "baz", "qux"]}},
      %{"foo" => 1, "bar" => 2},
      [{"Property foo depends on properties baz, qux to be present but they were not.", "#"}],
      [%Error{error: %Error.Dependencies{property: "foo", missing: ["baz", "qux"]}, path: "#"}]
    )
  end

  test "validation errors for schema dependencies" do
    assert_validation_errors(
      %{"dependencies" => %{"foo" => %{"properties" => %{"bar" => %{"type" => "boolean"}}}}},
      %{"foo" => 1, "bar" => 2},
      [{"Type mismatch. Expected Boolean but got Integer.", "#/bar"}],
      [%Error{error: %Error.Type{expected: ["boolean"], actual: "integer"}, path: "#/bar"}]
    )
  end

  test "validation errors for invalid items" do
    assert_validation_errors(
      %{"items" => %{"type" => "string"}},
      ["foo", "bar", 1, %{}],
      [
        {"Type mismatch. Expected String but got Integer.", "#/2"},
        {"Type mismatch. Expected String but got Object.", "#/3"}
      ],
      [
        %Error{error: %Error.Type{expected: ["string"], actual: "integer"}, path: "#/2"},
        %Error{error: %Error.Type{expected: ["string"], actual: "object"}, path: "#/3"}
      ]
    )
  end

  test "validation errors for items when none are allowed" do
    assert_validation_errors(
      %{
        "properties" => %{
          "foo" => %{"items" => %{"properties" => %{"bar" => %{"items" => false}}}}
        }
      },
      %{"foo" => [%{"bar" => ["foo"]}, %{"bar" => []}]},
      [{"Items are not allowed.", "#/foo/0/bar"}],
      [%Error{error: %Error.ItemsNotAllowed{}, path: "#/foo/0/bar"}]
    )
  end

  test "validation errors for items with false schema" do
    assert_validation_errors(
      %{"items" => [false, %{"type" => "string"}, false]},
      ["foo", "foo", "foo"],
      [{"False schema never matches.", "#/0"}, {"False schema never matches.", "#/2"}],
      [%Error{error: %Error.False{}, path: "#/0"}, %Error{error: %Error.False{}, path: "#/2"}]
    )
  end

  test "validation errors for an invalid item with a list of item schemata and an invalid additional item" do
    assert_validation_errors(
      %{
        "items" => [%{"type" => "string"}, %{"type" => "integer"}, %{"type" => "integer"}],
        "additionalItems" => %{"type" => "boolean"}
      },
      [%{}, 1, "foo", true, 2.2],
      [
        {"Type mismatch. Expected String but got Object.", "#/0"},
        {"Type mismatch. Expected Integer but got String.", "#/2"},
        {"Type mismatch. Expected Boolean but got Number.", "#/4"}
      ],
      [
        %Error{error: %Error.Type{expected: ["string"], actual: "object"}, path: "#/0"},
        %Error{error: %Error.Type{expected: ["integer"], actual: "string"}, path: "#/2"},
        %Error{error: %Error.Type{expected: ["boolean"], actual: "number"}, path: "#/4"}
      ]
    )
  end

  test "validation errors for disallowed additional items" do
    assert_validation_errors(
      %{"items" => [%{"type" => "boolean"}, %{"type" => "string"}], "additionalItems" => false},
      [true, "foo", true, "bar", 5],
      [{"Schema does not allow additional items.", "#"}],
      [%Error{error: %Error.AdditionalItems{additional_indices: 2..4}, path: "#"}]
    )
  end

  test "validation errors for minimum items" do
    assert_validation_errors(
      %{"minItems" => 2},
      ["foo"],
      [{"Expected a minimum of 2 items but got 1.", "#"}],
      [%Error{error: %Error.MinItems{expected: 2, actual: 1}, path: "#"}]
    )
  end

  test "validation errors for maximum items" do
    assert_validation_errors(
      %{"maxItems" => 2},
      ["foo", "bar", "baz"],
      [{"Expected a maximum of 2 items but got 3.", "#"}],
      [%Error{error: %Error.MaxItems{expected: 2, actual: 3}, path: "#"}]
    )
  end

  test "validation errors for non-unique items" do
    assert_validation_errors(
      %{"uniqueItems" => true},
      [1, 2, 3, 3],
      [{"Expected items to be unique but they were not.", "#"}],
      [%Error{error: %Error.UniqueItems{}, path: "#"}]
    )
  end

  test "validation errors for value not allowed in enum" do
    assert_validation_errors(
      %{"enum" => ["foo", "bar"]},
      %{"baz" => 1},
      [{"Value is not allowed in enum.", "#"}],
      [%Error{error: %Error.Enum{}, path: "#"}]
    )
  end

  test "validation errors for minimum values" do
    assert_validation_errors(
      %{
        "properties" => %{
          "foo" => %{"minimum" => 2},
          "bar" => %{"exclusiveMinimum" => 2}
        }
      },
      %{"foo" => 1, "bar" => 2},
      [{"Expected the value to be > 2", "#/bar"}, {"Expected the value to be >= 2", "#/foo"}],
      [
        %Error{error: %Error.Minimum{expected: 2, exclusive?: true}, path: "#/bar"},
        %Error{error: %Error.Minimum{expected: 2, exclusive?: false}, path: "#/foo"}
      ]
    )
  end

  test "validation errors for maximum values" do
    assert_validation_errors(
      %{
        "properties" => %{
          "foo" => %{"maximum" => 2},
          "bar" => %{"exclusiveMaximum" => 2}
        }
      },
      %{"foo" => 3, "bar" => 2},
      [{"Expected the value to be < 2", "#/bar"}, {"Expected the value to be <= 2", "#/foo"}],
      [
        %Error{error: %Error.Maximum{expected: 2, exclusive?: true}, path: "#/bar"},
        %Error{error: %Error.Maximum{expected: 2, exclusive?: false}, path: "#/foo"}
      ]
    )
  end

  test "validation errors for multiples of" do
    assert_validation_errors(
      %{"multipleOf" => 2},
      5,
      [{"Expected value to be a multiple of 2.", "#"}],
      [%Error{error: %Error.MultipleOf{expected: 2}, path: "#"}]
    )

    assert_validation_errors(
      %{"multipleOf" => 0.1},
      123.45,
      [{"Expected value to be a multiple of 0.1.", "#"}],
      [%Error{error: %Error.MultipleOf{expected: 0.1}, path: "#"}]
    )

    assert valid?(%{"multipleOf" => 5}, 0)
  end

  test "multiple of validator division by 0" do
    assert ExComponentSchema.Validator.MultipleOf.validate(nil, nil, {"multipleOf", 0}, 5, nil) ==
             [%Error{error: %Error.MultipleOf{expected: 0}}]
  end

  test "multiple of precision" do
    assert valid?(%{"multipleOf" => 0.01}, 147.41)
    assert valid?(%{"multipleOf" => 0.01}, 147.42)
  end

  test "validation errors for minimum length" do
    assert_validation_errors(
      %{"minLength" => 4},
      "foo",
      [{"Expected value to have a minimum length of 4 but was 3.", "#"}],
      [%Error{error: %Error.MinLength{expected: 4, actual: 3}, path: "#"}]
    )
  end

  test "validation errors for maximum length" do
    assert_validation_errors(
      %{"maxLength" => 2},
      "foo",
      [{"Expected value to have a maximum length of 2 but was 3.", "#"}],
      [%Error{error: %Error.MaxLength{expected: 2, actual: 3}, path: "#"}]
    )
  end

  test "validation errors for pattern mismatch" do
    assert_validation_errors(
      %{"pattern" => "^b..$"},
      "foo",
      [{~s(Does not match pattern "^b..$".), "#"}],
      [%Error{error: %Error.Pattern{expected: "^b..$"}, path: "#"}]
    )
  end

  test "validation errors for const" do
    assert_validation_errors(
      %{"const" => "foo"},
      "bar",
      [{"Expected data to be \"foo\".", "#"}],
      [%Error{error: %Error.Const{expected: "foo"}, path: "#"}]
    )
  end

  test "validation errors for contains" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"contains" => %{"type" => "number"}}}},
      %{"foo" => ["foo", %{}]},
      [{"Expected any of the items to match the schema but none did.", "#/foo"}],
      [
        %Error{
          error: %Error.Contains{
            empty?: false,
            invalid: [
              %Error.InvalidAtIndex{
                errors: [
                  %Error{
                    error: %Error.Type{expected: ["number"], actual: "string"},
                    path: "#/foo/0"
                  }
                ],
                index: 0
              },
              %Error.InvalidAtIndex{
                errors: [
                  %Error{
                    error: %Error.Type{expected: ["number"], actual: "object"},
                    path: "#/foo/1"
                  }
                ],
                index: 1
              }
            ]
          },
          path: "#/foo"
        }
      ]
    )
  end

  test "validation errors for contains and empty list" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"contains" => %{"type" => "number"}}}},
      %{"foo" => []},
      [{"Expected any of the items to match the schema but none did.", "#/foo"}],
      [
        %Error{
          error: %Error.Contains{
            empty?: true,
            invalid: []
          },
          path: "#/foo"
        }
      ]
    )
  end

  test "validation errors for content encoding" do
    assert_validation_errors(
      %{"contentEncoding" => "base64"},
      "foo",
      [{"Expected the content to be base64-encoded.", "#"}],
      [%Error{error: %Error.ContentEncoding{expected: "base64"}, path: "#"}]
    )
  end

  test "validation errors for content media type" do
    assert_validation_errors(
      %{"contentEncoding" => "base64", "contentMediaType" => "application/json"},
      Base.encode64("foo"),
      [{"Expected the content to be of media type application/json.", "#"}],
      [
        %Error{
          error: %Error.ContentMediaType{expected: "application/json"},
          path: "#"
        }
      ]
    )

    assert_validation_errors(
      %{"contentEncoding" => "something", "contentMediaType" => "application/json"},
      "{:}",
      [{"Expected the content to be of media type application/json.", "#"}],
      [
        %Error{
          error: %Error.ContentMediaType{expected: "application/json"},
          path: "#"
        }
      ]
    )
  end

  test "validation errors for property names" do
    assert_validation_errors(
      %{"properties" => %{"foo" => %{"propertyNames" => %{"minLength" => 3, "maxLength" => 5}}}},
      %{"foo" => %{"f" => true, "foo" => true, "barbaz" => true}},
      [
        {"Expected the property names to be valid but the following were not: barbaz, f.",
         "#/foo"}
      ],
      [
        %Error{
          error: %Error.PropertyNames{
            invalid: %{
              "f" => [
                %Error{
                  error: %Error.MinLength{expected: 3, actual: 1},
                  path: "#/foo/f"
                }
              ],
              "barbaz" => [
                %Error{
                  error: %Error.MaxLength{expected: 5, actual: 6},
                  path: "#/foo/barbaz"
                }
              ]
            }
          },
          path: "#/foo"
        }
      ]
    )
  end

  test "validation errors for nested objects" do
    assert_validation_errors(
      %{
        "properties" => %{
          "foo" => %{"items" => %{"properties" => %{"bar" => %{"type" => "integer"}}}}
        }
      },
      %{"foo" => [%{"bar" => 1}, %{"bar" => "baz"}]},
      [{"Type mismatch. Expected Integer but got String.", "#/foo/1/bar"}],
      [%Error{error: %Error.Type{expected: ["integer"], actual: "string"}, path: "#/foo/1/bar"}]
    )
  end

  test "format validation always succeeds for non-string values" do
    assert :ok == validate(%{"format" => "date-time"}, false)
  end

  test "validation errors for date-time format" do
    assert_validation_errors(
      %{"format" => "date-time"},
      "2012-12-12 12:12:12",
      [{"Expected to be a valid ISO 8601 date-time.", "#"}],
      [%Error{error: %Error.Format{expected: "date-time"}, path: "#"}]
    )
  end

  test "validation errors for email format" do
    assert_validation_errors(
      %{"format" => "email"},
      "foo@",
      [{"Expected to be a valid email.", "#"}],
      [%Error{error: %Error.Format{expected: "email"}, path: "#"}]
    )
  end

  test "validation errors for hostname format" do
    assert_validation_errors(
      %{"format" => "hostname"},
      "-foo-bar-",
      [{"Expected to be a valid hostname.", "#"}],
      [%Error{error: %Error.Format{expected: "hostname"}, path: "#"}]
    )
  end

  test "validation errors for ipv4 format" do
    assert_validation_errors(
      %{"format" => "ipv4"},
      "12.12.12",
      [{"Expected to be a valid IPv4 address.", "#"}],
      [%Error{error: %Error.Format{expected: "ipv4"}, path: "#"}]
    )
  end

  test "validation errors for ipv6 format" do
    assert_validation_errors(
      %{"format" => "ipv6"},
      "12:12:12",
      [{"Expected to be a valid IPv6 address.", "#"}],
      [%Error{error: %Error.Format{expected: "ipv6"}, path: "#"}]
    )
  end

  test "unknown formats are ignored" do
    assert :ok == validate(%{"format" => "custom-format"}, "asdfsadf")
  end

  defmodule MyFormatValidator do
    def validate("always_error", _data) do
      false
    end

    def validate("zipcode", data) do
      Regex.match?(~r/^\d+$/, data)
    end
  end

  test "configuring a custom format validator" do
    schema =
      Schema.resolve(
        %{
          "properties" => %{
            "error" => %{"format" => "always_error"},
            "zip" => %{"format" => "zipcode"}
          }
        },
        custom_format_validator: {MyFormatValidator, :validate}
      )

    assert_validation_errors(
      schema,
      %{"error" => ""},
      [{"Expected to be a valid always_error.", "#/error"}],
      [%Error{error: %Error.Format{expected: "always_error"}, path: "#/error"}]
    )

    assert :ok == validate(%{"format" => "zipcode"}, "12345")

    assert_validation_errors(
      schema,
      %{"zip" => "asdf"},
      [{"Expected to be a valid zipcode.", "#/zip"}],
      [%Error{error: %Error.Format{expected: "zipcode"}, path: "#/zip"}]
    )
  end

  test "passing the formatter as an option" do
    assert :ok = validate(%{"type" => "string"}, "foo", error_formatter: Error.StringFormatter)

    assert {:error, [{"Type mismatch. Expected String but got Integer.", "#"}]} =
             validate(%{"type" => "string"}, 666, error_formatter: Error.StringFormatter)
  end

  test "using the string formatter by default" do
    assert {:error, [{"Type mismatch. Expected String but got Integer.", "#"}]} =
             validate(%{"type" => "string"}, 666)
  end

  defp assert_validation_errors(schema, data, expected_errors, expected_error_structs) do
    assert {:error, errors} = validate(schema, data, error_formatter: false)
    assert errors == expected_error_structs
    assert Error.StringFormatter.format(errors) == expected_errors
  end
end
