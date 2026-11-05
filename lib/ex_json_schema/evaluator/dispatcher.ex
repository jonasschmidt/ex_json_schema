defmodule ExJsonSchema.Evaluator.Dispatcher do
  @moduledoc false

  # Selects the precompiled keyword phases for a location or derives them when
  # a reusable plan is unavailable.

  alias ExJsonSchema.Compiler.EvaluationPlan
  alias ExJsonSchema.Evaluator.Context

  @spec phases(Context.t(), map()) :: EvaluationPlan.t()
  def phases(
        %Context{
          keyword_plan: keyword_plan,
          vocabularies: vocabularies,
          keyword_metadata_vocabularies: metadata_vocabularies,
          dialect: dialect
        },
        schema
      )
      when is_map(schema) do
    if keyword_plan && vocabularies == metadata_vocabularies do
      keyword_plan
    else
      EvaluationPlan.new(schema, dialect, vocabularies)
    end
  end

  @spec active_keyword?(Context.t(), String.t()) :: boolean()
  def active_keyword?(%Context{} = context, keyword) do
    context
    |> Context.active_keywords()
    |> MapSet.member?(keyword)
  end
end
