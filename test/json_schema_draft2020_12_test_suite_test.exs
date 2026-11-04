defmodule ExJsonSchema.JsonSchemaDraft202012TestSuiteTest do
  use ExUnit.Case, async: true

  use ExJsonSchema.Test.Support.TestSuiteTemplate,
    schema_tests_path: "test/JSON-Schema-Test-Suite/tests/draft2020-12/",
    schema_url: "https://json-schema.org/draft/2020-12/schema",
    ignored_suites: [
      "optional/**"
    ]
end
