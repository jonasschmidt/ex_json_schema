defmodule ExJsonSchema.Schema do
  alias ExJsonSchema.Validator

  defmodule UnsupportedSchemaVersionError do
    defexception message: "Unsupported schema version, only draft 4, 6, and 7 are supported."
  end

  defmodule InvalidSchemaError do
    defexception message: "invalid schema"
  end

  defmodule UndefinedRemoteSchemaResolverError do
    defexception message:
                   "trying to resolve a remote schema but no remote schema resolver function is defined"
  end

  alias ExJsonSchema.Schema.Draft4
  alias ExJsonSchema.Schema.Draft6
  alias ExJsonSchema.Schema.Draft7
  alias ExJsonSchema.Schema.Root

  @type resolved :: %{String.t() => ExJsonSchema.data() | (Root.t() -> {Root.t(), resolved})}

  @current_draft_schema_url "http://json-schema.org/schema"
  @draft4_schema_url "http://json-schema.org/draft-04/schema"
  @draft6_schema_url "http://json-schema.org/draft-06/schema"
  @draft7_schema_url "http://json-schema.org/draft-07/schema"

  @false_value_schema %{
    "not" => %{
      "anyOf" => [
        %{"type" => "object"},
        %{"type" => "array"},
        %{"type" => "boolean"},
        %{"type" => "string"},
        %{"type" => "number"},
        %{"type" => "null"}
      ]
    }
  }

  @true_value_schema %{
    "anyOf" => [
      %{"type" => "object"},
      %{"type" => "array"},
      %{"type" => "boolean"},
      %{"type" => "string"},
      %{"type" => "number"},
      %{"type" => "null"}
    ]
  }

  @spec resolve(boolean | Root.t() | ExJsonSchema.data()) :: Root.t() | no_return
  def resolve(false) do
    %Root{schema: @false_value_schema}
  end

  def resolve(true) do
    %Root{schema: @true_value_schema}
  end

  def resolve(root = %Root{}), do: resolve_root(root)

  def resolve(schema = %{}), do: resolve_root(%Root{schema: schema})

  @spec get_ref_schema(Root.t(), [:root | String.t()]) :: ExJsonSchema.data()
  def get_ref_schema(root = %Root{}, [:root | path] = ref) do
    get_ref_schema_with_schema(root.schema, path, ref)
  end

  def get_ref_schema(root = %Root{}, [url | path] = ref) when is_binary(url) do
    get_ref_schema_with_schema(root.refs[url], path, ref)
  end

  @spec resolve_root(boolean | Root.t()) :: Root.t() | no_return
  defp resolve_root(root) do
    schema_version =
      root.schema
      |> Map.get("$schema", @current_draft_schema_url <> "#")
      |> schema_version()

    schema_version =
      case schema_version do
        {:ok, version} ->
          version

        :error ->
          raise UnsupportedSchemaVersionError
      end

    case assert_valid_schema(root.schema) do
      :ok ->
        :ok

      {:error, errors} ->
        raise InvalidSchemaError,
          message: "schema did not pass validation against its meta-schema: #{inspect(errors)}"
    end

    {root, schema} = resolve_with_root(root, root.schema)

    root
    |> Map.put(:version, schema_version)
    |> Map.put(:schema, schema)
  end

  @spec schema_version(String.t()) :: {:ok, non_neg_integer} | :error
  defp schema_version(@draft4_schema_url <> _), do: {:ok, 4}
  defp schema_version(@draft6_schema_url <> _), do: {:ok, 6}
  defp schema_version(@draft7_schema_url <> _), do: {:ok, 7}
  defp schema_version(@current_draft_schema_url <> _), do: {:ok, 7}
  defp schema_version(_), do: :error

  @spec assert_valid_schema(map) :: :ok | {:error, Validator.errors_with_list_paths()}
  defp assert_valid_schema(schema) do
    with false <- meta04?(schema),
         false <- meta06?(schema),
         false <- meta07?(schema) do
      schema_module =
        schema
        |> Map.get("$schema", @current_draft_schema_url <> "#")
        |> choose_meta_schema_validation_module()

      schema_module.schema()
      |> resolve()
      |> ExJsonSchema.Validator.validate(schema)
    else
      _ ->
        :ok
    end
  end

  @spec choose_meta_schema_validation_module(String.t()) :: module
  defp choose_meta_schema_validation_module(@draft4_schema_url <> _), do: Draft4
  defp choose_meta_schema_validation_module(@draft6_schema_url <> _), do: Draft6
  defp choose_meta_schema_validation_module(@draft7_schema_url <> _), do: Draft7
  defp choose_meta_schema_validation_module(_), do: Draft4

  defp resolve_with_root(root, schema, scope \\ "")

  defp resolve_with_root(root, schema = %{"$id" => id}, scope) when is_bitstring(id),
    do: do_resolve(root, schema, scope <> id)

  defp resolve_with_root(root, schema = %{"id" => id}, scope) when is_bitstring(id),
    do: do_resolve(root, schema, scope <> id)

  defp resolve_with_root(root, schema = %{}, scope), do: do_resolve(root, schema, scope)
  defp resolve_with_root(root, non_schema, _scope), do: {root, non_schema}

  defp do_resolve(root, schema, scope) do
    {root, schema} =
      if Map.has_key?(schema, "$ref") do
        schema
        |> Map.take(["$ref"])
        |> Enum.reduce({root, %{}}, fn property, {root, schema} ->
          {root, {k, v}} = resolve_property(root, property, scope)
          {root, Map.put(schema, k, v)}
        end)
      else
        Enum.reduce(schema, {root, %{}}, fn property, {root, schema} ->
          {root, {k, v}} = resolve_property(root, property, scope)
          {root, Map.put(schema, k, v)}
        end)
      end

    sanitized_schema =
      schema
      |> sanitize_properties_attribute()
      |> sanitize_additional_items_attribute()

    {root, sanitized_schema}
  end

  defp resolve_property(root, {"not", true}, _scope) do
    {root, {"not", @true_value_schema}}
  end

  defp resolve_property(root, {"not", false}, _scope) do
    {root, {"not", @false_value_schema}}
  end

  defp resolve_property(root, {"$ref", ref}, scope) when is_bitstring(ref) do
    scoped_ref = scoped_ref(scope, ref)

    {root, path} = resolve_ref(root, scoped_ref)
    {root, {"$ref", path}}
  end

  defp resolve_property(root, {key, value}, scope) when is_map(value) do
    {root, resolved} = resolve_with_root(root, value, scope)
    {root, {key, resolved}}
  end

  defp resolve_property(root, {key, values}, scope) when is_list(values) do
    {root, values} =
      Enum.reduce(values, {root, []}, &resolve_value(&1, &2, scope))

    {root, {key, Enum.reverse(values)}}
  end

  defp resolve_property(root, tuple, _) when is_tuple(tuple), do: {root, tuple}

  @spec scoped_ref(scope :: String.t(), ref :: String.t()) :: String.t()
  defp scoped_ref(_, ref = "http://" <> _), do: ref
  defp scoped_ref(_, ref = "https://" <> _), do: ref

  defp scoped_ref(scope, ref) do
    String.replace(scope <> ref, "##", "#")
  end

  defp resolve_value(true, {root, values}, _) do
    {root, [@true_value_schema | values]}
  end

  defp resolve_value(false, {root, values}, _) do
    {root, [@false_value_schema | values]}
  end

  defp resolve_value(value, {root, values}, scope) do
    {root, resolved} = resolve_with_root(root, value, scope)
    {root, [resolved | values]}
  end

  defp resolve_ref(root, "#") do
    {root, [root.location]}
  end

  defp resolve_ref(root, ref) do
    [url | fragments] = String.split(ref, "#")
    fragment = fragment!(fragments, ref)
    {root, path} = root_and_path_for_url(root, fragment, url)
    assert_reference_valid(path, root, ref)
    {root, path}
  end

  @spec fragment!([String.t], String.t()) :: String.t() | nil | no_return
  defp fragment!([], _), do: nil
  defp fragment!([""], _), do: nil
  defp fragment!([fragment = "/" <> _], _), do: fragment
  defp fragment!(_, ref), do: raise(InvalidSchemaError, message: "invalid reference #{ref}")

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
      case Integer.parse(key) do
        {integer, ""} ->
          integer

        :error ->
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

  @spec remote_schema(String.t()) :: ExJsonSchema.object()
  defp remote_schema(@current_draft_schema_url <> _), do: Draft4.schema()
  defp remote_schema(@draft4_schema_url <> _), do: Draft4.schema()
  defp remote_schema(@draft6_schema_url <> _), do: Draft6.schema()
  defp remote_schema(@draft7_schema_url <> _), do: Draft7.schema()
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
    Application.get_env(:ex_json_schema, :remote_schema_resolver) ||
      fn _url -> raise UndefinedRemoteSchemaResolverError end
  end

  defp assert_reference_valid(path, root, _ref) do
    get_ref_schema(root, path)
  end

  defp sanitize_properties_attribute(schema) do
    if needs_properties_attribute?(schema) do
      Map.put(schema, "properties", %{})
    else
      schema
    end
  end

  defp needs_properties_attribute?(%{"properties" => _}), do: false
  defp needs_properties_attribute?(%{"patternProperties" => _}), do: true
  defp needs_properties_attribute?(%{"additionalProperties" => _}), do: true
  defp needs_properties_attribute?(_), do: false

  defp sanitize_additional_items_attribute(schema) do
    if needs_additional_items_attribute?(schema) do
      Map.put(schema, "additionalItems", true)
    else
      schema
    end
  end

  defp needs_additional_items_attribute?(%{"additionalItems" => _}), do: false
  defp needs_additional_items_attribute?(%{"items" => items}) when is_list(items), do: true
  defp needs_additional_items_attribute?(_), do: false

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

  defp get_ref_schema_with_schema(nil, _, ref) do
    raise InvalidSchemaError, message: "reference #{ref_to_string(ref)} could not be resolved"
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
    try do
      get_ref_schema_with_schema(:lists.nth(idx + 1, schema), path, ref)
    catch
      :error, :function_clause ->
        raise InvalidSchemaError, message: "reference #{ref_to_string(ref)} could not be resolved"
    end
  end

  @spec ref_to_string([String.t() | :root]) :: String.t()
  defp ref_to_string([:root | path]), do: Enum.join(["#" | path], "/")
  defp ref_to_string([url | path]), do: Enum.join([url <> "#" | path], "/")
end
