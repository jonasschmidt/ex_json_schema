defmodule ExJsonSchema.Compiler.URI do
  @moduledoc false

  # Normalizes and resolves schema URI references while preserving JSON
  # Schema fragment semantics.

  @spec normalize(String.t()) :: String.t()
  def normalize(uri) when is_binary(uri) do
    if String.ends_with?(uri, "#"), do: String.trim_trailing(uri, "#"), else: uri
  end

  @spec resolve(String.t() | nil, String.t()) :: {:ok, String.t()} | :error
  def resolve(nil, reference) when is_binary(reference), do: valid_uri(reference)
  def resolve("", reference) when is_binary(reference), do: valid_uri(reference)

  def resolve(base, reference) when is_binary(base) and is_binary(reference) do
    with {:ok, _base} <- valid_uri(base),
         {:ok, _reference} <- valid_uri(reference) do
      cond do
        absolute?(reference) ->
          {:ok, normalize(reference)}

        reference == "" ->
          {:ok, without_fragment(base)}

        String.starts_with?(reference, "#") ->
          {:ok, without_fragment(base) <> reference}

        hierarchical?(base) ->
          merge_hierarchical(base, reference)

        true ->
          :error
      end
    end
  end

  @spec without_fragment(String.t()) :: String.t()
  def without_fragment(uri) when is_binary(uri) do
    uri
    |> String.split("#", parts: 2)
    |> hd()
  end

  @spec split_fragment(String.t()) :: {:ok, String.t(), String.t() | nil} | :error
  def split_fragment(uri) when is_binary(uri) do
    with {:ok, _uri} <- valid_uri(uri) do
      case String.split(uri, "#", parts: 2) do
        [resource] ->
          {:ok, resource, nil}

        [resource, fragment] ->
          case decode_fragment(fragment) do
            {:ok, decoded} -> {:ok, resource, decoded}
            :error -> :error
          end
      end
    end
  end

  @spec with_fragment(String.t(), String.t()) :: String.t()
  def with_fragment(resource, "") when is_binary(resource), do: without_fragment(resource)

  def with_fragment(resource, fragment) when is_binary(resource) and is_binary(fragment) do
    without_fragment(resource) <> "#" <> Elixir.URI.encode(fragment, &fragment_character?/1)
  end

  defp valid_uri(uri) do
    if valid_uri_reference?(uri), do: {:ok, normalize(uri)}, else: :error
  end

  defp valid_uri_reference?(uri) do
    String.valid?(uri) and
      Regex.match?(~r/\A[\x21-\x7E]*\z/, uri) and
      not Regex.match?(~r/[\\\"<>\^`{|}]/, uri) and
      valid_percent_encoding?(uri) and
      valid_scheme_prefix?(uri)
  end

  defp valid_percent_encoding?(uri) do
    uri
    |> String.replace(~r/%[0-9A-Fa-f]{2}/, "")
    |> then(&(not String.contains?(&1, "%")))
  end

  defp valid_scheme_prefix?(uri) do
    first_segment = uri |> String.split(["/", "?", "#"], parts: 2) |> hd()

    case String.split(first_segment, ":", parts: 2) do
      [_relative] -> true
      [scheme, _rest] -> Regex.match?(~r/\A[A-Za-z][A-Za-z0-9+.-]*\z/, scheme)
    end
  end

  defp absolute?(uri), do: Regex.match?(~r/\A[A-Za-z][A-Za-z0-9+.-]*:/, uri)

  defp hierarchical?(base) do
    case Elixir.URI.parse(base) do
      %Elixir.URI{host: host} when is_binary(host) -> true
      %Elixir.URI{path: "/" <> _rest} -> true
      _uri -> false
    end
  end

  defp merge_hierarchical(base, reference) do
    try do
      {:ok, base |> Elixir.URI.merge(reference) |> to_string() |> normalize()}
    rescue
      ArgumentError -> :error
    end
  end

  defp decode_fragment(fragment) do
    {:ok, Elixir.URI.decode(fragment)}
  rescue
    ArgumentError -> :error
  end

  defp fragment_character?(character) do
    Elixir.URI.char_unreserved?(character) or character in ~c"!$&'()*+,;=:@/?"
  end
end
