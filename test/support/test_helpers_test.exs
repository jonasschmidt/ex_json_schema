defmodule ExJsonSchema.Test.Support.TestHelpersTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Test.Support.TestHelpers

  test "registers versioned official remote schemas" do
    schemas = TestHelpers.remote_schemas()

    assert get_in(schemas, ["http://localhost:1234/draft4/subSchemas.json", "definitions", "integer"]) ==
             %{"type" => "integer"}

    assert get_in(schemas, ["http://localhost:1234/draft6/subSchemas.json", "definitions", "integer"]) ==
             %{"type" => "integer"}

    assert get_in(schemas, ["http://localhost:1234/draft7/subSchemas.json", "definitions", "integer"]) ==
             %{"type" => "integer"}

    assert is_map(schemas["http://localhost:1234/draft2020-12/subSchemas.json"])
  end

  test "loads a versioned remote without HTTP" do
    assert get_in(
             TestHelpers.remote_schema!("http://localhost:1234/draft7/subSchemas.json"),
             ["definitions", "integer"]
           ) ==
             %{"type" => "integer"}
  end
end
