defmodule ExComponentSchema.Test.Support.TestHelpers do
  @spec load_schema_test(name :: String.t(), schema_tests_path :: String.t()) :: map | no_return
  def load_schema_test(name, schema_tests_path) do
    schema_tests_path
    |> Path.join(name <> ".json")
    |> File.read!()
    |> Poison.decode!()
  end
end
