defmodule ExComponentSchema.JsonSchemaDraftLenraTestSuiteTest do
  use ExUnit.Case, async: true

  use ExComponentSchema.Test.Support.TestSuiteTemplate,
    schema_tests_path: "test/API-Component-Test-Suite/tests/",
    schema_url:
      "https://raw.githubusercontent.com/lenra-io/ex_component_schema/beta/priv/static/draft-lenra.json",
    ignored_tests: []
end
