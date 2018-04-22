defmodule ExJsonSchema.JsonSchemaDraft6TestSuiteTest do
  use ExUnit.Case, async: true

  use ExJsonSchema.Test.Support.TestSuiteTemplate,
    schema_tests_path: "test/JSON-Schema-Test-Suite/tests/draft6/",
    schema_url: "http://json-schema.org/draft-06/schema"
end
