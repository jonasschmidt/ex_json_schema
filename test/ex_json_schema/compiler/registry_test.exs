defmodule ExJsonSchema.Compiler.RegistryTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.Compiler.Dialect
  alias ExJsonSchema.Compiler.Registry
  alias ExJsonSchema.Compiler.Vocabulary

  test "registers every supported dialect under its canonical URI" do
    assert Registry.dialects() |> Map.keys() |> Enum.sort() ==
             [
               "http://json-schema.org/draft-04/schema",
               "http://json-schema.org/draft-06/schema",
               "http://json-schema.org/draft-07/schema",
               "https://json-schema.org/draft/2020-12/schema"
             ]

    assert {:ok, %Dialect{version: :"2020-12"}} =
             Registry.dialect("https://json-schema.org/draft/2020-12/schema#")
  end

  test "normalizes legacy scheme and empty-fragment aliases" do
    for draft <- ["draft-04", "draft-06", "draft-07"] do
      assert Registry.dialect("https://json-schema.org/#{draft}/schema#") ==
               Registry.dialect("http://json-schema.org/#{draft}/schema")
    end

    assert Registry.dialect("https://json-schema.org/schema#") ==
             Registry.dialect("http://json-schema.org/draft-07/schema")

    assert Registry.meta_schema("https://json-schema.org/draft-04/schema#") ==
             Registry.meta_schema("http://json-schema.org/draft-04/schema")
  end

  test "uses draft 7 when $schema is absent" do
    assert {:ok, %Dialect{version: 7}} =
             Registry.dialect_for_schema(%{"type" => "string"})

    assert {:ok, %Dialect{version: 7}} = Registry.dialect_for_schema(true)
  end

  test "returns a structured error for unsupported dialects" do
    assert {:error,
            %CompileError{
              reason: :unsupported_dialect,
              uri: "https://example.com/dialect"
            }} =
             Registry.dialect_for_schema(%{"$schema" => "https://example.com/dialect"})
  end

  test "registers the 2020-12 vocabularies and their meta-schemas" do
    vocabulary_ids = [
      "applicator",
      "content",
      "core",
      "format-annotation",
      "format-assertion",
      "meta-data",
      "unevaluated",
      "validation"
    ]

    for name <- vocabulary_ids do
      vocabulary_uri = "https://json-schema.org/draft/2020-12/vocab/#{name}"
      meta_schema_uri = "https://json-schema.org/draft/2020-12/meta/#{name}"

      assert {:ok, %Vocabulary{id: ^vocabulary_uri}} = Registry.vocabulary(vocabulary_uri)
      assert {:ok, %{"$id" => ^meta_schema_uri}} = Registry.meta_schema(meta_schema_uri <> "#")
    end
  end

  test "keeps format annotation and format assertion distinct" do
    assert {:ok, annotation} =
             Registry.vocabulary("https://json-schema.org/draft/2020-12/vocab/format-annotation")

    assert {:ok, assertion} =
             Registry.vocabulary("https://json-schema.org/draft/2020-12/vocab/format-assertion")

    assert %Vocabulary{id: annotation_id, keywords: keywords} = annotation
    assert %Vocabulary{id: assertion_id, keywords: ^keywords} = assertion
    assert annotation_id != assertion_id
  end

  test "returns error for unregistered identifiers" do
    assert :error = Registry.dialect("https://example.com/dialect")
    assert :error = Registry.vocabulary("https://example.com/vocabulary")
    assert :error = Registry.meta_schema("https://example.com/meta-schema")
  end
end
