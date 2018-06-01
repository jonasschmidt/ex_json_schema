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
      "root ref in remote ref: null is valid",
      "root ref in remote ref: object is invalid",
      "root ref in remote ref: string is valid"
    ]
end
