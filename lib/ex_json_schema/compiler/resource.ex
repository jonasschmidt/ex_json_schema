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
            anchors: %{},
            dynamic_anchors: %{},
            references: %{}
end
