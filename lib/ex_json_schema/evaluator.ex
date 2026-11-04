defmodule ExJsonSchema.Evaluator do
  @moduledoc false

  # Selects optimized or full evaluation paths and projects their results into
  # the requested public output format.

  alias ExJsonSchema.CompiledSchema
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Resource
  alias ExJsonSchema.Evaluator.BasicEngine
  alias ExJsonSchema.Evaluator.Context
  alias ExJsonSchema.Evaluator.Engine
  alias ExJsonSchema.Evaluator.FlagEngine
  alias ExJsonSchema.Evaluator.Output
  alias ExJsonSchema.Evaluator.Result

  @spec evaluate(ExJsonSchema.data(), CompiledSchema.t(), keyword()) :: Result.t()
  def evaluate(instance, compiled, options \\ []) do
    context = Context.new(compiled, options)
    schema = schema_at!(compiled, CompiledSchema.entrypoint(compiled))
    Engine.evaluate(schema, instance, context)
  end

  @spec validate(ExJsonSchema.data(), CompiledSchema.t(), keyword()) :: map()
  def validate(instance, compiled, options \\ []) do
    format = Keyword.get(options, :output, :basic)

    if format == :basic do
      case BasicEngine.validate(instance, compiled) do
        {:ok, output} -> output
        :fallback -> project(instance, compiled, options, format)
      end
    else
      project(instance, compiled, options, format)
    end
  end

  @spec valid?(ExJsonSchema.data(), CompiledSchema.t(), keyword()) :: boolean()
  def valid?(instance, compiled, options \\ []) do
    case FlagEngine.valid?(instance, compiled) do
      {:ok, valid} ->
        valid

      :fallback ->
        %Result{valid: valid} =
          evaluate(instance, compiled, Keyword.put(options, :output, :flag))

        valid
    end
  end

  defp schema_at!(compiled, %Location{resource: resource_uri, pointer: pointer}) do
    %Resource{schema: schema} =
      Map.fetch!(CompiledSchema.resources(compiled), resource_uri)

    Enum.reduce(pointer, schema, &schema_child!/2)
  end

  defp schema_child!(segment, schema) when is_binary(segment), do: Map.fetch!(schema, segment)
  defp schema_child!(segment, schema) when is_integer(segment), do: Enum.fetch!(schema, segment)

  defp project(instance, compiled, options, format) do
    instance
    |> evaluate(compiled, options)
    |> Output.project(format)
  end
end
