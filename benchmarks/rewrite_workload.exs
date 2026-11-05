Code.require_file("measure.exs", __DIR__)

defmodule ExJsonSchema.Benchmark.Adapter do
  @moduledoc false

  def implementation do
    Code.ensure_loaded!(ExJsonSchema)
    if function_exported?(ExJsonSchema, :compile!, 2), do: :rewrite, else: :legacy
  end

  def compile(schema, validate_schema? \\ false) do
    case implementation() do
      :rewrite ->
        options = if validate_schema?, do: [], else: [validate_schema: false]
        apply(ExJsonSchema, :compile!, [schema, options])

      :legacy ->
        apply(ExJsonSchema.Schema, :resolve, [schema])
    end
  end

  def valid?(instance, compiled) do
    case implementation() do
      :rewrite -> apply(ExJsonSchema, :valid?, [instance, compiled])
      :legacy -> apply(ExJsonSchema.Validator, :valid?, [compiled, instance])
    end
  end

  def validate(instance, compiled) do
    case implementation() do
      :rewrite ->
        apply(ExJsonSchema, :validate, [instance, compiled, [output: :basic]])

      :legacy ->
        apply(ExJsonSchema.Validator, :validate, [
          compiled,
          instance,
          [error_formatter: false]
        ])
    end
  end
end

defmodule ExJsonSchema.Benchmark.Workload do
  @moduledoc false

  alias ExJsonSchema.Benchmark.Adapter
  alias ExJsonSchema.Benchmark.Measure

  @draft7 "http://json-schema.org/draft-07/schema#"
  @draft202012 "https://json-schema.org/draft/2020-12/schema"

  def run(options) do
    Application.ensure_all_started(:ex_json_schema)

    results =
      options.sizes
      |> scenarios()
      |> Enum.map(fn scenario ->
        measurement =
          Measure.run(
            scenario.fun,
            options.samples,
            options.target_ms * 1_000
          )

        scenario
        |> Map.drop([:fun])
        |> Map.merge(measurement)
      end)

    %{
      label: options.label,
      implementation: Adapter.implementation(),
      library_version: library_version(),
      elixir: System.version(),
      otp: System.otp_release(),
      schedulers: System.schedulers_online(),
      samples: options.samples,
      target_ms: options.target_ms,
      results: results
    }
  end

  defp scenarios(sizes) do
    Enum.flat_map(sizes, fn size ->
      valid_items = Enum.to_list(1..size)
      invalid_last = List.replace_at(valid_items, size - 1, "invalid")
      contains_first = [1 | List.duplicate(0, size - 1)]
      contains_none = List.duplicate(0, size)
      nested_contains_first = [contains_first]

      items_schema = %{
        "$schema" => @draft7,
        "type" => "array",
        "items" => %{"type" => "integer"}
      }

      true_items_schema = %{
        "$schema" => @draft7,
        "type" => "array",
        "items" => true
      }

      contains_schema = %{
        "$schema" => @draft7,
        "type" => "array",
        "contains" => %{"const" => 1}
      }

      nested_contains_schema = %{
        "$schema" => @draft7,
        "type" => "array",
        "items" => %{
          "type" => "array",
          "contains" => %{"const" => 1}
        }
      }

      unique_schema = %{
        "$schema" => @draft7,
        "type" => "array",
        "uniqueItems" => true
      }

      properties =
        Map.new(1..size, fn index ->
          {"property-#{index}", %{"type" => "integer"}}
        end)

      object = Map.new(1..size, fn index -> {"property-#{index}", index} end)

      object_schema = %{
        "$schema" => @draft7,
        "type" => "object",
        "properties" => properties
      }

      sparse_object = Map.take(object, ["property-1"])

      api_properties =
        Map.merge(properties, %{
          "code" => %{
            "type" => "string",
            "minLength" => 2,
            "maxLength" => 16,
            "pattern" => "^[A-Z]+$"
          },
          "id" => %{
            "type" => "integer",
            "minimum" => 1,
            "maximum" => size + 1,
            "multipleOf" => 1
          },
          "status" => %{"enum" => ["active", "disabled"]}
        })

      api_object =
        object
        |> Map.put("code", "ABC")
        |> Map.put("id", 1)
        |> Map.put("status", "active")

      api_schema = %{
        "$schema" => @draft7,
        "type" => "object",
        "required" => ["id", "status", "code"],
        "minProperties" => 3,
        "properties" => api_properties
      }

      any_of_schema = %{
        "$schema" => @draft7,
        "anyOf" => [%{"const" => 1} | List.duplicate(%{"const" => 0}, size - 1)]
      }

      unused_definitions_schema = %{
        "$schema" => @draft7,
        "definitions" =>
          Map.new(1..size, fn index ->
            {"unused-#{index}", %{"title" => "Unused #{index}"}}
          end),
        "type" => "integer"
      }

      [
        {"items-valid", items_schema, valid_items},
        {"items-invalid-last", items_schema, invalid_last},
        {"items-true", true_items_schema, valid_items},
        {"contains-first", contains_schema, contains_first},
        {"contains-none", contains_schema, contains_none},
        {"nested-contains-first", nested_contains_schema, nested_contains_first},
        {"unique-scalars", unique_schema, valid_items},
        {"object-properties", object_schema, object},
        {"object-sparse", object_schema, sparse_object},
        {"object-api-assertions", api_schema, api_object},
        {"anyOf-first", any_of_schema, 1},
        {"unused-definitions", unused_definitions_schema, 1}
      ]
      |> Enum.flat_map(fn {name, schema, instance} ->
        validation_scenarios(name, size, schema, instance)
      end)
      |> Kernel.++(current_only_scenarios(size, properties, object))
      |> Kernel.++([
        scenario(:compilation, "compile/object-properties", size, fn ->
          Adapter.compile(object_schema)
        end)
      ])
    end)
  end

  defp compile(schema), do: Adapter.compile(schema)

  defp validation_scenarios(name, size, schema, instance) do
    compiled = compile(schema)
    schema_memory = Measure.term_memory(compiled)

    [
      scenario(
        :validity,
        "valid?/#{name}",
        size,
        fn -> Adapter.valid?(instance, compiled) end,
        schema_memory
      ),
      scenario(
        :validation,
        "validate/#{name}",
        size,
        fn -> Adapter.validate(instance, compiled) end,
        schema_memory
      )
    ]
  end

  defp current_only_scenarios(size, properties, object) do
    if Adapter.implementation() == :rewrite do
      validation_scenarios(
        "object-unevaluated",
        size,
        %{
          "$schema" => @draft202012,
          "type" => "object",
          "properties" => properties,
          "unevaluatedProperties" => false
        },
        object
      )
    else
      []
    end
  end

  defp scenario(group, name, size, fun, schema_memory \\ nil) do
    %{group: group, name: name, size: size, fun: fun, schema_memory: schema_memory}
  end

  defp library_version do
    case Application.spec(:ex_json_schema, :vsn) do
      nil -> "unknown"
      version -> to_string(version)
    end
  end
