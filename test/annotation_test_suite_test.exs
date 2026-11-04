defmodule ExJsonSchema.AnnotationTestSuiteTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Evaluator
  alias ExJsonSchema.Evaluator.Annotations

  @tests_path "test/JSON-Schema-Test-Suite/annotations/tests"
  @dialects [
    {4, "http://json-schema.org/draft-04/schema#"},
    {6, "http://json-schema.org/draft-06/schema#"},
    {7, "http://json-schema.org/draft-07/schema#"},
    {2020, "https://json-schema.org/draft/2020-12/schema"}
  ]

  for {version, dialect_uri} <- @dialects do
    test "compatible annotation cases pass for draft #{version}" do
      version = unquote(version)
      dialect_uri = unquote(dialect_uri)

      for path <- Path.wildcard(Path.join(@tests_path, "*.json")),
          test_case <- Jason.decode!(File.read!(path))["suite"],
          compatible?(test_case["compatibility"], version),
          schema_compatible?(test_case["schema"], version),
          test <- test_case["tests"] do
        schema = Map.put_new(test_case["schema"], "$schema", dialect_uri)

        compiled =
          Compiler.compile!(schema,
            resources: test_case["externalSchemas"] || %{},
            content_decoder: &Jason.decode/1,
            validate_schema: false
          )

        actual =
          test["instance"]
          |> Evaluator.evaluate(compiled)
          |> Annotations.collect()

        for assertion <- test["assertions"] do
          key = {assertion["location"], assertion["keyword"]}

          assert Map.get(actual, key, %{}) == assertion["expected"],
                 """
                 #{Path.basename(path)} / #{test_case["description"]}
                 #{inspect(key)}
                 actual: #{inspect(Map.get(actual, key, %{}))}
                 expected: #{inspect(assertion["expected"])}
                 """
        end
      end
    end
  end

  defp compatible?(nil, _version), do: true

  defp compatible?(compatibility, version) do
    compatibility
    |> String.split(",")
    |> Enum.all?(fn constraint ->
      cond do
        String.starts_with?(constraint, "<=") ->
          version <= parse_version(String.trim_leading(constraint, "<="))

        String.starts_with?(constraint, "=") ->
          version == parse_version(String.trim_leading(constraint, "="))

        true ->
          version >= parse_version(constraint)
      end
    end)
  end

  defp parse_version("2019"), do: 2019
  defp parse_version("2020"), do: 2020
  defp parse_version("9999"), do: 9999
  defp parse_version(version), do: String.to_integer(version)

  defp schema_compatible?(%{"$schema" => uri}, version),
    do: version == 2020 and String.contains?(uri, "2020-12")

  defp schema_compatible?(_schema, _version), do: true
end
