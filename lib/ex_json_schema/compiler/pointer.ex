defmodule ExJsonSchema.Compiler.Pointer do
  @moduledoc false

  # Encodes and decodes RFC 6901 JSON Pointer paths used for schema locations.

  @type segment :: String.t() | non_neg_integer()

  @spec encode([segment()]) :: String.t()
  def encode([]), do: ""

  def encode(segments) when is_list(segments) do
    "/" <> Enum.map_join(segments, "/", &encode_segment/1)
  end

  @spec decode(String.t()) :: {:ok, [String.t()]} | :error
  def decode(""), do: {:ok, []}

  def decode("/" <> pointer) do
    segments =
      pointer
      |> String.split("/", trim: false)
      |> Enum.map(&decode_segment/1)

    if Enum.any?(segments, &(&1 == :error)) do
      :error
    else
      {:ok, segments}
    end
  end

  def decode(_pointer), do: :error

  @spec encode_segment(segment()) :: String.t()
  def encode_segment(segment) when is_integer(segment) and segment >= 0,
    do: Integer.to_string(segment)

  def encode_segment(segment) when is_binary(segment) do
    segment
    |> String.replace("~", "~0")
    |> String.replace("/", "~1")
  end

  @spec decode_segment(String.t()) :: String.t() | :error
  def decode_segment(segment) when is_binary(segment), do: unescape(segment, "")

  defp unescape(<<>>, decoded), do: decoded
  defp unescape(<<"~0", rest::binary>>, decoded), do: unescape(rest, decoded <> "~")
  defp unescape(<<"~1", rest::binary>>, decoded), do: unescape(rest, decoded <> "/")
  defp unescape(<<"~", _rest::binary>>, _decoded), do: :error

  defp unescape(<<codepoint::utf8, rest::binary>>, decoded),
    do: unescape(rest, decoded <> <<codepoint::utf8>>)
end
