defmodule ExJsonSchema.JsonSchemaDraft4TestSuiteTest do
  use ExUnit.Case, async: true

  use ExJsonSchema.Test.Support.TestSuiteTemplate,
    schema_tests_path: "test/JSON-Schema-Test-Suite/tests/draft4/",
    schema_url: "http://json-schema.org/draft-04/schema",
    ignored_tests: [
      "Recursive references between schemas: invalid tree",
      "Recursive references between schemas: valid tree",
      "base URI change - change folder in subschema: number is valid",
      "base URI change - change folder in subschema: string is invalid",
      "base URI change - change folder: number is valid",
      "base URI change - change folder: string is invalid",
      "base URI change: base URI change ref valid",
      "fragment within remote ref: remote fragment valid",
      "multiple dependencies subschema: no dependency",
      "multiple dependencies subschema: valid",
      "nested refs: nested ref valid",
      "ref within remote ref: ref within ref valid",
      "remote ref, containing refs itself: remote ref valid",
      "remote ref: remote ref valid",
      "root ref in remote ref: null is valid",
      "root ref in remote ref: object is invalid",
      "root ref in remote ref: string is valid",
      "some languages do not distinguish between different types of numeric value: a float is not an integer even without fractional part",
      "valid definition: valid definition schema"
    ]
end
