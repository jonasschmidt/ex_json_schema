defmodule ExJsonSchema.Test.Support.TestSuiteTemplate do
  use ExUnit.CaseTemplate

  using opts do
    quote bind_quoted: [opts: opts] do
      alias ExJsonSchema.Test.Support.TestHelpers

      @schema_tests_path opts[:schema_tests_path]
      @schema_url opts[:schema_url]

      @ignored_suites Keyword.get(opts, :ignored_suites, [])
      @ignored_tests Keyword.get(opts, :ignored_tests, [])

      "#{@schema_tests_path}**/*.json"
      |> Path.wildcard()
      |> Enum.map(fn path ->
        name =
          path
          |> String.replace(@schema_tests_path, "")
          |> String.replace(".json", "")

        name
        |> TestHelpers.load_schema_test(@schema_tests_path)
        |> Enum.uniq_by(& &1["description"])
        |> Enum.each(fn %{"description" => description, "schema" => schema, "tests" => tests} ->
          @schema if is_map(schema), do: Map.put_new(schema, "$schema", @schema_url), else: schema

          tests
          |> Enum.each(fn t ->
            @test t

            if name in @ignored_suites or
                 "#{description}: #{@test["description"]}" in @ignored_tests do
              @tag :skip
            end

            @active [
              "refs with relative uris and defs"
            ]
            if description in @active and
                 name not in @ignored_tests do
              @tag :only
            end

            @tag String.to_atom(name)
            test "[#{name}] #{description}: #{@test["description"]}" do
              valid? =
                try do
                  @schema
                  |> ExJsonSchema.Schema.resolve()
                  |> ExJsonSchema.Validator.valid?(@test["data"])
                rescue
                  e in ExJsonSchema.Schema.InvalidSchemaError ->
                    false
                end

              assert(valid? == @test["valid"])
            end
          end)
        end)
      end)
    end
  end
end
