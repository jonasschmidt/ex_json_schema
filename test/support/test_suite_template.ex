defmodule ExComponentSchema.Test.Support.TestSuiteTemplate do
  use ExUnit.CaseTemplate

  using opts do
    quote bind_quoted: [opts: opts] do
      alias ExComponentSchema.Test.Support.TestHelpers

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
        |> Enum.each(fn fixture ->
          %{"description" => description, "schema" => schema, "tests" => tests} = fixture

          @schema if is_map(schema), do: Map.put_new(schema, "$schema", @schema_url), else: schema

          Enum.each(tests, fn t ->
            @test t

            if name in @ignored_suites or
                 "#{description}: #{@test["description"]}" in @ignored_tests do
              @tag :skip
            end

            @active [
              "base URI change - change folder in subschema: number is valid"
            ]
            if "#{description}: #{@test["description"]}" in @active and
                 name not in @ignored_tests do
              @tag :only
            end

            @tag String.to_atom("json_schema_" <> name)
            test "[#{name}] #{description}: #{@test["description"]}" do
              validated =
                try do
                  @schema
                  |> ExComponentSchema.Schema.resolve()
                  |> ExComponentSchema.Validator.validate(@test["data"])
                rescue
                  e in ExComponentSchema.Schema.InvalidSchemaError ->
                    {:error, e}
                end

              if @test["valid"] do
                assert :ok = validated
              else
                assert {:error, _} = validated
              end
            end
          end)
        end)
      end)
    end
  end
end
