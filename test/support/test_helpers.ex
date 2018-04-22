defmodule ExJsonSchema.Test.Support.TestHelpers do

  def load_schema_test(name, schema_tests_path) do
    name <> ".json"
    |> schema_test_path(schema_tests_path)
    |> File.read!()
    |> Poison.Parser.parse!()
  end

  defp schema_test_path(filename, schema_tests_path) do
    Path.join(schema_tests_path, filename)
  end
end
