defmodule ExJsonSchema.Test.Support.TestSuiteTemplateTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.Test.Support.TestSuiteTemplate

  test "invalid schemas fail instead of becoming invalid payload results" do
    assert_raise CompileError, fn ->
      TestSuiteTemplate.valid?(%{"type" => 123}, "payload")
    end
  end

  test "matches exact and recursive ignored suite names" do
    ignored = ["optional/format/**", "optional/cross-draft"]

    assert TestSuiteTemplate.ignored_suite?("optional/format/uri", ignored)
    assert TestSuiteTemplate.ignored_suite?("optional/cross-draft", ignored)
    refute TestSuiteTemplate.ignored_suite?("optional/float-overflow", ignored)
  end
end
