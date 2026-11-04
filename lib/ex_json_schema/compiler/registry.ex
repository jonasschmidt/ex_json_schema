defmodule ExJsonSchema.Compiler.Registry do
  @moduledoc false

  # Provides the built-in dialect, vocabulary, and meta-schema definitions
  # used during compilation.

  alias ExJsonSchema.Compiler.Dialect
  alias ExJsonSchema.Compiler.Vocabulary
  alias ExJsonSchema.CompileError
  alias ExJsonSchema.Schema.Draft4
  alias ExJsonSchema.Schema.Draft6
  alias ExJsonSchema.Schema.Draft7
  alias ExJsonSchema.Schema.Draft202012

  @draft4 "http://json-schema.org/draft-04/schema"
  @draft6 "http://json-schema.org/draft-06/schema"
  @draft7 "http://json-schema.org/draft-07/schema"
  @draft202012 "https://json-schema.org/draft/2020-12/schema"

  @core "https://json-schema.org/draft/2020-12/vocab/core"
  @applicator "https://json-schema.org/draft/2020-12/vocab/applicator"
  @unevaluated "https://json-schema.org/draft/2020-12/vocab/unevaluated"
  @validation "https://json-schema.org/draft/2020-12/vocab/validation"
  @metadata "https://json-schema.org/draft/2020-12/vocab/meta-data"
  @format_annotation "https://json-schema.org/draft/2020-12/vocab/format-annotation"
  @format_assertion "https://json-schema.org/draft/2020-12/vocab/format-assertion"
  @content "https://json-schema.org/draft/2020-12/vocab/content"

  @draft4_keywords MapSet.new(~w[
    $ref $schema
    additionalItems additionalProperties allOf anyOf const contains
    default definitions dependencies description enum exclusiveMaximum
    exclusiveMinimum format id items maxItems maxLength maxProperties maximum
    minItems minLength minProperties minimum multipleOf not oneOf pattern
    patternProperties properties required title type uniqueItems
  ])
                   |> MapSet.delete("const")
                   |> MapSet.delete("contains")

  @draft6_keywords MapSet.union(
                     @draft4_keywords,
                     MapSet.new(~w[$id const contains examples propertyNames])
                   )
                   |> MapSet.delete("id")

  @draft7_keywords MapSet.union(
                     @draft6_keywords,
                     MapSet.new(~w[$comment contentEncoding contentMediaType else if readOnly then writeOnly])
                   )

  @vocabularies %{
    @core => MapSet.new(~w[$anchor $comment $defs $dynamicAnchor $dynamicRef $id $ref $schema $vocabulary]),
    @applicator => MapSet.new(~w[
        additionalProperties allOf anyOf contains dependentSchemas else if items
        not oneOf patternProperties prefixItems properties propertyNames then
      ]),
    @unevaluated => MapSet.new(~w[unevaluatedItems unevaluatedProperties]),
    @validation => MapSet.new(~w[
        const dependentRequired enum exclusiveMaximum exclusiveMinimum maxContains
        maxItems maxLength maxProperties maximum minContains minItems minLength
        minProperties minimum multipleOf pattern required type uniqueItems
      ]),
    @metadata => MapSet.new(~w[default deprecated description examples readOnly title writeOnly]),
    @format_annotation => MapSet.new(~w[format]),
    @format_assertion => MapSet.new(~w[format]),
    @content => MapSet.new(~w[contentEncoding contentMediaType contentSchema])
  }

  @draft202012_vocabularies MapSet.new([
                              @core,
                              @applicator,
                              @unevaluated,
                              @validation,
                              @metadata,
                              @format_annotation,
                              @content
                            ])

  @keyword_order ~w[
    $ref $dynamicRef
    type const enum multipleOf maximum exclusiveMaximum minimum exclusiveMinimum
    maxLength minLength pattern maxItems minItems uniqueItems maxProperties
    minProperties required dependentRequired dependencies format contentEncoding
    contentMediaType contentSchema
    prefixItems items additionalItems contains properties patternProperties additionalProperties
    propertyNames dependentSchemas if then else allOf anyOf oneOf not
    unevaluatedItems unevaluatedProperties
    title description default deprecated readOnly writeOnly examples
  ]

  @dialect_aliases %{
    @draft4 => @draft4,
    String.replace(@draft4, "http://", "https://") => @draft4,
    @draft6 => @draft6,
    String.replace(@draft6, "http://", "https://") => @draft6,
    @draft7 => @draft7,
    String.replace(@draft7, "http://", "https://") => @draft7,
    "http://json-schema.org/schema" => @draft7,
    "https://json-schema.org/schema" => @draft7,
    @draft202012 => @draft202012,
    String.replace(@draft202012, "https://", "http://") => @draft202012
  }

  @dialects %{
    @draft4 => %Dialect{
      id: @draft4,
      aliases:
        MapSet.new([
          @draft4,
          String.replace(@draft4, "http://", "https://")
        ]),
      version: 4,
      metaschema: Draft4.schema(),
      vocabularies: MapSet.new(["urn:ex-json-schema:draft-04"]),
      keyword_order: @keyword_order,
      assert_formats?: true
    },
    @draft6 => %Dialect{
      id: @draft6,
      aliases:
        MapSet.new([
          @draft6,
          String.replace(@draft6, "http://", "https://")
        ]),
      version: 6,
      metaschema: Draft6.schema(),
      vocabularies: MapSet.new(["urn:ex-json-schema:draft-06"]),
      keyword_order: @keyword_order,
      assert_formats?: true
    },
    @draft7 => %Dialect{
      id: @draft7,
      aliases:
        MapSet.new([
          @draft7,
          String.replace(@draft7, "http://", "https://"),
          "http://json-schema.org/schema",
          "https://json-schema.org/schema"
        ]),
      version: 7,
      metaschema: Draft7.schema(),
      vocabularies: MapSet.new(["urn:ex-json-schema:draft-07"]),
      keyword_order: @keyword_order,
      assert_formats?: true
    },
    @draft202012 => %Dialect{
      id: @draft202012,
      aliases:
        MapSet.new([
          @draft202012,
          String.replace(@draft202012, "https://", "http://")
        ]),
      version: :"2020-12",
      metaschema: Draft202012.schema(),
      vocabularies: @draft202012_vocabularies,
      keyword_order: @keyword_order
    }
  }

  @legacy_vocabularies %{
    "urn:ex-json-schema:draft-04" => %Vocabulary{
      id: "urn:ex-json-schema:draft-04",
      keywords: @draft4_keywords
    },
    "urn:ex-json-schema:draft-06" => %Vocabulary{
      id: "urn:ex-json-schema:draft-06",
      keywords: @draft6_keywords
    },
    "urn:ex-json-schema:draft-07" => %Vocabulary{
      id: "urn:ex-json-schema:draft-07",
      keywords: @draft7_keywords
    }
  }

  @standard_vocabularies Map.new(@vocabularies, fn {id, keywords} ->
                           {id, %Vocabulary{id: id, keywords: keywords}}
                         end)

  @meta_schema_aliases Map.new(@dialect_aliases, fn {alias_uri, canonical} ->
                         {alias_uri, canonical}
                       end)
                       |> Map.merge(
                         Map.new(Draft202012.all(), fn {uri, _schema} ->
                           {String.replace(uri, "https://", "http://"), uri}
                         end)
                       )
                       |> Map.merge(Map.new(Draft202012.all(), fn {uri, _schema} -> {uri, uri} end))

  def default_dialect, do: Map.fetch!(@dialects, @draft7)

  @spec dialect_for_schema(ExJsonSchema.data()) :: {:ok, Dialect.t()} | {:error, CompileError.t()}
  def dialect_for_schema(schema) when is_boolean(schema), do: {:ok, default_dialect()}

  def dialect_for_schema(schema) when is_map(schema) do
    case Map.fetch(schema, "$schema") do
      :error ->
        {:ok, default_dialect()}

      {:ok, uri} when is_binary(uri) ->
        case dialect(uri) do
          {:ok, dialect} ->
            {:ok, dialect}

          :error ->
            {:error,
             %CompileError{
               reason: :unsupported_dialect,
               uri: uri,
               details: %{dialect: uri},
               message: "unsupported JSON Schema dialect: #{uri}"
             }}
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

  @spec dialect(String.t()) :: {:ok, Dialect.t()} | :error
  def dialect(uri) when is_binary(uri) do
    with {:ok, canonical} <- Map.fetch(@dialect_aliases, normalize_uri(uri)) do
      Map.fetch(@dialects, canonical)
    end
  end

  @spec vocabulary(String.t()) :: {:ok, Vocabulary.t()} | :error
  def vocabulary(uri) when is_binary(uri) do
    Map.fetch(Map.merge(@legacy_vocabularies, @standard_vocabularies), normalize_uri(uri))
  end

  @spec meta_schema(String.t()) :: {:ok, ExJsonSchema.data()} | :error
  def meta_schema(uri) when is_binary(uri) do
    with {:ok, canonical} <- Map.fetch(@meta_schema_aliases, normalize_uri(uri)) do
      case canonical do
        @draft4 -> {:ok, Draft4.schema()}
        @draft6 -> {:ok, Draft6.schema()}
        @draft7 -> {:ok, Draft7.schema()}
        uri -> Map.fetch(Draft202012.all(), uri)
      end
    end
  end

  @spec dialects() :: %{String.t() => Dialect.t()}
  def dialects, do: @dialects

  @spec vocabularies() :: %{String.t() => Vocabulary.t()}
  def vocabularies, do: Map.merge(@legacy_vocabularies, @standard_vocabularies)

  @spec meta_schemas() :: %{String.t() => ExJsonSchema.data()}
  def meta_schemas do
    %{
      @draft4 => Draft4.schema(),
      @draft6 => Draft6.schema(),
      @draft7 => Draft7.schema()
    }
    |> Map.merge(Draft202012.all())
  end

  defp normalize_uri(uri), do: String.trim_trailing(uri, "#")
end
