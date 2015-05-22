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
    {root, ref} = resolve_ref(root, ref, scope)
    {root, {"$ref", ref}}
  end

  defp resolve_property(root, tuple, _), do: {root, tuple}

  defp resolve_ref(root, "#", _) do
    {root, fn root -> {root, root.schema} end}
  end

  defp resolve_ref(root, url = "http" <> _, _scope) do
    [url | fragments] = String.split(url, "#")

    if root.refs[url] do
      case fragments do
        [ref = "/" <> _] ->
          {root, fn root -> remote_schema = root.refs[url]; {%Root{schema: remote_schema, refs: root.refs}, resolve(%{"$ref" => "#" <> ref}).schema} end}
        _ ->
          {root, fn root -> remote_schema = root.refs[url]; {%Root{schema: remote_schema, refs: root.refs}, remote_schema} end}
      end
    else
      root = %Root{root | refs: Map.put(root.refs, url, true)}
      remote_schema = fetch_remote_schema(root, url)
      root = %Root{root | refs: Map.put(root.refs, url, remote_schema.schema)}
      case fragments do
        [ref = "/" <> _] ->
          {root, fn root -> {%Root{remote_schema | refs: root.refs}, resolve(%{"$ref" => "#" <> ref}).schema} end}
        _ ->
          {root, fn root -> {%Root{remote_schema | refs: root.refs}, remote_schema.schema} end}
      end
    end
  end

  defp resolve_ref(root, ref, _) do
    ["#" | keys] = String.split(ref, "/")
    keys = Enum.map keys, fn key ->
      if Regex.match?(~r/^[0-9]$/, key) do
        fn :get, data, _ -> Enum.at(data, String.to_integer(key)) end
      else
        key
      end
    end
    {root, fn root -> {root, get_in(root.schema, keys)} end}
  end

  defp fetch_remote_schema(root, url) do
    resolve_root(root, RemoteSchema.get!(url).body)
  end
end
