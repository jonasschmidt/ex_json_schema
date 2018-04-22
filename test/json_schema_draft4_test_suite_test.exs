defmodule ExJsonSchema.JsonSchemaDraft4TestSuiteTest do
  use ExUnit.Case, async: true

  use ExJsonSchema.Test.Support.TestSuiteTemplate,
    schema_tests_path: "test/JSON-Schema-Test-Suite/tests/draft4/",
    schema_url: "http://json-schema.org/draft-04/schema"
end
