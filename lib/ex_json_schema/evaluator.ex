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
  alias ExJsonSchema.Evaluator.Options
  alias ExJsonSchema.Evaluator.Output
  alias ExJsonSchema.Evaluator.PlanEngine
  alias ExJsonSchema.Evaluator.Result

  @spec evaluate(ExJsonSchema.data(), CompiledSchema.t()) :: Result.t()
  def evaluate(instance, compiled), do: evaluate(instance, compiled, %Options{})

  @spec evaluate(ExJsonSchema.data(), CompiledSchema.t(), keyword() | Options.t()) :: Result.t()
  def evaluate(instance, compiled, options) when is_list(options) do
    evaluate(instance, compiled, Options.parse!(options))
  end

  def evaluate(instance, compiled, %Options{} = options) do
    context = Context.new(compiled, options)
    schema = schema_at!(compiled, CompiledSchema.entrypoint(compiled))
    Engine.evaluate(schema, instance, context)
  end

  @spec validate(ExJsonSchema.data(), CompiledSchema.t()) :: map()
  def validate(instance, compiled), do: validate(instance, compiled, %Options{})

  @spec validate(ExJsonSchema.data(), CompiledSchema.t(), keyword() | Options.t()) :: map()
  def validate(instance, compiled, options) when is_list(options) do
    validate(instance, compiled, Options.parse!(options))
  end

  def validate(instance, compiled, %Options{output: format} = options) do
    if format == :basic do
      case BasicEngine.validate(instance, compiled) do
        {:ok, output} -> output
        :fallback -> project(instance, compiled, options, format)
      end
    else
      project(instance, compiled, options, format)
    end
  end

  @spec valid?(ExJsonSchema.data(), CompiledSchema.t()) :: boolean()
  def valid?(instance, compiled), do: valid?(instance, compiled, %Options{})

  @spec valid?(ExJsonSchema.data(), CompiledSchema.t(), keyword() | Options.t()) :: boolean()
  def valid?(instance, compiled, options) when is_list(options) do
    valid?(instance, compiled, Options.parse!(options))
  end

  def valid?(instance, compiled, %Options{} = options) do
    case PlanEngine.valid?(instance, compiled) do
      {:ok, valid} ->
        valid

      :fallback ->
        %Result{valid: valid} =
          evaluate(instance, compiled, %Options{options | output: :flag})

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
