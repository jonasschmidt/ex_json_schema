defmodule ExJsonSchema.Test.Support.TestSuiteTemplate do
  use ExUnit.CaseTemplate

  alias ExJsonSchema.Test.Support.TestHelpers

  @remote_schemas TestHelpers.remote_schemas()

  def compile!(schema) do
    ExJsonSchema.Compiler.compile!(schema,
      resources: @remote_schemas,
      content_decoder: &Jason.decode/1
    )
  end

  def valid?(
        %{"$schema" => "https://json-schema.org/draft/2020-12/schema" <> _rest} = schema,
        data
      ) do
    compiled_valid?(schema, data)
  end

  def valid?(
        %{"$schema" => "http://localhost:1234/draft2020-12/" <> _rest} = schema,
        data
      ) do
    compiled_valid?(schema, data)
  end

  def valid?(schema, data) do
    compiled_valid?(schema, data)
  end

  defp compiled_valid?(schema, data) do
    schema
    |> compile!()
    |> then(&ExJsonSchema.Evaluator.valid?(data, &1))
  end

  def ignored_suite?(name, ignored_suites) do
    Enum.any?(ignored_suites, fn
      pattern when is_binary(pattern) ->
        case String.split(pattern, "/**", parts: 2) do
          [^pattern] -> name == pattern
          [prefix, ""] -> String.starts_with?(name, prefix)
        end
    end)
  end

  using opts do
    quote bind_quoted: [opts: opts] do
      alias ExJsonSchema.Test.Support.TestHelpers
      alias ExJsonSchema.Test.Support.OutputAssertions
      alias ExJsonSchema.Test.Support.TestSuiteTemplate

      @schema_tests_path opts[:schema_tests_path]
      @schema_url opts[:schema_url]
      @assert_outputs? Keyword.get(opts, :assert_outputs?, false)

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

            if TestSuiteTemplate.ignored_suite?(name, @ignored_suites) or
                 "#{description}: #{@test["description"]}" in @ignored_tests do
              @tag :skip
            end

            @tag String.to_atom("json_schema_" <> name)
            test "[#{name}] #{description}: #{@test["description"]}" do
              compiled = TestSuiteTemplate.compile!(@schema)
              valid? = ExJsonSchema.Evaluator.valid?(@test["data"], compiled)
              assert(valid? == @test["valid"])

              if @assert_outputs? do
                assert :ok =
                         OutputAssertions.assert_all!(
                           @test["data"],
                           compiled,
                           @test["valid"]
                         )
              end
            end
          end)
        end)
      end)
    end
  end
end
