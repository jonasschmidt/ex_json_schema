defmodule ExJsonSchema.Compiler.Location do
  @moduledoc false

  # Identifies a schema location by its containing resource and decoded JSON
  # Pointer segments.

  alias ExJsonSchema.Compiler.Pointer
  alias ExJsonSchema.Compiler.URI, as: SchemaURI

  @type pointer_segment :: String.t() | non_neg_integer()
  @type t :: %__MODULE__{
          resource: String.t() | nil,
          pointer: [pointer_segment()]
        }

  defstruct resource: nil, pointer: []

  @spec root(String.t() | nil) :: t()
  def root(resource \\ nil), do: %__MODULE__{resource: resource}

  @spec child(t(), pointer_segment()) :: t()
  def child(%__MODULE__{pointer: pointer} = location, segment)
      when is_binary(segment) or is_integer(segment) do
    %__MODULE__{location | pointer: pointer ++ [segment]}
  end

  @spec pointer(t()) :: String.t()
  def pointer(%__MODULE__{pointer: segments}), do: Pointer.encode(segments)

  @spec fragment(t()) :: String.t()
  def fragment(location), do: "#" <> pointer(location)

  @spec absolute_uri(t()) :: String.t() | nil
  def absolute_uri(%__MODULE__{resource: nil}), do: nil
  def absolute_uri(%__MODULE__{resource: ""}), do: nil

  def absolute_uri(%__MODULE__{resource: resource} = location) do
    SchemaURI.with_fragment(resource, pointer(location))
  end

  @spec from_pointer(String.t() | nil, String.t()) :: {:ok, t()} | :error
  def from_pointer(resource, pointer) do
    case Pointer.decode(pointer) do
      {:ok, segments} -> {:ok, %__MODULE__{resource: resource, pointer: segments}}
      :error -> :error
    end
  end
end
