defmodule ExJsonSchema.Benchmark.Compare do
  @moduledoc false

  @marker "__EX_JSON_SCHEMA_BENCHMARK__"

  def run(arguments) do
    options = parse_options(arguments)
    root = git!(["rev-parse", "--show-toplevel"], File.cwd!()) |> String.trim()
    baseline_commit = git!(["rev-parse", options.baseline_ref], root) |> String.trim()
    temporary = temporary_directory()
    baseline = Path.join(temporary, "baseline")
    workload = Path.join(root, "benchmarks/rewrite_workload.exs")

    File.mkdir_p!(temporary)
    prepare_dependencies!(root)

    try do
      git!(["worktree", "add", "--detach", baseline, baseline_commit], root)
      prepare_legacy_dependencies!(baseline, temporary)

      IO.puts("Running legacy baseline #{String.slice(baseline_commit, 0, 12)}...")
      legacy = workload!(baseline, workload, "legacy", temporary, root, options)

      IO.puts("Running current working tree...")
      rewrite = workload!(root, workload, "rewrite", temporary, root, options)

      report = report(legacy, rewrite, baseline_commit, root, options)
      IO.puts(report)

      if options.output do
        output = Path.expand(options.output, root)
        File.mkdir_p!(Path.dirname(output))
        File.write!(output, report)
        IO.puts("Saved #{Path.relative_to(output, root)}")
      end
    after
      System.cmd("git", ["worktree", "remove", "--force", baseline],
        cd: root,
        stderr_to_stdout: true
      )

      File.rm_rf(temporary)
    end
  end

  defp workload!(checkout, workload, label, temporary, root, options) do
    arguments = [
      "exec",
      "--",
      "mix",
      "run",
      workload,
      "--",
      "--label",
      label,
      "--samples",
      Integer.to_string(options.samples),
      "--target-ms",
      Integer.to_string(options.target_ms),
      "--sizes",
      Enum.join(options.sizes, ",")
    ]

    environment = [
      {"MIX_ENV", "dev"},
      {"MIX_DEPS_PATH", dependency_path(label, temporary, root)}
    ]

    environment =
      if label == "legacy" do
        build = Path.join(temporary, "legacy_build")
        [{"MIX_BUILD_PATH", build} | environment]
      else
        environment
      end

    case System.cmd("mise", arguments,
           cd: checkout,
           env: environment,
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        decode_result!(output)

      {output, status} ->
        raise "benchmark subprocess failed with status #{status}:\n#{output}"
    end
  end

  defp decode_result!(output) do
    encoded =
      output
      |> String.split("\n")
      |> Enum.find_value(fn line ->
        if String.starts_with?(line, @marker),
          do: String.replace_prefix(line, @marker, "")
      end)

    if is_nil(encoded), do: raise("benchmark output did not contain a result:\n#{output}")

    encoded
    |> Base.decode64!()
    |> :erlang.binary_to_term()
  end

  defp report(legacy, rewrite, baseline_commit, root, options) do
    baseline =
      Map.new(legacy.results, fn result ->
        {{result.group, result.name, result.size}, result}
      end)

    dirty = git!(["status", "--short"], root) != ""
    current_commit = git!(["rev-parse", "HEAD"], root) |> String.trim()

    """
    # Legacy vs current benchmark

    Generated at #{DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()}.

    - Baseline: `#{baseline_commit}` (`ex_json_schema` #{legacy.library_version})
    - Current: `#{current_commit}`#{if dirty, do: " with working-tree changes", else: ""} (`ex_json_schema` #{rewrite.library_version})
    - Runtime: Elixir #{rewrite.elixir}, OTP #{rewrite.otp}, #{rewrite.schedulers} schedulers
    - Samples: #{options.samples}; target time per sample: #{options.target_ms} ms
    - Sizes: #{Enum.join(options.sizes, ", ")}

    ## Boolean-only validity

    #{markdown_table(comparison_rows(rewrite.results, baseline, :validity))}

    ## Full public validation

    #{markdown_table(comparison_rows(rewrite.results, baseline, :validation))}

    ## Compilation

    #{markdown_table(comparison_rows(rewrite.results, baseline, :compilation))}

    ## Compiled validator footprint

    #{schema_memory_table(schema_memory_rows(rewrite.results, baseline))}

    Ratios are current divided by legacy; values above `1.00x` are regressions.
    Time is the median wall time per operation. Reductions are measured for one
    operation in an isolated process. Allocation is estimated from words
    reclaimed by BEAM garbage collections over repeated calls. Result and
    retained-schema sizes count shared subterms once; flat schema size counts
    shared subterms each time they are referenced.

    Validation scenarios compile their schema outside the measured operation.
    Shared validation scenarios use Draft 7. `object-unevaluated` is a current-only
    Draft 2020-12 scenario because the legacy release does not support that
    keyword. `compile/*` compares the current no-metaschema-validation path with
    the legacy release's normal resolve path, which always validates its schema.
    Diagnostic output differs by API contract: legacy returns raw error structs
    and current returns standardized basic output.
    """
  end

  defp comparison_rows(results, baseline, group) do
    results
    |> Enum.filter(&(&1.group == group))
    |> Enum.map(fn current ->
      previous = Map.get(baseline, {current.group, current.name, current.size})

      if previous do
        [
          current.name,
          Integer.to_string(current.size),
          number(previous.time_us),
          number(current.time_us),
          ratio(current.time_us, previous.time_us),
          integer(previous.reductions),
          integer(current.reductions),
          ratio(current.reductions, previous.reductions),
          bytes(previous.allocated_bytes),
          bytes(current.allocated_bytes),
          ratio(current.allocated_bytes, previous.allocated_bytes),
          bytes(previous.result_bytes),
          bytes(current.result_bytes),
          ratio(current.result_bytes, previous.result_bytes)
        ]
      else
        [
          current.name,
          Integer.to_string(current.size),
          "n/a",
          number(current.time_us),
          "n/a",
          "n/a",
          integer(current.reductions),
          "n/a",
          "n/a",
          bytes(current.allocated_bytes),
          "n/a",
          "n/a",
          bytes(current.result_bytes),
          "n/a"
        ]
      end
    end)
  end

  defp schema_memory_rows(results, baseline) do
    results
    |> Enum.filter(&(&1.group == :validity))
    |> Enum.map(fn current ->
      previous = Map.get(baseline, {current.group, current.name, current.size})
      current_memory = current.schema_memory

      if previous do
        previous_memory = previous.schema_memory

        [
          String.replace_prefix(current.name, "valid?/", ""),
          Integer.to_string(current.size),
          bytes(previous_memory.retained_bytes),
          bytes(current_memory.retained_bytes),
          ratio(current_memory.retained_bytes, previous_memory.retained_bytes),
          bytes(previous_memory.flat_bytes),
          bytes(current_memory.flat_bytes),
          ratio(current_memory.flat_bytes, previous_memory.flat_bytes)
        ]
      else
        [
          String.replace_prefix(current.name, "valid?/", ""),
          Integer.to_string(current.size),
          "n/a",
          bytes(current_memory.retained_bytes),
          "n/a",
          "n/a",
          bytes(current_memory.flat_bytes),
          "n/a"
        ]
      end
    end)
  end

  defp markdown_table(rows) do
    headers = [
      "Scenario",
      "N",
      "Legacy µs",
      "Current µs",
      "Time",
      "Legacy reductions",
      "Current reductions",
      "Compute",
      "Legacy allocation",
      "Current allocation",
      "Allocation",
      "Legacy result",
      "Current result",
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
      "Legacy retained",
      "Current retained",
      "Retained",
      "Legacy flat",
      "Current flat",
      "Flat"
    ]

    separator = Enum.map(headers, fn _ -> "---" end)

    [headers, separator | rows]
    |> Enum.map_join("\n", fn row -> "| " <> Enum.join(row, " | ") <> " |" end)
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
        strict: [
          baseline_ref: :string,
          output: :string,
          samples: :integer,
          target_ms: :integer,
          sizes: :string
        ]
      )

    if invalid != [], do: raise("invalid benchmark options: #{inspect(invalid)}")

    %{
      baseline_ref: Keyword.get(options, :baseline_ref, "v0.11.5"),
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

  defp temporary_directory do
    suffix = System.unique_integer([:positive, :monotonic])
    Path.join(System.tmp_dir!(), "ex_json_schema-rewrite-benchmark-#{suffix}")
  end

  defp prepare_dependencies!(root) do
    lock = Path.join(root, "mix.lock")
    dependency = Path.join([root, "deps", "jason"])

    unless File.exists?(lock) and File.dir?(dependency) do
      case System.cmd("mise", ["exec", "--", "mix", "deps.get"],
             cd: root,
             env: [{"MIX_ENV", "dev"}],
             stderr_to_stdout: true
           ) do
        {_output, 0} -> :ok
        {output, status} -> raise "mix deps.get failed (#{status}):\n#{output}"
      end
    end
  end

  defp prepare_legacy_dependencies!(baseline, temporary) do
    case System.cmd("mise", ["exec", "--", "mix", "deps.get"],
           cd: baseline,
           env: [
             {"MIX_ENV", "dev"},
             {"MIX_DEPS_PATH", Path.join(temporary, "legacy_deps")}
           ],
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        :ok

      {output, status} ->
        raise "legacy mix deps.get failed (#{status}):\n#{output}"
    end
  end

  defp dependency_path("legacy", temporary, _root),
    do: Path.join(temporary, "legacy_deps")

  defp dependency_path(_label, _temporary, root), do: Path.join(root, "deps")

  defp git!(arguments, directory) do
    case System.cmd("git", arguments, cd: directory, stderr_to_stdout: true) do
      {output, 0} -> output
      {output, status} -> raise "git #{Enum.join(arguments, " ")} failed (#{status}):\n#{output}"
    end
  end
end

ExJsonSchema.Benchmark.Compare.run(System.argv())
