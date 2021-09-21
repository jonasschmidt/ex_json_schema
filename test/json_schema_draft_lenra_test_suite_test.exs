defmodule ExComponentSchema.JsonSchemaDraftLenraTestSuiteTest do
  use ExUnit.Case, async: true

  use ExComponentSchema.Test.Support.TestSuiteTemplate,
    schema_tests_path: "test/API-component-Test-Suite/tests/",
    schema_url:
      "https://raw.githubusercontent.com/lenra-io/ex_component_schema/beta/priv/static/draft-lenra.json",
    ignored_tests: [
      "Location-independent identifier: match",
      "Location-independent identifier: mismatch",
      "Location-independent identifier with absolute URI: match",
      "Location-independent identifier with absolute URI: mismatch",
      "Location-independent identifier with base URI change in subschema: match",
      "Location-independent identifier with base URI change in subschema: mismatch",
      "Recursive references between schemas: invalid tree",
      "Recursive references between schemas: valid tree",
      "ECMA 262 \\S matches everything but ascii whitespace: latin-1 non-breaking-space matches (unlike e.g. Python)",
      "ECMA 262 \\w matches everything but ascii letters: latin-1 e-acute matches (unlike e.g. Python)",
      "ECMA 262 \\D matches everything but ascii digits: NKO DIGIT ZERO (as \\u escape) matches",
      "ECMA 262 \\D matches everything but ascii digits: NKO DIGIT ZERO matches (unlike e.g. Python)",
      "ECMA 262 regex non-compliance: ECMA 262 has no support for \\Z anchor from .NET",
      "ECMA 262 regex $ does not match trailing newline: matches in Python, but should not in jsonschema"
    ]
end
