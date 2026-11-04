defmodule ExJsonSchema.Evaluator.Context do
  @moduledoc false

  # Carries schema, instance, dialect, scope, and bookkeeping state through a
  # single evaluation traversal.

  alias ExJsonSchema.CompiledSchema
  alias ExJsonSchema.Compiler.Dialect
  alias ExJsonSchema.Compiler.EvaluationPlan
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Resource

  @type output_format :: :flag | :basic | :detailed | :verbose
  @type t :: %__MODULE__{compiled: CompiledSchema.t()}

  defstruct compiled: nil,
            resource: "",
            resource_data: nil,
            schema_location: nil,
            keyword_location: nil,
            instance_location: %Location{},
            dialect: nil,
            vocabularies: MapSet.new(),
            active_keywords: MapSet.new(),
            keyword_positions: %{},
            keyword_metadata_vocabularies: MapSet.new(),
            keyword_plan: nil,
            dynamic_scope: [],
            output_format: :basic,
            assert_formats?: :default,
            collect_annotations?: true,
            track_evaluated?: false,
            evaluation_path: [],
            seen: MapSet.new()

  @spec new(CompiledSchema.t(), keyword()) :: t()
  def new(compiled, options \\ []) do
    %Location{resource: resource_uri} = entrypoint = CompiledSchema.entrypoint(compiled)

    %Resource{
      canonical_uri: canonical_uri,
      dialect: dialect,
      vocabularies: vocabularies
    } = resource = Map.fetch!(CompiledSchema.resources(compiled), resource_uri)

    output_format = Keyword.get(options, :output, :basic)
    {active_keywords, keyword_positions} = keyword_metadata(resource)

    %__MODULE__{
      compiled: compiled,
      resource: canonical_uri,
      resource_data: resource,
      schema_location: entrypoint,
      keyword_location: if(output_format == :flag, do: nil, else: reporting_location(resource, entrypoint)),
      instance_location: Location.root(),
      dialect: dialect,
      vocabularies: vocabularies,
      active_keywords: active_keywords,
      keyword_positions: keyword_positions,
      keyword_metadata_vocabularies: vocabularies,
      keyword_plan: keyword_plan(resource, entrypoint),
      output_format: output_format,
      assert_formats?: Keyword.get(options, :assert_formats?, :default),
      collect_annotations?: output_format != :flag,
      track_evaluated?: false
    }
  end

  @spec at_schema(t(), Location.t()) :: t()
  def at_schema(
        %__MODULE__{
          resource: current_resource,
          resource_data: current_resource_data,
          compiled: compiled,
          output_format: output_format
        } = context,
        %Location{resource: location_resource} = location
      ) do
    resource =
      if current_resource_data && location_resource == current_resource do
        current_resource_data
      else
        compiled
        |> CompiledSchema.resources()
        |> Map.fetch!(location_resource)
      end

    %Resource{
      canonical_uri: canonical_uri,
      dialect: dialect,
      vocabularies: vocabularies
    } = resource

    resource_changed? = current_resource != canonical_uri

    context = %__MODULE__{
      context
      | resource: canonical_uri,
        resource_data: resource,
        schema_location: location,
        keyword_location:
          if(output_format == :flag,
            do: nil,
            else: reporting_location(resource, location)
          ),
        dialect: dialect,
        vocabularies: vocabularies,
        keyword_plan: keyword_plan(resource, location)
    }

    if resource_changed? do
      {active_keywords, keyword_positions} = keyword_metadata(resource)

      %__MODULE__{
        context
        | active_keywords: active_keywords,
          keyword_positions: keyword_positions,
          keyword_metadata_vocabularies: vocabularies
      }
    else
      context
    end
  end

  @spec at_schema_child(t(), Location.pointer_segment()) :: t()
  def at_schema_child(
        %__MODULE__{
          schema_location: schema_location,
          output_format: output_format,
          keyword_location: keyword_location
        } = context,
        segment
      ) do
    %__MODULE__{
      context
      | schema_location: Location.child(schema_location, segment),
        keyword_plan: nil,
        keyword_location:
          if(output_format == :flag,
            do: nil,
            else: Location.child(keyword_location, segment)
          )
    }
  end

  @spec at_instance_child(t(), Location.pointer_segment()) :: t()
  def at_instance_child(%__MODULE__{instance_location: instance_location} = context, segment) do
    %__MODULE__{context | instance_location: Location.child(instance_location, segment)}
  end

  @spec at_keyword(t(), String.t()) :: t()
  def at_keyword(
        %__MODULE__{
          schema_location: schema_location,
          output_format: output_format,
          keyword_location: keyword_location,
          evaluation_path: evaluation_path
        } = context,
        keyword
      ) do
    %__MODULE__{
      context
      | schema_location: Location.child(schema_location, keyword),
        keyword_plan: nil,
        keyword_location:
          if(output_format == :flag,
            do: nil,
            else: Location.child(keyword_location, keyword)
          ),
        evaluation_path: evaluation_path ++ [keyword]
    }
  end

  @spec push_dynamic_scope(t(), String.t()) :: t()
  def push_dynamic_scope(%__MODULE__{dynamic_scope: dynamic_scope} = context, resource) do
    if List.last(dynamic_scope) == resource do
      context
    else
      %__MODULE__{context | dynamic_scope: dynamic_scope ++ [resource]}
    end
  end

  @spec active_keywords(t()) :: MapSet.t(String.t())
  def active_keywords(%__MODULE__{
        vocabularies: vocabularies,
        keyword_metadata_vocabularies: metadata_vocabularies,
        active_keywords: active_keywords
      }) do
    if vocabularies == metadata_vocabularies do
      active_keywords
    else
      EvaluationPlan.active_keywords(vocabularies)
    end
  end

  defp reporting_location(
         %Resource{origin_location: origin_location, canonical_uri: canonical_uri},
         %Location{pointer: location_pointer}
       ) do
    %Location{resource: origin_resource, pointer: origin_pointer} =
      origin_location || Location.root(canonical_uri)

    %Location{
      resource: origin_resource,
      pointer: origin_pointer ++ location_pointer
    }
  end

  defp keyword_metadata(%Resource{
         vocabularies: vocabularies,
         dialect: %Dialect{keyword_order: keyword_order}
       }) do
    active_keywords = EvaluationPlan.active_keywords(vocabularies)

    keyword_positions =
      keyword_order
      |> Enum.with_index()
      |> Map.new()

    {active_keywords, keyword_positions}
  end

  defp keyword_plan(
         %Resource{evaluation_plans: evaluation_plans},
         %Location{pointer: pointer}
       ) do
    Map.get(evaluation_plans, pointer)
  end
end
