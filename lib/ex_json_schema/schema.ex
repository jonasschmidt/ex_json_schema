defmodule ExJsonSchema.Schema do
  defmodule UnsupportedSchemaVersionError do
    defexception message: "unsupported schema version, only draft 4 is supported"
  end

  defmodule InvalidSchemaError do
    defexception message: "invalid schema"
  end

  defmodule UndefinedRemoteSchemaResolverError do
    defexception message:
                   "trying to resolve a remote schema but no remote schema resolver function is defined"
  end

  defmodule InvalidReferenceError do
    defexception message: "invalid reference"
  end

  alias ExJsonSchema.Schema.Draft4
  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @type ref_path :: [:root | String.t()]
  @type resolved :: ExJsonSchema.data() | %{String.t() =>  (Root.t() -> {Root.t(), resolved}) | ref_path}
  @type invalid_reference_error :: {:error, :invalid_reference}

  @current_draft_schema_url "http://json-schema.org/schema"
  @draft4_schema_url "http://json-schema.org/draft-04/schema"

  @spec resolve(Root.t() | ExJsonSchema.object(), custom_format_validator: {module(), atom()}) ::
          Root.t() | no_return
  def resolve(schema, options \\ [])

  def resolve(root = %Root{}, options) do
    root = %Root{root | custom_format_validator: Keyword.get(options, :custom_format_validator)}
    resolve_root(root)
  end

  def resolve(schema = %{}, options), do: resolve(%Root{schema: schema}, options)

  @spec get_fragment(Root.t(), ref_path | ExJsonSchema.json_path()) ::
          {:ok, resolved} | invalid_reference_error | no_return
  def get_fragment(root = %Root{}, path) when is_binary(path) do
    case resolve_ref(root, path) do
      {:ok, {_root, ref}} -> get_fragment(root, ref)
      error -> error
    end
  end

  def get_fragment(root = %Root{}, [:root | path] = ref) do
    do_get_fragment(root.schema, path, ref)
  end

  def get_fragment(root = %Root{}, [url | path] = ref) when is_binary(url) do
    do_get_fragment(root.refs[url], path, ref)
  end

  @spec get_fragment!(Root.t(), ref_path | ExJsonSchema.json_path()) :: resolved | no_return
  def get_fragment!(schema, ref) do
    case get_fragment(schema, ref) do
      {:ok, schema} -> schema
      {:error, :invalid_reference} -> raise_invalid_reference_error(ref)
    end
  end

  defp resolve_root(root) do
    assert_supported_schema_version(
      Map.get(root.schema, "$schema", @current_draft_schema_url <> "#")
    )

    assert_valid_schema(root.schema)
    {root, schema} = resolve_with_root(root, root.schema)
    %{root | schema: schema}
  end

  defp assert_supported_schema_version(version) do
    unless supported_schema_version?(version), do: raise(UnsupportedSchemaVersionError)
  end

  defp assert_valid_schema(schema) do
    unless meta?(schema) do
      case Validator.validate(resolve(Draft4.schema()), schema, error_formatter: false) do
        {:error, errors} ->
          raise InvalidSchemaError,
            message: "schema did not pass validation against its meta-schema: #{inspect(errors)}"

        _ ->
          nil
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
    scope =
      case URI.parse(scope) do
        %URI{host: nil} -> id
        uri -> uri |> URI.merge(id) |> to_string()
      end

    do_resolve(root, schema, scope)
  end

  defp resolve_with_root(root, schema = %{}, scope), do: do_resolve(root, schema, scope)
  defp resolve_with_root(root, non_schema, _scope), do: {root, non_schema}

  defp do_resolve(root, schema, scope) do
    {root, schema} =
      Enum.reduce(schema, {root, %{}}, fn property, {root, schema} ->
        {root, {k, v}} = resolve_property(root, property, scope)
        {root, Map.put(schema, k, v)}
      end)

    {root, schema |> sanitize_properties_attribute |> sanitize_additional_items_attribute}
  end

  defp resolve_property(root, {key, value}, scope) when is_map(value) do
    {root, resolved} = resolve_with_root(root, value, scope)
    {root, {key, resolved}}
  end

  defp resolve_property(root, {key, values}, scope) when is_list(values) do
    {root, values} =
      Enum.reduce(values, {root, []}, fn value, {root, values} ->
        {root, resolved} = resolve_with_root(root, value, scope)
        {root, [resolved | values]}
      end)

    {root, {key, Enum.reverse(values)}}
  end

  defp resolve_property(root, {"$ref", ref}, scope) do
    scoped_ref =
      case URI.parse(ref) do
        # TODO: this special case is only needed until there is proper support for URL references
        # that point to a local schema (via scope changes)
        %URI{host: nil, path: nil} = uri ->
          to_string(uri)

        ref_uri ->
          case URI.parse(scope) do
            %URI{host: nil} -> ref
            scope_uri -> URI.merge(scope_uri, ref_uri) |> to_string()
          end
      end

    {root, path} = resolve_ref!(root, scoped_ref)
    {root, {"$ref", path}}
  end

  defp resolve_property(root, tuple, _), do: {root, tuple}

  defp resolve_ref(root, "#") do
    {:ok, {root, [root.location]}}
  end

  defp resolve_ref(root, ref) do
    [url | anchor] = String.split(ref, "#")
    ref_path = validate_ref_path(anchor, ref)
    {root, path} = root_and_path_for_url(root, ref_path, url)

    case get_fragment(root, path) do
      {:ok, _schema} -> {:ok, {root, path}}
      error -> error
    end
  end

  defp resolve_ref!(root, ref) do
    case resolve_ref(root, ref) do
      {:ok, result} -> result
      {:error, :invalid_reference} -> raise_invalid_reference_error(ref)
    end
  end

  defp validate_ref_path([], _), do: nil
  defp validate_ref_path([""], _), do: nil
  defp validate_ref_path([fragment = "/" <> _], _), do: fragment
  defp validate_ref_path(_, ref), do: raise_invalid_reference_error(ref)

  defp root_and_path_for_url(root, fragment, "") do
    {root, [root.location | relative_path(fragment)]}
  end

  defp root_and_path_for_url(root, fragment, url) do
    root = resolve_and_cache_remote_schema(root, url)
    {root, [url | relative_path(fragment)]}
  end

  defp relative_path(nil), do: []
  defp relative_path(fragment), do: relative_ref_path(fragment)

  defp relative_ref_path(ref) do
    ["" | keys] = unescaped_ref_segments(ref)

    Enum.map(keys, fn key ->
      case key =~ ~r/^\d+$/ do
        true ->
          String.to_integer(key)

        false ->
          key
      end
    end)
  end

  defp resolve_and_cache_remote_schema(root, url) do
    if root.refs[url], do: root, else: fetch_and_resolve_remote_schema(root, url)
  end

  defp fetch_and_resolve_remote_schema(root, url)
       when url == @current_draft_schema_url or url == @draft4_schema_url do
    resolve_remote_schema(root, url, Draft4.schema())
  end

  defp fetch_and_resolve_remote_schema(root, url) do
    resolve_remote_schema(root, url, fetch_remote_schema(url))
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

  defp fetch_remote_schema(url) do
    case remote_schema_resolver() do
      fun when is_function(fun) -> fun.(url)
      {mod, fun_name} -> apply(mod, fun_name, [url])
    end
  end

  defp remote_schema_resolver do
    Application.get_env(:ex_json_schema, :remote_schema_resolver) ||
      fn _url -> raise UndefinedRemoteSchemaResolverError end
  end

  defp sanitize_properties_attribute(schema) do
    if needs_properties_attribute?(schema), do: Map.put(schema, "properties", %{}), else: schema
  end

  defp needs_properties_attribute?(schema) do
    Enum.any?(~w(patternProperties additionalProperties), &Map.has_key?(schema, &1)) and
      not Map.has_key?(schema, "properties")
  end

  defp sanitize_additional_items_attribute(schema) do
    if needs_additional_items_attribute?(schema),
      do: Map.put(schema, "additionalItems", true),
      else: schema
  end

  defp needs_additional_items_attribute?(schema) do
    Map.has_key?(schema, "items") and is_list(schema["items"]) and
      not Map.has_key?(schema, "additionalItems")
  end

  defp unescaped_ref_segments(ref) do
    ref
    |> String.split("/")
    |> Enum.map(fn segment ->
      segment
      |> String.replace("~0", "~")
      |> String.replace("~1", "/")
      |> URI.decode()
    end)
  end

  defp meta?(schema) do
    String.starts_with?(Map.get(schema, "id", ""), @draft4_schema_url)
  end

  defp do_get_fragment(nil, _, _ref), do: {:error, :invalid_reference}
  defp do_get_fragment(schema, [], _), do: {:ok, schema}

  defp do_get_fragment(schema, [key | path], ref) when is_binary(key),
    do: do_get_fragment(Map.get(schema, key), path, ref)

  defp do_get_fragment(schema, [idx | path], ref) when is_integer(idx) do
    try do
      do_get_fragment(:lists.nth(idx + 1, schema), path, ref)
    catch
      :error, :function_clause -> {:error, :invalid_reference}
    end
  end

  defp ref_to_string([:root | path]), do: ["#" | path] |> Enum.join("/")
  defp ref_to_string([url | path]), do: [url <> "#" | path] |> Enum.join("/")

  @spec raise_invalid_reference_error(any) :: no_return
  def raise_invalid_reference_error(ref) when is_binary(ref),
    do: raise(InvalidReferenceError, message: "invalid reference #{ref}")

  def raise_invalid_reference_error(ref),
    do: ref |> ref_to_string |> raise_invalid_reference_error
end
