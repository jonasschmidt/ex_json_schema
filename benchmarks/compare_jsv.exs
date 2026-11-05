Mix.install(
  [
    {:ex_json_schema, path: Path.expand("..", __DIR__)},
    {:jsv, "~> 0.26.2"},
    {:decimal, "~> 2.0 or ~> 3.0"}
  ],
  consolidate_protocols: false
)

Code.require_file("measure.exs", __DIR__)

defmodule ExJsonSchema.Benchmark.JSVCompare do
  @moduledoc false

  alias ExJsonSchema.Benchmark.Measure

  @draft202012 "https://json-schema.org/draft/2020-12/schema"

  def run(arguments) do
    options = parse_options(arguments)

    results =
      options.sizes
      |> scenarios()
      |> Enum.map(&measure_scenario(&1, options))

    report = report(results, options)
    IO.puts(report)

    if options.output do
      output = Path.expand(options.output, Path.expand("..", __DIR__))
      File.mkdir_p!(Path.dirname(output))
      File.write!(output, report)
      IO.puts("Saved #{Path.relative_to_cwd(output)}")
    end
  end

  defp scenarios(sizes) do
    Enum.flat_map(sizes, fn size ->
      valid_items = Enum.to_list(1..size)
      invalid_last = List.replace_at(valid_items, size - 1, "invalid")
      contains_first = [1 | List.duplicate(0, size - 1)]
      contains_none = List.duplicate(0, size)
      nested_contains_first = [contains_first]

      items_schema = %{
        "$schema" => @draft202012,
        "type" => "array",
        "items" => %{"type" => "integer"}
      }

      true_items_schema = %{
        "$schema" => @draft202012,
        "type" => "array",
        "items" => true
      }

      contains_schema = %{
        "$schema" => @draft202012,
        "type" => "array",
        "contains" => %{"const" => 1}
      }

      nested_contains_schema = %{
        "$schema" => @draft202012,
        "type" => "array",
        "items" => %{
          "type" => "array",
          "contains" => %{"const" => 1}
        }
      }

      unique_schema = %{
        "$schema" => @draft202012,
        "type" => "array",
        "uniqueItems" => true
      }

      properties =
        Map.new(1..size, fn index ->
          {"property-#{index}", %{"type" => "integer"}}
        end)

      object = Map.new(1..size, fn index -> {"property-#{index}", index} end)

      object_schema = %{
        "$schema" => @draft202012,
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
        "$schema" => @draft202012,
        "type" => "object",
        "required" => ["id", "status", "code"],
        "minProperties" => 3,
        "properties" => api_properties
      }

      any_of_schema = %{
        "$schema" => @draft202012,
        "anyOf" => [%{"const" => 1} | List.duplicate(%{"const" => 0}, size - 1)]
      }

      unused_definitions_schema = %{
        "$schema" => @draft202012,
        "$defs" =>
          Map.new(1..size, fn index ->
            {"unused-#{index}",
             %{
               "title" => "Unused #{index}",
               "unevaluatedProperties" => false
             }}
          end),
        "type" => "integer"
      }

      unevaluated_schema =
        Map.put(object_schema, "unevaluatedProperties", false)

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
        {"object-unevaluated", unevaluated_schema, object},
        {"anyOf-first", any_of_schema, 1},
        {"unused-definitions", unused_definitions_schema, 1}
      ]
      |> Enum.flat_map(fn {name, schema, instance} ->
        validation_scenarios(name, size, schema, instance)
      end)
      |> Kernel.++([compile_scenario("compile/object-properties", size, object_schema)])
    end)
  end

  defp validation_scenarios(name, size, schema, instance) do
    ex_schema = ExJsonSchema.compile!(schema, validate_schema: false)
    jsv_schema = JSV.build!(schema, warnings: :silence)

    schema_memory = %{
      ex_json_schema: Measure.term_memory(ex_schema),
      jsv: Measure.term_memory(jsv_schema)
    }

    [
      %{
        group: :validity,
        name: "valid?/#{name}",
        size: size,
        schema_memory: schema_memory,
        ex_json_schema: fn -> ExJsonSchema.valid?(instance, ex_schema) end,
        jsv: fn -> match?({:ok, _data}, JSV.validate(instance, jsv_schema, cast: false)) end
      },
      %{
        group: :validation,
        name: "validate/basic/#{name}",
        size: size,
        schema_memory: schema_memory,
        ex_json_schema: fn -> ExJsonSchema.validate(instance, ex_schema, output: :basic) end,
        jsv: fn -> JSV.validate(instance, jsv_schema, cast: false) end
      }
    ]
  end

  defp compile_scenario(name, size, schema) do
    %{
      group: :compilation,
      name: name,
      size: size,
      ex_json_schema: fn -> ExJsonSchema.compile!(schema, validate_schema: false) end,
      jsv: fn -> JSV.build!(schema, warnings: :silence) end
    }
  end

  defp measure_scenario(scenario, options) do
    ex_json_schema =
      Measure.run(scenario.ex_json_schema, options.samples, options.target_ms * 1_000)

    jsv = Measure.run(scenario.jsv, options.samples, options.target_ms * 1_000)

    scenario
    |> Map.take([:group, :name, :size, :schema_memory])
    |> Map.merge(%{ex_json_schema: ex_json_schema, jsv: jsv})
  end

  defp report(results, options) do
    """
    # ex_json_schema vs JSV benchmark

    Generated at #{DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()}.

    - ex_json_schema: #{application_version(:ex_json_schema)}
    - JSV: #{application_version(:jsv)}
    - Runtime: Elixir #{System.version()}, OTP #{System.otp_release()}, #{System.schedulers_online()} schedulers
    - Samples: #{options.samples}; target time per sample: #{options.target_ms} ms
    - Sizes: #{Enum.join(options.sizes, ", ")}
    - Dialect: JSON Schema Draft 2020-12

    ## Boolean-only validity

    #{markdown_table(rows(results, :validity))}

    ## Full public validation

    #{markdown_table(rows(results, :validation))}

    ## Compilation

    #{markdown_table(rows(results, :compilation))}

    ## Compiled validator footprint

    #{schema_memory_table(schema_memory_rows(results))}

    Ratios are ex_json_schema divided by JSV; values below `1.00x` favor
    ex_json_schema. Validation schemas are compiled outside measured operations.
    JSV 0.26.2 does not expose `valid?`; the boolean-only rows classify the
    result of `JSV.validate(cast: false)`. They compare the fastest public way
    each library can answer validity, not equivalent internal work.

    Full-validation rows compare
    `ExJsonSchema.validate(output: :basic)` with `JSV.validate(cast: false)`.
    Both execute their public diagnostic validation paths, but their contracts
    differ: ex_json_schema returns standardized JSON Schema output, while JSV
    returns validated data or a `JSV.ValidationError`. Result sizes in these
    rows are therefore not directly comparable. Both validators report a
    failing `contains` keyword as an aggregate match-count error.

    Compilation compares `ExJsonSchema.compile!(validate_schema: false)` with
    `JSV.build!`.

    Time is median wall time per operation. Reductions measure one operation in
    an isolated process. Allocation is estimated from words reclaimed by BEAM
    garbage collections over repeated calls. Result and retained-schema sizes
    count shared subterms once; flat schema size counts shared subterms each
    time they are referenced and approximates the cost of copying a schema
    without preserving sharing.
    """
  end

  defp rows(results, group) do
    results
    |> Enum.filter(&(&1.group == group))
    |> Enum.map(fn result ->
      ex = result.ex_json_schema
      jsv = result.jsv

      [
        result.name,
        Integer.to_string(result.size),
        number(ex.time_us),
        number(jsv.time_us),
        ratio(ex.time_us, jsv.time_us),
        integer(ex.reductions),
        integer(jsv.reductions),
        ratio(ex.reductions, jsv.reductions),
        bytes(ex.allocated_bytes),
        bytes(jsv.allocated_bytes),
        ratio(ex.allocated_bytes, jsv.allocated_bytes),
        bytes(ex.result_bytes),
        bytes(jsv.result_bytes),
        ratio(ex.result_bytes, jsv.result_bytes)
      ]
    end)
  end

  defp schema_memory_rows(results) do
    results
    |> Enum.filter(&(&1.group == :validity))
    |> Enum.map(fn result ->
      ex = result.schema_memory.ex_json_schema
      jsv = result.schema_memory.jsv

      [
        String.replace_prefix(result.name, "valid?/", ""),
        Integer.to_string(result.size),
        bytes(ex.retained_bytes),
        bytes(jsv.retained_bytes),
        ratio(ex.retained_bytes, jsv.retained_bytes),
        bytes(ex.flat_bytes),
        bytes(jsv.flat_bytes),
        ratio(ex.flat_bytes, jsv.flat_bytes)
      ]
    end)
  end

  defp markdown_table(rows) do
    headers = [
      "Scenario",
      "N",
      "ex_json_schema µs",
      "JSV µs",
      "Time",
      "ex_json_schema reductions",
      "JSV reductions",
      "Compute",
      "ex_json_schema allocation",
      "JSV allocation",
      "Allocation",
      "ex_json_schema result",
      "JSV result",
      "Result"
    ]

    separator = Enum.map(headers, fn _ -> "---" end)

    [headers, separator | rows]
    |> Enum.map_join("\n", fn row -> "| " <> Enum.join(row, " | ") <> " |" end)
  end

  defp schema_memory_table(rows) do
    headers = [
      "Scenario",
      "N",
      "ex_json_schema retained",
      "JSV retained",
      "Retained",
      "ex_json_schema flat",
      "JSV flat",
      "Flat"
    ]

    separator = Enum.map(headers, fn _ -> "---" end)

    [headers, separator | rows]
    |> Enum.map_join("\n", fn row -> "| " <> Enum.join(row, " | ") <> " |" end)
  end

  defp application_version(application) do
    application
    |> Application.spec(:vsn)
    |> to_string()
  end

  defp number(value) when value < 10, do: :erlang.float_to_binary(value * 1.0, decimals: 2)
  defp number(value), do: :erlang.float_to_binary(value * 1.0, decimals: 1)
  defp integer(value), do: Integer.to_string(value)

  defp ratio(_current, 0), do: "n/a"
  defp ratio(current, previous), do: :erlang.float_to_binary(current / previous, decimals: 2) <> "x"

  defp bytes(value) when value < 1_024, do: "#{value} B"
  defp bytes(value) when value < 1_048_576, do: "#{Float.round(value / 1_024, 1)} KiB"
  defp bytes(value), do: "#{Float.round(value / 1_048_576, 1)} MiB"

  defp parse_options(arguments) do
    {options, _remaining, invalid} =
      OptionParser.parse(arguments,
        strict: [output: :string, samples: :integer, target_ms: :integer, sizes: :string]
      )

    if invalid != [], do: raise("invalid benchmark options: #{inspect(invalid)}")

    %{
      output: Keyword.get(options, :output),
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

ExJsonSchema.Benchmark.JSVCompare.run(System.argv())
