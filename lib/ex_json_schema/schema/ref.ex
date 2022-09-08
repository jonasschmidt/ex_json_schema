defmodule ExJsonSchema.Schema.Ref do
  defstruct location: nil, fragment: [], fragment_pointer?: false

  @type t :: %ExJsonSchema.Schema.Ref{
          location: String.t() | nil,
          fragment: [String.t()],
          fragment_pointer?: boolean()
        }

  alias ExJsonSchema.Schema.Root

  def local?(%__MODULE__{location: :root}), do: true
  def local?(%__MODULE__{}), do: false

  def cached?(%__MODULE__{location: url} = ref, %Root{refs: refs}) do
    local?(ref) || Map.has_key?(refs, url) || Map.has_key?(refs, to_string(ref))
  end

  # TODO: this can probably be simplified a bit, plus `authority` is deprecated and replaced by host in future versions
  def merge_scope(scope_1, scope_2) do
    case {URI.parse(scope_1), URI.parse(scope_2)} do
      {%URI{authority: nil, path: "/" <> _} = uri_1, uri_2} ->
        uri = %URI{uri_1 | authority: "dummy"} |> URI.merge(uri_2)
        %URI{uri | authority: nil} |> to_string()

      {%URI{authority: nil}, %URI{path: path}} when is_binary(path) ->
        scope_2

      {%URI{authority: nil} = uri_1, _} ->
        to_string(%URI{uri_1 | fragment: nil}) <> scope_2

      {uri_1, _} ->
        uri_1 |> URI.merge(scope_2) |> to_string()
    end
  end

  def from_string(ref, root) do
    from_uri(URI.parse(ref), root)
  end

  defp from_uri(%URI{authority: nil, path: nil, fragment: fragment}, %Root{location: location}) do
    %__MODULE__{location: location} |> parse_fragment(fragment)
  end

  defp from_uri(%URI{fragment: fragment} = uri, _root) do
    location = %URI{uri | fragment: nil} |> to_string()
    %__MODULE__{location: location} |> parse_fragment(fragment)
  end

  defp parse_fragment(ref, fragment) when fragment in [nil, ""], do: %__MODULE__{ref | fragment: []}

  defp parse_fragment(ref, "/" <> _ = pointer) do
    keys = unescaped_ref_segments(pointer)

    pointer =
      Enum.map(keys, fn key ->
        case key =~ ~r/^\d+$/ do
          true -> String.to_integer(key)
          false -> key
        end
      end)

    %__MODULE__{ref | fragment: pointer, fragment_pointer?: true}
  end

  defp parse_fragment(ref, id), do: %__MODULE__{ref | fragment: [id]}

  defp unescaped_ref_segments(ref) do
    ref
    |> String.split("/")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn segment ->
      segment
      |> String.replace("~0", "~")
      |> String.replace("~1", "/")
      |> URI.decode()
    end)
  end
end

defimpl String.Chars, for: ExJsonSchema.Schema.Ref do
  alias ExJsonSchema.Schema.Ref

  def to_string(%ExJsonSchema.Schema.Ref{location: :root} = ref), do: fragment_to_string(ref)
  def to_string(%ExJsonSchema.Schema.Ref{location: url} = ref), do: url <> fragment_to_string(ref)

  defp fragment_to_string(%Ref{fragment: []}), do: ""
  defp fragment_to_string(%Ref{fragment: fragment, fragment_pointer?: true}), do: "#/" <> Enum.join(fragment, "/")
  defp fragment_to_string(%Ref{fragment: [fragment], fragment_pointer?: false}), do: "#" <> fragment
end
