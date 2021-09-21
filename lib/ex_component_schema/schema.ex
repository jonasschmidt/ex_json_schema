defmodule ExComponentSchema.Schema do
  defmodule UnsupportedSchemaVersionError do
    defexception message:
                   "Unsupported schema version, only draft 4, 6, 7 and lenra draft are supported."
  end

  defmodule InvalidSchemaError do
    defexception message: "invalid schema"
  end

  defmodule MissingJsonDecoderError do
    defexception message: "JSON decoder not specified."
  end

  defmodule UndefinedRemoteSchemaResolverError do
    defexception message:
                   "trying to resolve a remote schema but no remote schema resolver function is defined"
  end

  defmodule InvalidReferenceError do
    defexception message: "invalid reference"
  end

  alias ExComponentSchema.Schema.Draft4
  alias ExComponentSchema.Schema.Draft6
  alias ExComponentSchema.Schema.Draft7
  alias ExComponentSchema.Schema.DraftLenra
  alias ExComponentSchema.Schema.Root
  alias ExComponentSchema.Validator

  @type ref_path :: [:root | String.t()]
  @type resolved ::
          ExComponentSchema.data()
          | %{String.t() => (Root.t() -> {Root.t(), resolved}) | ref_path}
          | true
          | false
  @type invalid_reference_error :: {:error, :invalid_reference}

  @current_draft_schema_url "http://json-schema.org/schema"
  @draft4_schema_url "http://json-schema.org/draft-04/schema"
  @draft6_schema_url "http://json-schema.org/draft-06/schema"
  @draft7_schema_url "http://json-schema.org/draft-07/schema"
  @draft_lenra_schema_url "https://raw.githubusercontent.com/lenra-io/ex_component_schema/beta/priv/static/draft-lenra.json"

  @spec decode_json(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def decode_json(json) do
    decoder =
      Application.get_env(:ex_component_schema, :decode_json) ||
        fn _json -> raise MissingJsonDecoderError end

    decoder.(json)
  end

  @spec resolve(boolean | Root.t() | ExComponentSchema.object(),
          custom_format_validator: {module(), atom()}
        ) ::
          Root.t() | no_return
  def resolve(schema, options \\ [])

  def resolve(schema, _options) when is_boolean(schema) do
    %Root{schema: schema}
  end

  def resolve(root = %Root{}, options) do
    root = %Root{root | custom_format_validator: Keyword.get(options, :custom_format_validator)}
    resolve_root(root)
  end

  def resolve(schema = %{}, options) do
    resolve(%Root{schema: schema}, options)
  end

  @spec get_fragment(Root.t(), ref_path | ExComponentSchema.json_path()) ::
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

  @spec get_fragment!(Root.t(), ref_path | ExComponentSchema.json_path()) :: resolved | no_return
  def get_fragment!(schema, ref) do
    case get_fragment(schema, ref) do
      {:ok, schema} -> schema
      {:error, :invalid_reference} -> raise_invalid_reference_error(ref)
    end
  end

  @spec get_ref_schema(Root.t(), [:root | String.t()]) :: ExComponentSchema.data() | no_return
  def get_ref_schema(root = %Root{}, [:root | path] = ref) do
    case get_ref_schema_with_schema(root.schema, path, ref) do
      {:error, error} ->
        raise InvalidSchemaError, message: error

      ref_schema ->
        ref_schema
    end
  end

  def get_ref_schema(root = %Root{}, [url | path] = ref) when is_binary(url) do
    case get_ref_schema_with_schema(root.refs[url], path, ref) do
      {:error, error} ->
        raise InvalidSchemaError, message: error

      ref_schema ->
        ref_schema
    end
  end

  @spec resolve_root(boolean | Root.t()) :: Root.t() | no_return
  defp resolve_root(%Root{schema: root_schema} = root) do
    schema_version =
      root_schema
      |> Map.get("$schema", @current_draft_schema_url <> "#")
      |> schema_version!()

    case assert_valid_schema(root_schema) do
      :ok ->
        :ok

      {:error, errors} ->
        raise InvalidSchemaError,
          message: "schema did not pass validation against its meta-schema: #{inspect(errors)}"
    end

    {root, schema} = resolve_with_root(root, root_schema)

    %Root{root | schema: schema, version: schema_version}
  end

  defp schema_version!(schema_url) do
    case schema_module(schema_url, :error) do
      :error -> raise(UnsupportedSchemaVersionError)
      module -> module.version()
    end
  end

  defp schema_module(schema_url, default \\ Draft7)
  defp schema_module(@draft4_schema_url <> _, _), do: Draft4
  defp schema_module(@draft6_schema_url <> _, _), do: Draft6
  defp schema_module(@draft7_schema_url <> _, _), do: Draft7
  defp schema_module(@current_draft_schema_url <> _, _), do: Draft7
  defp schema_module(@draft_lenra_schema_url <> _, _), do: DraftLenra
  defp schema_module(_, default), do: default

  @spec assert_valid_schema(map) :: :ok | {:error, Validator.errors()}
  defp assert_valid_schema(schema) do
    with false <- meta04?(schema),
         false <- meta06?(schema),
         false <- meta07?(schema) do
      schema_module =
        schema
        |> Map.get("$schema", @current_draft_schema_url <> "#")
        |> schema_module()

      schema_module.schema()
      |> resolve()
      |> ExComponentSchema.Validator.validate(schema, error_formatter: false)
    else
      _ -> :ok
    end
  end

  defp resolve_with_root(root, schema, scope \\ "")

  defp resolve_with_root(root, schema = %{"$id" => id}, scope) when is_binary(id) do
    resolve_id(root, schema, scope, id)
  end

  defp resolve_with_root(root, schema = %{"id" => id}, scope) when is_binary(id) do
    resolve_id(root, schema, scope, id)
  end

  defp resolve_with_root(root, schema = %{}, scope), do: do_resolve(root, schema, scope)
  defp resolve_with_root(root, non_schema, _scope), do: {root, non_schema}

  defp resolve_id(root, schema, scope, id) do
    scope =
      case URI.parse(scope) do
        %URI{host: nil} -> id
        uri -> uri |> URI.merge(id) |> to_string()
      end

    do_resolve(root, schema, scope)
  end

  defp do_resolve(root, schema, scope) do
    {root, schema} =
      Enum.reduce(schema, {root, %{}}, fn property, {root, schema} ->
        {root, {k, v}} = resolve_property(root, property, scope)
        {root, Map.put(schema, k, v)}
      end)

    {root, schema |> sanitize_attributes()}
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

  defp resolve_property(root, tuple, _) when is_tuple(tuple), do: {root, tuple}

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
    if root.refs[url] do
      root
    else
      remote_schema = remote_schema(url)
      resolve_remote_schema(root, url, remote_schema)
    end
  end

  @spec remote_schema(String.t()) :: ExComponentSchema.object()
  defp remote_schema(@current_draft_schema_url <> _), do: Draft7.schema()
  defp remote_schema(@draft4_schema_url <> _), do: Draft4.schema()
  defp remote_schema(@draft6_schema_url <> _), do: Draft6.schema()
  defp remote_schema(@draft7_schema_url <> _), do: Draft7.schema()
  defp remote_schema(@draft_lenra_schema_url <> _), do: DraftLenra.schema()
  defp remote_schema(url) when is_bitstring(url), do: fetch_remote_schema(url)

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
    Application.get_env(:ex_component_schema, :remote_schema_resolver) ||
      fn _url -> raise UndefinedRemoteSchemaResolverError end
  end

  defp sanitize_attributes(schema) do
    schema
    |> sanitize_properties_attribute()
    |> sanitize_additional_items_attribute()
    |> sanitize_content_encoding_attribute()
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

  defp sanitize_content_encoding_attribute(schema) do
    if Map.has_key?(schema, "contentMediaType") and not Map.has_key?(schema, "contentEncoding") do
      schema |> Map.put("contentEncoding", nil)
    else
      schema
    end
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

  defp meta04?(%{"$schema" => @draft4_schema_url <> _}), do: true
  defp meta04?(_), do: false

  defp meta06?(%{"$schema" => @draft6_schema_url <> _}), do: true
  defp meta06?(_), do: false

  defp meta07?(%{"$schema" => @draft7_schema_url <> _}), do: true
  defp meta07?(_), do: false

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

  defp get_ref_schema_with_schema(nil, _, ref) do
    {:error, "reference #{ref_to_string(ref)} could not be resolved"}
  end

  defp get_ref_schema_with_schema(schema, [], _) do
    schema
  end

  defp get_ref_schema_with_schema(schema, [key | path], ref) when is_binary(key) do
    schema
    |> Map.get(key)
    |> get_ref_schema_with_schema(path, ref)
  end

  defp get_ref_schema_with_schema(schema, [idx | path], ref) when is_integer(idx) do
    (idx + 1)
    |> :lists.nth(schema)
    |> get_ref_schema_with_schema(path, ref)
  end

  defp ref_to_string([:root | path]), do: ["#" | path] |> Enum.join("/")
  defp ref_to_string([url | path]), do: [url <> "#" | path] |> Enum.join("/")

  @spec raise_invalid_reference_error(any) :: no_return
  def raise_invalid_reference_error(ref) when is_binary(ref),
    do: raise(InvalidReferenceError, message: "invalid reference #{ref}")

  def raise_invalid_reference_error(ref),
    do: ref |> ref_to_string |> raise_invalid_reference_error
end
