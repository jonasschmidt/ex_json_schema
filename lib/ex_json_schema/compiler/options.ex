defmodule ExJsonSchema.Compiler.Options do
  @moduledoc false

  # Merges and validates application defaults and explicit capabilities and
  # policies accepted by schema compilation.

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.Compiler.URI, as: SchemaURI

  @type callback(function_type) :: function_type | {module(), atom()}
  @type resolver ::
          callback((String.t() -> {:ok, ExJsonSchema.data()} | {:error, term()}))
  @type format_validator :: callback((term() -> :ok | {:error, term()}))
  @type content_decoder ::
          callback((String.t() -> {:ok, ExJsonSchema.data()} | {:error, term()}))

  @type t :: %__MODULE__{
          retrieval_uri: String.t() | nil,
          resources: %{String.t() => ExJsonSchema.data()},
          resolver: resolver() | nil,
          formats: %{String.t() => format_validator()},
          content_decoder: content_decoder() | nil,
          validate_schema: boolean()
        }

  @keys [
    :retrieval_uri,
    :resources,
    :resolver,
    :formats,
    :content_decoder,
    :validate_schema
  ]

  defstruct retrieval_uri: nil,
            resources: %{},
            resolver: nil,
            formats: %{},
            content_decoder: nil,
            validate_schema: true

  @spec parse(keyword()) :: {:ok, t()} | {:error, CompileError.t()}
  def parse(options), do: parse(options, [])

  @doc false
  @spec application_defaults() :: keyword()
  def application_defaults do
    Enum.flat_map(@keys, fn key ->
      case Application.fetch_env(:ex_json_schema, key) do
        {:ok, value} -> [{key, value}]
        :error -> []
      end
    end)
  end

  @spec parse(keyword(), keyword()) :: {:ok, t()} | {:error, CompileError.t()}
  def parse(options, defaults) do
    with :ok <- validate_keyword_list(defaults, :application_defaults),
         :ok <- validate_known_keys(defaults, :application_defaults),
         :ok <- validate_keyword_list(options, :options),
         :ok <- validate_known_keys(options, :options) do
      defaults
      |> Keyword.merge(options)
      |> parse_merged()
    end
  end

  defp parse_merged(options) do
    with %__MODULE__{
           retrieval_uri: retrieval_uri,
           resources: resources,
           resolver: resolver,
           formats: formats,
           content_decoder: content_decoder,
           validate_schema: validate_schema
         } = parsed <- struct!(__MODULE__, options),
         :ok <- validate_retrieval_uri(retrieval_uri),
         :ok <- validate_resources(resources),
         :ok <- validate_callback(:resolver, resolver),
         :ok <- validate_formats(formats),
         :ok <- validate_callback(:content_decoder, content_decoder),
         :ok <- validate_boolean(:validate_schema, validate_schema) do
      {:ok, parsed}
    end
  end

  defp validate_keyword_list(value, source) do
    if Keyword.keyword?(value) do
      :ok
    else
      invalid(source, "expected a keyword list", value)
    end
  end

  defp validate_known_keys(options, source) do
    case Keyword.keys(options) -- @keys do
      [] -> :ok
      keys -> invalid(source, "unknown compile options: #{inspect(keys)}", keys)
    end
  end

  defp validate_retrieval_uri(nil), do: :ok

  defp validate_retrieval_uri(uri) when is_binary(uri) do
    with {:ok, resolved} <- SchemaURI.resolve("", uri),
         {:ok, _resource, fragment} <- SchemaURI.split_fragment(resolved) do
      if is_nil(fragment),
        do: :ok,
        else: invalid(:retrieval_uri, "must not contain a fragment", uri)
    else
      :error -> invalid(:retrieval_uri, "must be a valid URI reference", uri)
    end
  end

  defp validate_retrieval_uri(value),
    do: invalid(:retrieval_uri, "expected a string or nil", value)

  defp validate_resources(resources) when is_map(resources) do
    case Enum.find(resources, fn
           {uri, schema} when is_binary(uri) and (is_map(schema) or is_boolean(schema)) -> false
           _entry -> true
         end) do
      nil -> :ok
      entry -> invalid(:resources, "expected URI keys and decoded schema values", entry)
    end
  end

  defp validate_resources(value), do: invalid(:resources, "expected a map", value)

  defp validate_formats(formats) when is_map(formats) do
    case Enum.find(formats, fn
           {name, validator} -> not is_binary(name) or not valid_callback?(validator)
           _entry -> true
         end) do
      nil ->
        :ok

      entry ->
        invalid(
          :formats,
          "expected string keys and one-argument functions or {module, function} tuples",
          entry
        )
    end
  end

  defp validate_formats(value), do: invalid(:formats, "expected a map", value)

  defp validate_callback(_name, nil), do: :ok

  defp validate_callback(name, callback) do
    if valid_callback?(callback) do
      :ok
    else
      invalid(
        name,
        "expected a one-argument function, {module, function} tuple, or nil",
        callback
      )
    end
  end

  defp valid_callback?(callback) when is_function(callback, 1), do: true

  defp valid_callback?({module, function})
       when is_atom(module) and is_atom(function),
       do: true

  defp valid_callback?(_callback), do: false

  defp validate_boolean(_name, value) when is_boolean(value), do: :ok
  defp validate_boolean(name, value), do: invalid(name, "expected a boolean", value)

  defp invalid(option, message, value) do
    {:error,
     %CompileError{
       reason: :invalid_option,
       message: "invalid #{option} option: #{message}",
       details: %{option: option, value: value}
     }}
  end
end
