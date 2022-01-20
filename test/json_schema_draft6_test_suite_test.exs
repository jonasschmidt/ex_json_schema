defmodule ExJsonSchema.JsonSchemaDraft6TestSuiteTest do
  use ExUnit.Case, async: true

  use ExJsonSchema.Test.Support.TestSuiteTemplate,
    schema_tests_path: "test/JSON-Schema-Test-Suite/tests/draft6/",
    schema_url: "http://json-schema.org/draft-06/schema",
    ignored_suites: [
      "optional/non-bmp-regex",
      "optional/ecmascript-regex",
      # TODO: check this one
      "optional/format/ipv6",
      "optional/float-overflow"
    ],
    ignored_tests: [
      "validation of IP addresses: leading zeroes should be rejected, as they are treated as octals",
      "validation of date-time strings: a valid date-time with a leap second, UTC",
      "validation of date-time strings: a valid date-time with a leap second, with minus offset",
      "validation of URIs: an invalid URI with comma in scheme"
    ]
end
