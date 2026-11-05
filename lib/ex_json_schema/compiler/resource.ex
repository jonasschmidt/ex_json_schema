defmodule ExJsonSchema.Compiler.Resource do
  @moduledoc false

  # Stores one canonical schema resource and the indexes required to evaluate
  # locations, anchors, references, and compiled plans within it.

  alias ExJsonSchema.Compiler.Dialect
  alias ExJsonSchema.Compiler.EvaluationPlan
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Reference

  @type t :: %__MODULE__{
          schema: ExJsonSchema.data(),
          retrieval_uri: String.t(),
          canonical_uri: String.t(),
          aliases: MapSet.t(String.t()),
          origin_location: Location.t() | nil,
          dialect: Dialect.t(),
          vocabularies: MapSet.t(String.t()),
          locations: %{String.t() => Location.t()},
          location_index: %{[Location.pointer_segment()] => Location.t()},
          base_uri_overrides: %{[Location.pointer_segment()] => String.t()},
          evaluation_plans: %{[Location.pointer_segment()] => EvaluationPlan.t()},
          nodes: %{
            [Location.pointer_segment()] => {Location.t() | nil, non_neg_integer() | nil}
          },
          plan_table: tuple(),
          anchors: %{String.t() => Location.t()},
          dynamic_anchors: %{String.t() => Location.t()},
          references: %{String.t() => Reference.t()}
        }

  defstruct schema: %{},
            retrieval_uri: "",
            canonical_uri: "",
            aliases: MapSet.new(),
            origin_location: nil,
            dialect: nil,
            vocabularies: MapSet.new(),
            locations: %{},
            location_index: %{},
            base_uri_overrides: %{},
            evaluation_plans: %{},
            nodes: %{},
            plan_table: {},
            anchors: %{},
            dynamic_anchors: %{},
            references: %{}

  @spec fetch_location(t(), [Location.pointer_segment()]) ::
          {:ok, Location.t()} | :error
  def fetch_location(
        %__MODULE__{canonical_uri: canonical_uri, nodes: nodes},
        pointer
      )
      when map_size(nodes) > 0 do
    case Map.fetch(nodes, pointer) do
      {:ok, {nil, _plan}} -> {:ok, %Location{resource: canonical_uri, pointer: pointer}}
      {:ok, {location, _plan}} -> {:ok, location}
      :error -> :error
    end
  end

  def fetch_location(%__MODULE__{location_index: location_index}, pointer),
    do: Map.fetch(location_index, pointer)

  @spec fetch_evaluation_plan(t(), [Location.pointer_segment()]) ::
          {:ok, EvaluationPlan.t()} | :error
  def fetch_evaluation_plan(
        %__MODULE__{nodes: nodes, plan_table: plan_table},
        pointer
      )
      when map_size(nodes) > 0 do
    case Map.fetch(nodes, pointer) do
      {:ok, {_location, plan_index}} when is_integer(plan_index) ->
        {:ok, elem(plan_table, plan_index)}

      {:ok, {_location, nil}} ->
        :error

      :error ->
        :error
    end
  end

  def fetch_evaluation_plan(%__MODULE__{evaluation_plans: evaluation_plans}, pointer),
    do: Map.fetch(evaluation_plans, pointer)
end
