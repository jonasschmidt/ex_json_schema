defmodule ExJsonSchema.Schema do
  defmodule UnsupportedSchemaVersionError do
    defexception message: "unsupported schema version, only draft 4 is supported"
  end

  defmodule InvalidSchemaError do
    defexception message: "invalid schema"
  end

  alias ExJsonSchema.Schema.Draft4
  alias ExJsonSchema.Schema.Root

  @type resolved :: %{String.t => ExJsonSchema.json_value | (Root.t -> {Root.t, resolved})}

  @current_draft_schema_url "http://json-schema.org/schema"
  @draft4_schema_url "http://json-schema.org/draft-04/schema"

  @spec resolve(Root.t) :: Root.t | no_return
  def resolve(root = %Root{}), do: resolve_root(root)

  @spec resolve(ExJsonSchema.json) :: Root.t | no_return
  def resolve(schema = %{}), do: resolve_root(%Root{schema: schema})

  @spec get_ref_schema(Root.t, List.t) :: ExJsonSchema.json
  def get_ref_schema(root=%Root{}, [location|t] = ref) do
    case location do
      :root -> get_ref_schema_with_schema(root.schema, t, ref)
      url when is_binary(url) -> get_ref_schema_with_schema(root.refs[url], t, ref)
    end
  end

  defp resolve_root(root) do
    assert_supported_schema_version(Map.get(root.schema, "$schema", @current_draft_schema_url <> "#"))
    assert_valid_schema(root.schema)
    {root, schema} = resolve_with_root(root, root.schema)
    %{root | schema: schema}
  end

  defp assert_supported_schema_version(version) do
    unless supported_schema_version?(version), do: raise UnsupportedSchemaVersionError
  end

  defp assert_valid_schema(schema) do
    unless meta?(schema) do
      case ExJsonSchema.Validator.validate(resolve(Draft4.schema), schema) do
        {:error, errors} ->
          raise InvalidSchemaError, message: "schema did not pass validation against its meta-schema: #{inspect(errors)}"
        _ -> nil
      end
    end
  end

  defp supported_schema_version?(version) do
    case version do
      @current_draft_schema_url <> _ -> true
      @draft4_schema_url <> _ -> true
      _ -> false
    end
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
    {root, schema} = Enum.reduce schema, {root, %{}}, fn (property, {root, schema}) ->
      {root, {k, v}} = resolve_property(root, property, scope)
      {root, Map.put(schema, k, v)}
    end
    {root, schema |> sanitize_properties_attribute |> sanitize_additional_items_attribute}
  end

  defp resolve_property(root, {key, value}, scope) when is_map(value) do
    {root, resolved} = resolve_with_root(root, value, scope)
    {root, {key, resolved}}
  end

  defp resolve_property(root, {key, values}, scope) when is_list(values) do
    {root, values} = Enum.reduce values, {root, []}, fn (value, {root, values}) ->
      {root, resolved} = resolve_with_root(root, value, scope)
      {root, [resolved | values]}
    end
    {root, {key, Enum.reverse(values)}}
  end

  defp resolve_property(root, {"$ref", ref}, scope) do
    ref = String.replace(scope <> ref, "##", "#")
    {root, path} = resolve_ref(root, ref)
    {root, {"$ref", path}}
  end

  defp resolve_property(root, tuple, _), do: {root, tuple}

  defp resolve_ref(root, "#") do
    {root, [root.location]}
  end

  defp resolve_ref(root, ref) do
    [url | fragments] = String.split(ref, "#")
    {root, path} = root_and_path_for_url(root, fragments, url)
    assert_reference_valid(path, root, ref)
    {root, path}
  end

  defp root_and_path_for_url(root, fragments, "") do
    {root, [root.location | relative_path(fragments)]}
  end

  defp root_and_path_for_url(root, fragments, url) do
    root = resolve_and_cache_remote_schema(root, url)
    {root, [url | relative_path(fragments)]}
  end

  defp relative_path([fragment = "/" <> _]), do: relative_ref_path(fragment)
  defp relative_path(_), do: [] 

  defp relative_ref_path(ref) do
    ["" | keys] = unescaped_ref_segments(ref)
    Enum.map keys, fn key ->
      case key =~ ~r/^\d+$/ do
        true ->
          String.to_integer(key) + 1
        false -> key
      end
    end
  end

  defp resolve_and_cache_remote_schema(root, url) do
    if root.refs[url], do: root, else: fetch_and_resolve_remote_schema(root, url)
  end

  defp fetch_and_resolve_remote_schema(root, url)
      when url == @current_draft_schema_url or url == @draft4_schema_url do
    resolve_remote_schema(root, url, Draft4.schema)
  end

  defp fetch_and_resolve_remote_schema(root, url) do
    resolve_remote_schema(root, url, remote_schema_resolver.(url))
  end

  defp resolve_remote_schema(root, url, remote_schema) do
    root = root_with_ref(root, url, remote_schema)
    resolved_root = resolve_root(%{root | schema: remote_schema, location: url})
    root = %{root | refs: resolved_root.refs}
    root_with_ref(root, url, resolved_root.schema)
  end

  defp root_with_ref(root, url, ref) do
    %{root | refs: Map.put(root.refs, url, ref)}
  end

  defp remote_schema_resolver do
    Application.get_env(:ex_json_schema, :remote_schema_resolver)
  end

  defp assert_reference_valid(path, root, _ref) do
    get_ref_schema(root, path)
  end

  defp sanitize_properties_attribute(schema) do
    if needs_properties_attribute?(schema), do: Map.put(schema, "properties", %{}), else: schema
  end

  defp needs_properties_attribute?(schema) do
    Enum.any?(~w(patternProperties additionalProperties), &Map.has_key?(schema, &1))
      and not Map.has_key?(schema, "properties")
  end

  defp sanitize_additional_items_attribute(schema) do
    if needs_additional_items_attribute?(schema), do: Map.put(schema, "additionalItems", true), else: schema
  end

  defp needs_additional_items_attribute?(schema) do
    Map.has_key?(schema, "items") and not Map.has_key?(schema, "additionalItems")
  end

  defp unescaped_ref_segments(ref) do
    ref
    |> String.split("/")
    |> Enum.map(fn segment ->
      segment
      |> String.replace("~0", "~")
      |> String.replace("~1", "/")
      |> URI.decode
    end)
  end

  defp meta?(schema) do
    String.starts_with?(Map.get(schema, "id", ""), @draft4_schema_url)
  end
  
  defp get_ref_schema_with_schema(nil, _, ref) do
    raise InvalidSchemaError, message: "reference #{ref_to_string(ref)} could not be resolved"
  end
  defp get_ref_schema_with_schema(schema, [], _) do
    schema
  end
  defp get_ref_schema_with_schema(schema, [key|t], ref) when is_binary(key) do
    get_ref_schema_with_schema(Map.get(schema, key), t, ref)
  end
  defp get_ref_schema_with_schema(schema, [idx|t], ref) when is_integer(idx) do
    try do
      get_ref_schema_with_schema(:lists.nth(idx, schema), t, ref)
    catch
      :throw, :function_clause ->
        raise InvalidSchemaError, message: "reference #{ref_to_string(ref)} could not be resolved"
    end
  end

  defp ref_to_string([:root|t]) do
    ["#"|t] |> Enum.join("/")
  end
  defp ref_to_string([url|t]) do
    [url <> "#"|t] |> Enum.join("/")
  end
end
