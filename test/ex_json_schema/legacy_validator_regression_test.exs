defmodule ExJsonSchema.LegacyValidatorRegressionTest do
  use ExUnit.Case, async: true

  # Preserves every historical validator test from master. Tests labeled
  # "replacement" assert the 1.0 contract that superseded a removed API;
  # "correction" records behavior intentionally changed for conformance.

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.ReferenceError

  @remote_resources %{
    "http://localhost:1234/subschema.json" => %{
      "foo" => %{"$ref" => "http://localhost:1234/subsubschema.json#/foo"}
    },
    "http://localhost:1234/subsubschema.json" => %{
      "foo" => %{"type" => "integer"}
    }
  }

  test "legacy regression: empty schema is valid" do
    assert_valid(%{}, %{"foo" => "bar"})
  end

  test "legacy regression: trying to validate a fragment with an invalid path" do
    compiled = compile(schema_with_ref(), resources: @remote_resources)

    assert {:error, %ReferenceError{reference: "#/properties/bar"}} =
             ExJsonSchema.fetch_schema(compiled, "#/properties/bar")
  end

  test "legacy regression: validating a fragment with a path" do
    compiled = compile(schema_with_ref(), resources: @remote_resources)
    assert {:ok, fragment} = ExJsonSchema.fetch_schema(compiled, "#/properties/foo")

    assert_invalid_compiled(
      fragment,
      "foo",
      [{"/foo/type", ""}]
    )

    assert_valid_compiled(fragment, 123)
  end

  test "legacy replacement: validating a fragment with a partial schema" do
    compiled = compile(schema_with_ref(), resources: @remote_resources)
    fragment = ExJsonSchema.fetch_schema!(compiled, "#/properties/foo")

    refute ExJsonSchema.valid?("foo", fragment)
    assert ExJsonSchema.valid?(123, fragment)
  end

  test "legacy regression: required properties are not validated when the data is not a map" do
    assert_invalid(
      %{"required" => ["foo"], "type" => "object"},
      "foo",
      [{"/type", ""}]
    )
  end

  test "legacy regression: validation errors with a reference" do
    assert_invalid(
      %{"foo" => %{"type" => "object"}, "properties" => %{"bar" => %{"$ref" => "#/foo"}}},
      %{"bar" => "baz"},
      [{"/foo/type", "/bar"}]
    )
  end

  test "legacy regression: validation errors with a reference to a sibling definition" do
    assert_invalid(
      %{"$ref" => "#/definitions/foo", "definitions" => %{"foo" => %{"type" => "string"}}},
      5,
      [{"/definitions/foo/type", ""}]
    )
  end

  test "legacy regression: validation errors with a reference to a nested sibling definition" do
    assert_invalid(
      %{
        "properties" => %{
          "foo" => %{
            "$ref" => "#/properties/foo/definitions/bar",
            "definitions" => %{"bar" => %{"type" => "string"}}
          }
        }
      },
      %{"foo" => 5},
      [{"/properties/foo/definitions/bar/type", "/foo"}]
    )
  end

  test "legacy regression: validation errors with a remote reference within a remote reference" do
    compiled =
      compile(
        %{"$ref" => "http://localhost:1234/subschema.json#/foo"},
        resources: @remote_resources
      )

    output = assert_invalid_compiled(compiled, "foo", [{"/foo/type", ""}])

    assert Enum.any?(output["errors"], fn error ->
             error["absoluteKeywordLocation"] ==
               "http://localhost:1234/subsubschema.json#/foo/type"
           end)
  end

  test "legacy regression: validation errors for not matching all of the schemata" do
    assert_invalid(
      %{
        "properties" => %{
          "foo" => %{
            "allOf" => [%{"type" => "number"}, %{"type" => "string"}, %{"type" => "integer"}]
          }
        }
      },
      %{"foo" => "foo"},
      [
        {"/properties/foo/allOf", "/foo"},
        {"/properties/foo/allOf/0/type", "/foo"},
        {"/properties/foo/allOf/2/type", "/foo"}
      ]
    )
  end

  test "legacy regression: validation errors for not matching any of the schemata" do
    assert_invalid(
      %{
        "properties" => %{"foo" => %{"anyOf" => [%{"type" => "number"}, %{"type" => "integer"}]}}
      },
      %{"foo" => "foo"},
      [{"/properties/foo/anyOf", "/foo"}]
    )
  end

  test "legacy regression: validation errors for matching more than one of the schemata when exactly one should be matched" do
    assert_invalid(
      %{"oneOf" => [%{"type" => "number"}, %{"type" => "string"}, %{"type" => "integer"}]},
      5,
      [{"/oneOf", ""}]
    )
  end

  test "legacy regression: validation errors for matching none of the schemata when exactly one should be matched" do
    assert_invalid(
      %{"items" => %{"oneOf" => [%{"type" => "number"}, %{"type" => "integer"}]}},
      ["foo"],
      [{"/items/oneOf", "/0"}]
    )
  end

  test "legacy regression: validation errors for matching a schema when it should not be matched" do
    assert_invalid(%{"not" => %{"type" => "object"}}, %{}, [{"/not", ""}])
  end

  test "legacy regression: validation errors for a wrong type" do
    assert_invalid(%{"type" => ["integer", "number"]}, "foo", [{"/type", ""}])
  end

  test "legacy regression: validation errors for an unknown type" do
    assert_invalid(%{"type" => "string"}, {:foo, "bar"}, [{"/type", ""}])
  end

  test "legacy regression: validation errors for invalid properties" do
    assert_invalid(
      %{
        "properties" => %{"foo" => %{"type" => "string"}},
        "patternProperties" => %{"^b.*$" => %{"type" => "boolean"}},
        "additionalProperties" => false
      },
      %{"foo" => true, "bar" => true, "baz" => 1, "xyz" => false},
      [
        {"/properties/foo/type", "/foo"},
        {"/patternProperties/^b.*$/type", "/baz"},
        {"/additionalProperties", "/xyz"}
      ]
    )
  end

  test "legacy regression: validation errors for invalid additional properties" do
    assert_invalid(
      %{
        "properties" => %{"foo" => %{"type" => "string"}},
        "additionalProperties" => %{"type" => "boolean"}
      },
      %{"foo" => "bar", "bar" => "baz"},
      [{"/additionalProperties/type", "/bar"}]
    )
  end

  test "legacy regression: validation errors for minimum properties" do
    assert_invalid(%{"minProperties" => 2}, %{"foo" => 1}, [{"/minProperties", ""}])
  end

  test "legacy regression: validation errors for maximum properties" do
    assert_invalid(
      %{"maxProperties" => 1},
      %{"foo" => 1, "bar" => 2},
      [{"/maxProperties", ""}]
    )
  end

  test "legacy regression: validation errors for missing required property" do
    assert_invalid(
      %{"required" => ["foo", "bar", "baz"]},
      %{"foo" => 1, "bar" => 2},
      [{"/required", ""}]
    )
  end

  test "legacy regression: validation errors for missing required properties" do
    assert_invalid(
      %{"required" => ["foo", "bar", "baz"]},
      %{"foo" => 1},
      [{"/required", ""}]
    )
  end

  test "legacy regression: validation errors for dependent property" do
    assert_invalid(
      %{"dependencies" => %{"foo" => ["bar", "baz", "qux"]}},
      %{"foo" => 1, "bar" => 2, "baz" => 3},
      [{"/dependencies", ""}]
    )
  end

  test "legacy regression: validation errors for dependent properties" do
    assert_invalid(
      %{"dependencies" => %{"foo" => ["bar", "baz", "qux"]}},
      %{"foo" => 1, "bar" => 2},
      [{"/dependencies", ""}]
    )
  end

  test "legacy regression: validation errors for schema dependencies" do
    assert_invalid(
      %{"dependencies" => %{"foo" => %{"properties" => %{"bar" => %{"type" => "boolean"}}}}},
      %{"foo" => 1, "bar" => 2},
      [{"/dependencies/foo/properties/bar/type", "/bar"}]
    )
  end

  test "legacy regression: validation errors for invalid items" do
    assert_invalid(
      %{"items" => %{"type" => "string"}},
      ["foo", "bar", 1, %{}],
      [{"/items/type", "/2"}, {"/items/type", "/3"}]
    )
  end

  test "legacy regression: validation errors for items when none are allowed" do
    assert_invalid(
      %{
        "properties" => %{
          "foo" => %{"items" => %{"properties" => %{"bar" => %{"items" => false}}}}
        }
      },
      %{"foo" => [%{"bar" => ["foo"]}, %{"bar" => []}]},
      [{"/properties/foo/items/properties/bar/items", "/foo/0/bar"}]
    )
  end

  test "legacy regression: validation errors for items with false schema" do
    assert_invalid(
      %{"items" => [false, %{"type" => "string"}, false]},
      ["foo", "foo", "foo"],
      [{"/items/0", "/0"}, {"/items/2", "/2"}]
    )
  end

  test "legacy regression: validation errors for an invalid item with a list of item schemata and an invalid additional item" do
    assert_invalid(
      %{
        "items" => [%{"type" => "string"}, %{"type" => "integer"}, %{"type" => "integer"}],
        "additionalItems" => %{"type" => "boolean"}
      },
      [%{}, 1, "foo", true, 2.2],
      [
        {"/items/0/type", "/0"},
        {"/items/2/type", "/2"},
        {"/additionalItems/type", "/4"}
      ]
    )
  end

  test "legacy regression: validation errors for disallowed additional items" do
    assert_invalid(
      %{"items" => [%{"type" => "boolean"}, %{"type" => "string"}], "additionalItems" => false},
      [true, "foo", true, "bar", 5],
      [{"/additionalItems", "/2"}, {"/additionalItems", "/4"}]
    )
  end

  test "legacy regression: validation errors for minimum items" do
    assert_invalid(%{"minItems" => 2}, ["foo"], [{"/minItems", ""}])
  end

  test "legacy regression: validation errors for maximum items" do
    assert_invalid(%{"maxItems" => 2}, ["foo", "bar", "baz"], [{"/maxItems", ""}])
  end

  test "legacy regression: validation errors for non-unique items" do
    assert_invalid(%{"uniqueItems" => true}, [1, 2, 3, 3], [{"/uniqueItems", ""}])
  end

  test "legacy regression: validation errors for value not allowed in enum" do
    assert_invalid(%{"enum" => ["foo", "bar"]}, %{"baz" => 1}, [{"/enum", ""}])
  end

  test "legacy regression: validation errors for minimum values" do
    assert_invalid(
      %{
        "properties" => %{
          "foo" => %{"minimum" => 2},
          "bar" => %{"exclusiveMinimum" => 2}
        }
      },
      %{"foo" => 1, "bar" => 2},
      [
        {"/properties/bar/exclusiveMinimum", "/bar"},
        {"/properties/foo/minimum", "/foo"}
      ]
    )
  end

  test "legacy regression: validation errors for maximum values" do
    assert_invalid(
      %{
        "properties" => %{
          "foo" => %{"maximum" => 2},
          "bar" => %{"exclusiveMaximum" => 2}
        }
      },
      %{"foo" => 3, "bar" => 2},
      [
        {"/properties/bar/exclusiveMaximum", "/bar"},
        {"/properties/foo/maximum", "/foo"}
      ]
    )
  end

  test "legacy regression: validation errors for multiples of" do
    assert_invalid(%{"multipleOf" => 2}, 5, [{"/multipleOf", ""}])
    assert_invalid(%{"multipleOf" => 0.1}, 123.45, [{"/multipleOf", ""}])
    assert_valid(%{"multipleOf" => 5}, 0)
  end

  test "legacy regression: multiple of validator division by 0" do
    assert_raise CompileError, fn ->
      ExJsonSchema.compile!(%{"multipleOf" => 0}, validate_schema: true)
    end
  end

  test "legacy regression: multiple of precision" do
    assert_valid(%{"multipleOf" => 0.01}, 147.41)
    assert_valid(%{"multipleOf" => 0.01}, 147.42)
  end

  test "legacy regression: validation errors for minimum length" do
    assert_invalid(%{"minLength" => 4}, "foo", [{"/minLength", ""}])
  end

  test "legacy regression: validation errors for maximum length" do
    assert_invalid(%{"maxLength" => 2}, "foo", [{"/maxLength", ""}])
  end

  test "legacy regression: validation errors for pattern mismatch" do
    assert_invalid(%{"pattern" => "^b..$"}, "foo", [{"/pattern", ""}])
  end

  test "legacy regression: validation errors for const" do
    assert_invalid(%{"const" => "foo"}, "bar", [{"/const", ""}])
  end

  test "legacy regression: validation errors for contains" do
    assert_invalid(
      %{"properties" => %{"foo" => %{"contains" => %{"type" => "number"}}}},
      %{"foo" => ["foo", %{}]},
      [{"/properties/foo/contains", "/foo"}]
    )
  end

  test "legacy regression: validation errors for contains and empty list" do
    assert_invalid(
      %{"properties" => %{"foo" => %{"contains" => %{"type" => "number"}}}},
      %{"foo" => []},
      [{"/properties/foo/contains", "/foo"}]
    )
  end

  test "legacy regression: validation errors for content encoding" do
    assert_invalid(
      %{"contentEncoding" => "base64"},
      "foo",
      [{"/contentEncoding", ""}],
      content_decoder: &Jason.decode/1
    )
  end

  test "legacy regression: validation errors for content media type" do
    options = [content_decoder: &Jason.decode/1]

    assert_invalid(
      %{"contentEncoding" => "base64", "contentMediaType" => "application/json"},
      Base.encode64("foo"),
      [{"/contentMediaType", ""}],
      options
    )

    assert_invalid(
      %{"contentEncoding" => "something", "contentMediaType" => "application/json"},
      "{:}",
      [{"/contentMediaType", ""}],
      options
    )
  end

  test "legacy regression: validation errors for property names" do
    assert_invalid(
      %{"properties" => %{"foo" => %{"propertyNames" => %{"minLength" => 3, "maxLength" => 5}}}},
      %{"foo" => %{"f" => true, "foo" => true, "barbaz" => true}},
      [
        {"/properties/foo/propertyNames/minLength", "/foo"},
        {"/properties/foo/propertyNames/maxLength", "/foo"}
      ]
    )
  end

  test "legacy regression: validation errors for nested objects" do
    assert_invalid(
      %{
        "properties" => %{
          "foo" => %{"items" => %{"properties" => %{"bar" => %{"type" => "integer"}}}}
        }
      },
      %{"foo" => [%{"bar" => 1}, %{"bar" => "baz"}]},
      [{"/properties/foo/items/properties/bar/type", "/foo/1/bar"}]
    )
  end

  test "legacy regression: format validation always succeeds for non-string values" do
    assert_valid(%{"format" => "date-time"}, false)
  end

  test "legacy correction: format validation succeeds for datetime without tz offset" do
    assert_invalid(
      %{"format" => "date-time"},
      "2012-12-12 12:12:12",
      [{"/format", ""}]
    )
  end

  test "legacy regression: validation errors for date-time format" do
    assert_invalid(
      %{"format" => "date-time"},
      "2012-12-12 12:12:12-1.5",
      [{"/format", ""}]
    )
  end

  test "legacy regression: validation errors for email format" do
    assert_invalid(%{"format" => "email"}, "foo@", [{"/format", ""}])
  end

  test "legacy regression: validation errors for hostname format" do
    assert_invalid(%{"format" => "hostname"}, "-foo-bar-", [{"/format", ""}])
  end

  test "legacy regression: validation errors for ipv4 format" do
    assert_invalid(%{"format" => "ipv4"}, "12.12.12", [{"/format", ""}])
  end

  test "legacy regression: validation errors for ipv6 format" do
    assert_invalid(%{"format" => "ipv6"}, "12:12:12", [{"/format", ""}])
  end

  test "legacy regression: unknown formats are ignored" do
    assert_valid(%{"format" => "custom-format"}, "asdfsadf")
  end

  test "legacy regression: configuring a custom format validator" do
    formats = %{
      "always_error" => fn _value -> {:error, :always_error} end,
      "zipcode" => fn value ->
        if is_binary(value) and Regex.match?(~r/^\d+$/, value),
          do: :ok,
          else: {:error, :invalid_zipcode}
      end
    }

    schema =
      %{
        "properties" => %{
          "error" => %{"format" => "always_error"},
          "zip" => %{"format" => "zipcode"}
        }
      }

    assert_invalid(
      schema,
      %{"error" => ""},
      [{"/properties/error/format", "/error"}],
      formats: formats
    )

    assert_valid(%{"format" => "zipcode"}, "12345", formats: formats)

    assert_invalid(
      schema,
      %{"zip" => "asdf"},
      [{"/properties/zip/format", "/zip"}],
      formats: formats
    )
  end

  test "legacy regression: configuring an anonymous function as custom format validator" do
    formats = %{
      "myformat" => fn
        "mydata" -> :ok
        _value -> {:error, :unexpected_data}
      end
    }

    schema = %{"properties" => %{"error" => %{"format" => "myformat"}}}

    assert_valid(schema, %{"error" => "mydata"}, formats: formats)

    assert_invalid(
      schema,
      %{"error" => ""},
      [{"/properties/error/format", "/error"}],
      formats: formats
    )
  end

  test "legacy replacement: configuring a custom format validator with custom error message" do
    formats = %{"custom" => fn _value -> {:error, :custom_reason} end}

    assert_invalid(
      %{"format" => "custom"},
      "value",
      [{"/format", ""}],
      formats: formats
    )
  end

  test "legacy replacement: passing the formatter as an option" do
    compiled = compile(%{"type" => "string"}, [])

    assert_raise ArgumentError, ~r/unknown validation options/, fn ->
      ExJsonSchema.validate(666, compiled, error_formatter: false)
    end
  end

  test "legacy replacement: using the string formatter by default" do
    compiled = compile(%{"type" => "string"}, [])

    assert %{
             "valid" => false,
             "errors" => [
               %{
                 "instanceLocation" => "",
                 "keywordLocation" => "/type"
               }
             ]
           } = ExJsonSchema.validate(666, compiled)
  end

  defp schema_with_ref do
    %{
      "properties" => %{
        "foo" => %{"$ref" => "http://localhost:1234/subschema.json#/foo"}
      }
    }
  end

  defp compile(schema, options) do
    ExJsonSchema.compile!(schema, Keyword.put_new(options, :validate_schema, false))
  end

  defp assert_valid(schema, instance, options \\ []) do
    schema
    |> compile(options)
    |> assert_valid_compiled(instance)
  end

  defp assert_valid_compiled(compiled, instance) do
    assert ExJsonSchema.valid?(instance, compiled, [])
    assert %{"valid" => true} = ExJsonSchema.validate(instance, compiled, output: :flag)
  end

  defp assert_invalid(schema, instance, locations, options \\ []) do
    schema
    |> compile(options)
    |> assert_invalid_compiled(instance, locations)
  end

  defp assert_invalid_compiled(compiled, instance, locations) do
    refute ExJsonSchema.valid?(instance, compiled, [])

    assert %{"valid" => false, "errors" => errors} =
             output =
             ExJsonSchema.validate(instance, compiled, output: :basic)

    for {keyword_location, instance_location} <- locations do
      assert Enum.any?(errors, fn error ->
               error["keywordLocation"] == keyword_location and
                 error["instanceLocation"] == instance_location
             end),
             """
             expected an error at keyword #{inspect(keyword_location)} and instance #{inspect(instance_location)}
             errors: #{inspect(errors, pretty: true)}
             """
    end

    output
  end
end
