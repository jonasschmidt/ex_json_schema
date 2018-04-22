defmodule ExJsonSchema.Test.Support.TestSuiteTemplate do

  use ExUnit.CaseTemplate

  using opts do
    quote bind_quoted: [opts: opts] do

      alias ExJsonSchema.Test.Support.TestHelpers

      @schema_tests_path opts[:schema_tests_path]

      @active [
        # "Recursive references between schemas: valid tree"
      ]

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

          @schema schema

          Enum.each(tests, fn t ->
            @test t
            if Enum.empty?(@active) || "#{description}: #{@test["description"]}" in @active do
              @tag String.to_atom("json_schema_" <> name)
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
            end
          end)
        end)
      end)
    end
  end
end
