defmodule ExJsonSchema.Compiler.DialectResolver do
  @moduledoc false

  # Selects a built-in dialect or derives a custom dialect from a loaded
  # meta-schema and its vocabulary declarations.

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.Compiler.Callbacks
  alias ExJsonSchema.Compiler.Dialect
  alias ExJsonSchema.Compiler.Options
  alias ExJsonSchema.Compiler.Registry
  alias ExJsonSchema.Compiler.URI, as: SchemaURI

  @format_assertion "https://json-schema.org/draft/2020-12/vocab/format-assertion"

  @spec resolve(ExJsonSchema.data(), Options.t()) ::
          {:ok, Dialect.t(), Options.t(), %{String.t() => Dialect.t()}}
          | {:error, CompileError.t()}
  def resolve(schema, %Options{} = options) when is_boolean(schema) do
    {:ok, Registry.default_dialect(), options, %{}}
  end

  def resolve(schema, %Options{} = options) when is_map(schema) do
    case Map.fetch(schema, "$schema") do
      :error ->
        {:ok, Registry.default_dialect(), options, %{}}

      {:ok, uri} when is_binary(uri) ->
        case Registry.dialect(uri) do
          {:ok, dialect} ->
            {:ok, dialect, options, %{}}

          :error ->
            resolve_custom(uri, options)
        end

      {:ok, value} ->
        {:error,
         %CompileError{
           reason: :invalid_schema,
           details: %{"$schema" => value},
           message: "$schema must be a string"
         }}
    end
  end

  defp resolve_custom(uri, options) do
    normalized = SchemaURI.without_fragment(uri)

    with {:ok, metaschema, options} <- load_metaschema(normalized, options),
         {:ok, %Dialect{} = base} <- base_dialect(metaschema, normalized),
         {:ok, vocabularies} <- vocabularies(metaschema, base, normalized) do
      canonical = Map.get(metaschema, "$id", normalized) |> SchemaURI.without_fragment()

      dialect = %Dialect{
        base
        | id: canonical,
          aliases: MapSet.new([normalized, canonical]),
          metaschema: metaschema,
          vocabularies: vocabularies,
          assert_formats?: MapSet.member?(vocabularies, @format_assertion)
      }

      {:ok, dialect, options, %{normalized => dialect, canonical => dialect}}
    end
  end

  defp load_metaschema(
         uri,
         %Options{resources: configured_resources, resolver: resolver} = options
       ) do
    resources =
      Map.new(configured_resources, fn {resource_uri, schema} ->
        {SchemaURI.without_fragment(resource_uri), schema}
      end)

    case Map.fetch(resources, uri) do
      {:ok, metaschema} ->
        {:ok, metaschema, options}

      :error when is_nil(resolver) ->
        unsupported_dialect(uri)

      :error ->
        case Callbacks.resolve(resolver, uri) do
          {:ok, metaschema} ->
            updated_resources = Map.put(configured_resources, uri, metaschema)
            {:ok, metaschema, %Options{options | resources: updated_resources}}

          {:error, error} ->
            {:error, error}
        end
    end
  end

  defp base_dialect(%{"$schema" => base_uri}, _custom_uri) when is_binary(base_uri) do
    case Registry.dialect(base_uri) do
      {:ok, dialect} -> {:ok, dialect}
      :error -> unsupported_dialect(base_uri)
    end
  end

  defp base_dialect(_metaschema, custom_uri), do: unsupported_dialect(custom_uri)

  defp vocabularies(%{"$vocabulary" => declarations}, _base, custom_uri)
       when is_map(declarations) do
    Enum.reduce_while(declarations, {:ok, MapSet.new()}, fn {uri, required?}, {:ok, active} ->
      case Registry.vocabulary(uri) do
        {:ok, _vocabulary} ->
          {:cont, {:ok, MapSet.put(active, uri)}}

        :error when required? == false ->
          {:cont, {:ok, active}}

        :error ->
          {:halt,
           {:error,
            %CompileError{
              reason: :unsupported_vocabulary,
              uri: custom_uri,
              details: %{vocabulary: uri, required: required?},
              message: "unsupported required JSON Schema vocabulary: #{uri}"
            }}}
      end
    end)
  end

  defp vocabularies(_metaschema, %Dialect{vocabularies: vocabularies}, _custom_uri),
    do: {:ok, vocabularies}

  defp unsupported_dialect(uri) do
    {:error,
     %CompileError{
       reason: :unsupported_dialect,
       uri: uri,
       details: %{dialect: uri},
       message: "unsupported JSON Schema dialect: #{uri}"
     }}
  end
end
