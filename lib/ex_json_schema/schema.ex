defmodule ExJsonSchema.Schema do
  defmodule RemoteSchema do
    use HTTPoison.Base

    def process_url(url) do
      url
    end

    def process_response_body(body) do
      body |> Poison.Parser.parse!
    end
  end

  defmodule Root do
    defstruct schema: %{}, refs: %{}
  end

  def resolve(root = %Root{}), do: resolve_root(root, root.schema)

  def resolve(schema = %{}), do: resolve_root(%Root{schema: schema}, schema)

  def resolve(non_schema), do: non_schema

  defp resolve_root(root, schema) do
    {root, schema} = resolve_with_root(root, schema)
    %Root{root | schema: schema}
  end

  defp resolve_with_root(root, schema, scope \\ "")

  defp resolve_with_root(root, schema = %{"id" => id}, scope) when is_binary(id) do
    do_resolve(root, schema, scope <> id)
  end

  defp resolve_with_root(root, schema = %{}, scope) do
    do_resolve(root, schema, scope)
  end

  defp resolve_with_root(root, non_schema, _scope) do
    {root, non_schema}
  end

  defp do_resolve(root, schema, scope) do
    schema
    |> Enum.reduce {root, schema}, fn (property, {root, schema}) ->
      {root, {k, v}} = resolve_property(root, property, scope)
      {root, Map.put(schema, k, v)}
    end
  end

  defp resolve_property(root, {key, value}, scope) when is_map(value) do
    {root, resolved} = resolve_with_root(root, value, scope)
    {root, {key, resolved}}
  end

  defp resolve_property(root, {key, values}, scope) when is_list(values) do
    {root, values} = Enum.reduce values, {root, []}, fn (value, {root, values}) ->
      {root, resolved} = resolve_with_root(root, value, scope)
      {root, values ++ [resolved]}
    end
    {root, {key, values}}
  end

  defp resolve_property(root, {"$ref", ref}, scope) do
    ref = String.replace(scope <> ref, "##", "#")
    {root, ref} = resolve_ref(root, ref)
    {root, {"$ref", ref}}
  end

  defp resolve_property(root, tuple, _), do: {root, tuple}

  defp resolve_ref(root, "#") do
    {root, &root_schema_resolver/1}
  end

  defp resolve_ref(root, url = "http" <> _) do
    [url | fragments] = String.split(url, "#")
    {resolve_and_cache_remote_schema(root, url), url_ref_resolver(url, fragments)}
  end

  defp resolve_ref(root, ref = "#" <> _) do
    {root, relative_ref_resolver(ref)}
  end

  defp relative_ref_resolver(ref) do
    ["#" | keys] = String.split(ref, "/")
    keys = Enum.map keys, fn key ->
      if Regex.match?(~r/^[0-9]$/, key) do
        fn :get, data, _ -> Enum.at(data, String.to_integer(key)) end
      else
        key
      end
    end
    fn root -> {root, get_in(root.schema, keys)} end
  end

  defp url_ref_resolver(url, [ref = "/" <> _]) do
    url_with_relative_ref_resolver(url, relative_ref_resolver("#" <> ref))
  end

  defp url_ref_resolver(url, _) do
    url_with_relative_ref_resolver(url, &root_schema_resolver/1)
  end

  defp url_with_relative_ref_resolver(url, relative_ref_resolver) do
    fn root ->
      remote_schema = root.refs[url]
      relative_ref_resolver.(%{root | schema: remote_schema})
    end
  end

  defp root_schema_resolver(root) do
    {root, root.schema}
  end

  defp resolve_and_cache_remote_schema(root, url) do
    unless root.refs[url] do
      remote_schema = RemoteSchema.get!(url).body
      root = root_with_ref(root, url, true)
      resolved_root = resolve_root(root, remote_schema)
      root = root_with_ref(root, url, resolved_root.schema)
    end
    root
  end

  defp root_with_ref(root, url, ref) do
    %{root | refs: Map.put(root.refs, url, ref)}
  end
end
