defmodule ExJsonSchema.Schema do
  defmodule UnsupportedSchemaVersionError do
    defexception message: "Unsupported schema version, only draft 4, 6, and 7 are supported."
  end

  defmodule InvalidSchemaError do
    defexception message: "invalid schema"
  end

  defmodule MissingJsonDecoderError do
    defexception message: "JSON decoder not specified."
  end

  defmodule UndefinedRemoteSchemaResolverError do
    defexception message: "trying to resolve a remote schema but no remote schema resolver function is defined"
  end

  defmodule InvalidReferenceError do
    defexception message: "invalid reference"
  end

  alias ExJsonSchema.Schema.Draft4
  alias ExJsonSchema.Schema.Draft6
  alias ExJsonSchema.Schema.Draft7
  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Schema.Ref

  @type resolved :: ExJsonSchema.data()
  @type invalid_reference_error :: {:error, :invalid_reference}

  @current_draft_schema_url "http://json-schema.org/schema"
  @draft4_schema_url "http://json-schema.org/draft-04/schema"
  @draft6_schema_url "http://json-schema.org/draft-06/schema"
  @draft7_schema_url "http://json-schema.org/draft-07/schema"

  @ignored_properties ["const", "default", "enum", "examples"]

  @spec decode_json(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def decode_json(json) do
    decoder = Application.get_env(:ex_json_schema, :decode_json) || fn _json -> raise MissingJsonDecoderError end
    decoder.(json)
  end

  @spec resolve(boolean | Root.t() | ExJsonSchema.object(), custom_format_validator: {module(), atom()}) ::
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

  @spec get_fragment(Root.t(), Ref.t() | ExJsonSchema.json_path()) ::
          {:ok, resolved} | invalid_reference_error | no_return
  def get_fragment(root = %Root{}, ref) when is_binary(ref) do
    get_fragment(root, Ref.from_string(ref, root))
  end

  def get_fragment(%Root{schema: schema, refs: refs}, %Ref{location: location, fragment: fragment} = ref) do
    case Map.get(refs, to_string(ref)) do
      nil ->
        schema = if Ref.local?(ref), do: schema, else: refs[location]
        do_get_fragment(schema, fragment, ref)

      schema ->
        {:ok, schema}
    end
  end

  @spec get_fragment!(Root.t(), Ref.t() | ExJsonSchema.json_path()) :: resolved | no_return
  def get_fragment!(root, ref) do
    case get_fragment(root, ref) do
      {:ok, schema} -> schema
      {:error, :invalid_reference} -> raise_invalid_reference_error(ref)
    end
  end

  @spec get_ref_schema(Root.t(), Ref.t()) :: ExJsonSchema.data() | no_return
  def get_ref_schema(%Root{schema: schema}, %Ref{location: :root, fragment: fragment} = ref) do
    case get_ref_schema_with_schema(schema, fragment, ref) do
      {:error, error} ->
        raise InvalidSchemaError, message: error

      ref_schema ->
        ref_schema
    end
  end

  def get_ref_schema(%Root{refs: refs}, %Ref{location: url, fragment: fragment} = ref) when is_binary(url) do
    case get_ref_schema_with_schema(refs[url], fragment, ref) do
      {:error, error} ->
        raise InvalidSchemaError, message: error

      ref_schema ->
        ref_schema
    end
  end

  @spec resolve_root(boolean | Root.t()) :: Root.t() | no_return
  defp resolve_root(%Root{schema: root_schema} = root, scope \\ "") do
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

    root = %Root{root | version: schema_version}
    {root, schema} = resolve_with_root(root, root_schema, scope)

    %Root{root | schema: schema}
    |> resolve_refs(schema)
  end

  defp resolve_refs(%Root{} = root, schema) when is_map(schema) do
    schema
    |> Enum.reduce(root, fn
      {"$ref", %Ref{} = ref}, root ->
        root =
          case Ref.cached?(ref, root) do
            true -> root
            false -> resolve_and_cache_remote_schema(root, ref)
          end

        get_fragment!(root, ref)
        root

      {_, value}, root when is_map(value) ->
        resolve_refs(root, value)

      {_, values}, root when is_list(values) ->
        values
        |> Enum.reduce(root, fn value, root -> resolve_refs(root, value) end)

      _, root ->
        root
    end)
  end

  defp resolve_refs(%Root{} = root, _), do: root

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
      |> ExJsonSchema.Validator.validate(schema, error_formatter: false)
    else
      _ -> :ok
    end
  end

  defp resolve_with_root(root, %{"$ref" => ref}, scope) when is_binary(ref) do
    do_resolve(root, %{"$ref" => ref}, scope)
  end

  defp resolve_with_root(root, schema = %{"$id" => id}, scope) when is_binary(id) do
    resolve_with_id(root, schema, scope, id)
  end

  defp resolve_with_root(root, schema = %{"id" => id}, scope) when is_binary(id) do
    resolve_with_id(root, schema, scope, id)
  end

  defp resolve_with_root(root, schema = %{}, scope), do: do_resolve(root, schema, scope)
  defp resolve_with_root(root, non_schema, _scope), do: {root, non_schema}

  defp resolve_with_id(root, schema, scope, id) do
    scope =
      case URI.parse(scope) do
        %URI{host: nil} = uri -> to_string(%URI{uri | fragment: nil}) <> id
        uri -> uri |> URI.merge(id) |> to_string()
      end

    {root, schema} = do_resolve(root, schema, scope)
    {root_with_ref(root, scope, schema), schema}
  end

  defp do_resolve(root, schema, scope) do
    {root, schema} =
      Enum.reduce(schema, {root, %{}}, fn property, {root, schema} ->
        {root, {k, v}} = resolve_property(root, property, scope)
        {root, Map.put(schema, k, v)}
      end)

    {root, schema |> sanitize_attributes()}
  end

  defp resolve_property(root, {key, value}, scope) when is_map(value) and key not in @ignored_properties do
    {root, resolved} = resolve_with_root(root, value, scope)
    {root, {key, resolved}}
  end

  defp resolve_property(root, {key, values}, scope) when is_list(values) and key not in @ignored_properties do
    {root, values} =
      Enum.reduce(values, {root, []}, fn value, {root, values} ->
        {root, resolved} = resolve_with_root(root, value, scope)
        {root, [resolved | values]}
      end)

    {root, {key, Enum.reverse(values)}}
  end

  defp resolve_property(root, {"$ref", ref}, scope) when is_binary(ref) do
    ref_uri = URI.parse(ref)

    scoped_ref =
      case URI.parse(scope) do
        %URI{host: nil} -> ref_uri
        scope_uri -> URI.merge(scope_uri, ref_uri)
      end
      |> to_string()

    {root, {"$ref", Ref.from_string(scoped_ref, root)}}
  end

  defp resolve_property(root, tuple, _) when is_tuple(tuple), do: {root, tuple}

  defp resolve_and_cache_remote_schema(root, %Ref{location: url}) do
    remote_schema = remote_schema(url)
    resolve_remote_schema(root, url, remote_schema)
  end

  @spec remote_schema(String.t()) :: ExJsonSchema.object()
  defp remote_schema(@current_draft_schema_url <> _), do: Draft7.schema()
  defp remote_schema(@draft4_schema_url <> _), do: Draft4.schema()
  defp remote_schema(@draft6_schema_url <> _), do: Draft6.schema()
  defp remote_schema(@draft7_schema_url <> _), do: Draft7.schema()
  defp remote_schema(url) when is_bitstring(url), do: fetch_remote_schema(url)

  defp resolve_remote_schema(root, url, remote_schema) do
    root = root_with_ref(root, url, remote_schema)
    %Root{schema: schema, refs: refs} = resolve_root(%Root{root | schema: remote_schema, location: url}, url)

    %Root{root | refs: refs}
    |> root_with_ref(url, schema)
  end

  defp root_with_ref(%Root{refs: refs} = root, url, ref) do
    %{root | refs: Map.put(refs, url, ref)}
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

  defp meta04?(%{"$schema" => @draft4_schema_url <> _}), do: true
  defp meta04?(_), do: false

  defp meta06?(%{"$schema" => @draft6_schema_url <> _}), do: true
  defp meta06?(_), do: false

  defp meta07?(%{"$schema" => @draft7_schema_url <> _}), do: true
  defp meta07?(_), do: false

  defp do_get_fragment(nil, _, _ref), do: {:error, :invalid_reference}
  defp do_get_fragment(schema, [], _), do: {:ok, schema}

  defp do_get_fragment(schema, [key | path], ref) when is_binary(key) do
    do_get_fragment(Map.get(schema, key), path, ref)
  end

  defp do_get_fragment(schema, [idx | path], ref) when is_integer(idx) do
    try do
      do_get_fragment(:lists.nth(idx + 1, schema), path, ref)
    catch
      :error, :function_clause -> {:error, :invalid_reference}
    end
  end

  defp get_ref_schema_with_schema(nil, _, ref) do
    {:error, "reference #{to_string(ref)} could not be resolved"}
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

  @spec raise_invalid_reference_error(any) :: no_return
  def raise_invalid_reference_error(ref) when is_binary(ref),
    do: raise(InvalidReferenceError, message: "invalid reference #{ref}")

  def raise_invalid_reference_error(ref),
    do: ref |> to_string() |> raise_invalid_reference_error
end
