defmodule ExJsonSchema.Benchmark.Measure do
  @moduledoc false

  @word_size :erlang.system_info(:wordsize)

  def run(fun, samples, target_microseconds) do
    fun.()
    iterations = calibrate(fun, target_microseconds)

    timings =
      for _ <- 1..samples do
        :erlang.garbage_collect()
        {elapsed, _result} = :timer.tc(fn -> repeat(fun, iterations) end)
        elapsed / iterations
      end

    once = measure_once(fun)
    allocation_iterations = iterations |> max(10) |> min(1_000)

    %{
      iterations: iterations,
      time_us: median(timings),
      reductions: once.reductions,
      allocated_bytes: measure_allocations(fun, allocation_iterations),
      result_bytes: once.result_bytes
    }
  end

  def term_memory(term) do
    %{
      retained_bytes: :erts_debug.size(term) * @word_size,
      flat_bytes: :erts_debug.flat_size(term) * @word_size
    }
  end

  defp calibrate(fun, target_microseconds) do
    {elapsed, _result} = :timer.tc(fun)

    target_microseconds
    |> Kernel./(max(elapsed, 1))
    |> trunc()
    |> max(1)
    |> min(100_000)
  end

  defp repeat(fun, 1), do: fun.()

  defp repeat(fun, iterations) do
    Enum.reduce(1..iterations, nil, fn _, _ -> fun.() end)
  end

  defp repeat_for_allocation(_fun, 0), do: :ok

  defp repeat_for_allocation(fun, iterations) do
    fun.()
    repeat_for_allocation(fun, iterations - 1)
  end

  defp measure_once(fun) do
    parent = self()

    pid =
      spawn(fn ->
        :erlang.garbage_collect()
        {:reductions, before_reductions} = Process.info(self(), :reductions)
        result = fun.()
        {:reductions, after_reductions} = Process.info(self(), :reductions)

        send(
          parent,
          {:measurement_complete, self(),
           %{
             reductions: after_reductions - before_reductions,
             result_bytes: :erts_debug.size(result) * @word_size
           }}
        )
      end)

    receive do
      {:measurement_complete, ^pid, measurement} ->
        measurement
    after
      30_000 ->
        Process.exit(pid, :kill)
        raise "benchmark measurement timed out"
    end
  end

  defp measure_allocations(fun, iterations) do
    parent = self()

    pid =
      spawn(fn ->
        :erlang.garbage_collect()
        :erlang.trace(self(), true, [:garbage_collection, {:tracer, parent}])

        repeat_for_allocation(fun, iterations)
        :erlang.garbage_collect()

        :erlang.trace(self(), false, [:garbage_collection])
        trace_reference = :erlang.trace_delivered(self())

        receive do
          {:trace_delivered, _tracee, ^trace_reference} ->
            send(parent, {:allocation_measurement_complete, self()})
        end
      end)

    receive_allocations(pid, iterations, nil, 0)
  end

  defp receive_allocations(pid, iterations, active_words, reclaimed_words) do
    receive do
      {:trace, ^pid, event, info} when event in [:gc_minor_start, :gc_major_start] ->
        receive_allocations(pid, iterations, used_heap_words(info), reclaimed_words)

      {:trace, ^pid, event, info} when event in [:gc_minor_end, :gc_major_end] ->
        reclaimed =
          if is_integer(active_words) do
            max(active_words - used_heap_words(info), 0)
          else
            0
          end

        receive_allocations(pid, iterations, nil, reclaimed_words + reclaimed)

      {:allocation_measurement_complete, ^pid} ->
        div(reclaimed_words * @word_size, iterations)
    after
      30_000 ->
        Process.exit(pid, :kill)
        raise "allocation measurement timed out"
    end
  end

  defp used_heap_words(info) do
    Keyword.get(info, :heap_size, 0) + Keyword.get(info, :old_heap_size, 0)
  end

  defp median(values) do
    sorted = Enum.sort(values)
    Enum.at(sorted, div(length(sorted), 2))
  end
end
