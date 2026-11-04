defmodule ExJsonSchema.CompiledSchema do
  @moduledoc """
  An opaque, reusable compiled JSON Schema.

  Values of this type are created by the `ExJsonSchema` compilation API. Their
  internal resource graph is intentionally not part of the public contract.
  """

  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Resource

  @opaque t :: %__MODULE__{
            resources: %{String.t() => Resource.t()},
            aliases: %{String.t() => String.t()},
            entrypoint: Location.t(),
            formats: %{String.t() => ExJsonSchema.callback()},
            content_decoder: ExJsonSchema.callback() | nil,
            annotations?: boolean(),
            track_evaluated?: boolean(),
            basic_success_output: map()
          }

  @doc false
  defstruct resources: %{},
            aliases: %{},
            entrypoint: nil,
            formats: %{},
            content_decoder: nil,
            annotations?: false,
            track_evaluated?: false,
            basic_success_output: %{}

  @doc false
  @spec new(keyword()) :: t()
  def new(attributes) do
    %__MODULE__{
      resources: resources,
      entrypoint: entrypoint
    } = compiled = struct!(__MODULE__, attributes)

    %__MODULE__{
      compiled
      | basic_success_output: basic_success_output(resources, entrypoint)
    }
  end

  @doc false
  @spec resources(t()) :: %{String.t() => Resource.t()}
  def resources(%__MODULE__{resources: resources}), do: resources

  @doc false
  @spec aliases(t()) :: %{String.t() => String.t()}
  def aliases(%__MODULE__{aliases: aliases}), do: aliases

  @doc false
  @spec entrypoint(t()) :: Location.t()
  def entrypoint(%__MODULE__{entrypoint: entrypoint}), do: entrypoint

  @doc false
  @spec formats(t()) :: %{String.t() => ExJsonSchema.callback()}
  def formats(%__MODULE__{formats: formats}), do: formats

  @doc false
  @spec content_decoder(t()) :: ExJsonSchema.callback() | nil
  def content_decoder(%__MODULE__{content_decoder: content_decoder}), do: content_decoder

  @doc false
  @spec annotations?(t()) :: boolean()
  def annotations?(%__MODULE__{annotations?: annotations?}), do: annotations?

  @doc false
  @spec track_evaluated?(t()) :: boolean()
  def track_evaluated?(%__MODULE__{track_evaluated?: track_evaluated?}),
    do: track_evaluated?

  @doc false
  @spec basic_success_output(t()) :: map()
  def basic_success_output(%__MODULE__{basic_success_output: output}), do: output

  @doc false
  @spec with_entrypoint(t(), Location.t()) :: t()
  def with_entrypoint(%__MODULE__{resources: resources} = compiled, entrypoint) do
    %__MODULE__{
      compiled
      | entrypoint: entrypoint,
        basic_success_output: basic_success_output(resources, entrypoint)
    }
  end

  @doc false
  @spec with_resources(t(), %{String.t() => Resource.t()}) :: t()
  def with_resources(%__MODULE__{} = compiled, resources) do
    %__MODULE__{compiled | resources: resources}
  end

  defp basic_success_output(
         resources,
         %Location{resource: resource_uri, pointer: pointer}
       ) do
    %Resource{
      origin_location: origin_location,
      canonical_uri: canonical_uri
    } = Map.fetch!(resources, resource_uri)

    %Location{resource: origin_resource, pointer: origin_pointer} =
      origin_location || Location.root(canonical_uri)

    absolute_keyword_location =
      Location.absolute_uri(%Location{resource: canonical_uri, pointer: pointer})

    %{
      "valid" => true,
      "keywordLocation" =>
        Location.pointer(%Location{
          resource: origin_resource,
          pointer: origin_pointer ++ pointer
        }),
      "instanceLocation" => ""
    }
    |> maybe_put_absolute(absolute_keyword_location)
  end

  defp maybe_put_absolute(output, nil), do: output

  defp maybe_put_absolute(output, absolute_keyword_location),
    do: Map.put(output, "absoluteKeywordLocation", absolute_keyword_location)
end