end

defmodule ExJsonSchema.Benchmark.Options do
  @moduledoc false

  def parse(arguments) do
    arguments = if List.first(arguments) == "--", do: tl(arguments), else: arguments

    {options, _remaining, invalid} =
      OptionParser.parse(arguments,
        strict: [label: :string, samples: :integer, target_ms: :integer, sizes: :string]
      )

    if invalid != [], do: raise("invalid benchmark options: #{inspect(invalid)}")

    %{
      label: Keyword.get(options, :label, "run"),
      samples: positive!(Keyword.get(options, :samples, 5), "samples"),
      target_ms: positive!(Keyword.get(options, :target_ms, 100), "target-ms"),
      sizes: parse_sizes(Keyword.get(options, :sizes, "10,100,1000"))
    }
  end

  defp parse_sizes(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(fn size ->
      case Integer.parse(size) do
        {integer, ""} -> positive!(integer, "sizes")
        _ -> raise "sizes must be comma-separated positive integers"
      end
    end)
  end

  defp positive!(value, _name) when is_integer(value) and value > 0, do: value
  defp positive!(_value, name), do: raise("#{name} must be a positive integer")
end

options = ExJsonSchema.Benchmark.Options.parse(System.argv())
result = ExJsonSchema.Benchmark.Workload.run(options)
encoded = result |> :erlang.term_to_binary([:compressed]) |> Base.encode64()
IO.puts("__EX_JSON_SCHEMA_BENCHMARK__#{encoded}")
