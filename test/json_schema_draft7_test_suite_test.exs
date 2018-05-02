defmodule ExJsonSchema.JsonSchemaDraft7TestSuiteTest do
  use ExUnit.Case, async: true

  use ExJsonSchema.Test.Support.TestSuiteTemplate,
    schema_tests_path: "test/JSON-Schema-Test-Suite/tests/draft7/",
    schema_url: "http://json-schema.org/draft-07/schema",
    ignored_suites: [
      "if-then-else",
      "iri"
    ],
    ignored_tests: [
      "Recursive references between schemas: invalid tree",
      "Recursive references between schemas: valid tree",
      "base URI change - change folder in subschema: number is valid",
      "base URI change - change folder in subschema: string is invalid",
      "base URI change - change folder: number is valid",
      "base URI change - change folder: string is invalid",
      "base URI change: base URI change ref valid",
      "invalid definition: invalid definition schema",
      "multiple dependencies subschema: no dependency",
      "multiple dependencies subschema: valid",
      "ref within remote ref: ref within ref valid",
      "remote ref, containing refs itself: remote ref invalid",
      "remote ref, containing refs itself: remote ref valid",
      "root ref in remote ref: null is valid",
      "root ref in remote ref: object is invalid",
      "root ref in remote ref: string is valid",
      "validation of regular expressions: a regular expression with unclosed parens is invalid",
      "validation of string-encoded content based on media type: an invalid JSON document"
    ]
end
