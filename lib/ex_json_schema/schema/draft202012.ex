defmodule ExJsonSchema.Schema.Draft202012 do
  @moduledoc false

  # Embeds the Draft 2020-12 general and vocabulary meta-schemas for local
  # dialect validation.

  @schemas %{
    "https://json-schema.org/draft/2020-12/meta/applicator" => %{
      "$defs" => %{
        "schemaArray" => %{
          "items" => %{"$dynamicRef" => "#meta"},
          "minItems" => 1,
          "type" => "array"
        }
      },
      "$dynamicAnchor" => "meta",
      "$id" => "https://json-schema.org/draft/2020-12/meta/applicator",
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "properties" => %{
        "additionalProperties" => %{"$dynamicRef" => "#meta"},
        "allOf" => %{"$ref" => "#/$defs/schemaArray"},
        "anyOf" => %{"$ref" => "#/$defs/schemaArray"},
        "contains" => %{"$dynamicRef" => "#meta"},
        "dependentSchemas" => %{
          "additionalProperties" => %{"$dynamicRef" => "#meta"},
          "default" => %{},
          "type" => "object"
        },
        "else" => %{"$dynamicRef" => "#meta"},
        "if" => %{"$dynamicRef" => "#meta"},
        "items" => %{"$dynamicRef" => "#meta"},
        "not" => %{"$dynamicRef" => "#meta"},
        "oneOf" => %{"$ref" => "#/$defs/schemaArray"},
        "patternProperties" => %{
          "additionalProperties" => %{"$dynamicRef" => "#meta"},
          "default" => %{},
          "propertyNames" => %{"format" => "regex"},
          "type" => "object"
        },
        "prefixItems" => %{"$ref" => "#/$defs/schemaArray"},
        "properties" => %{
          "additionalProperties" => %{"$dynamicRef" => "#meta"},
          "default" => %{},
          "type" => "object"
        },
        "propertyNames" => %{"$dynamicRef" => "#meta"},
        "then" => %{"$dynamicRef" => "#meta"}
      },
      "title" => "Applicator vocabulary meta-schema",
      "type" => ["object", "boolean"]
    },
    "https://json-schema.org/draft/2020-12/meta/content" => %{
      "$dynamicAnchor" => "meta",
      "$id" => "https://json-schema.org/draft/2020-12/meta/content",
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "properties" => %{
        "contentEncoding" => %{"type" => "string"},
        "contentMediaType" => %{"type" => "string"},
        "contentSchema" => %{"$dynamicRef" => "#meta"}
      },
      "title" => "Content vocabulary meta-schema",
      "type" => ["object", "boolean"]
    },
    "https://json-schema.org/draft/2020-12/meta/core" => %{
      "$defs" => %{
        "anchorString" => %{
          "pattern" => "^[A-Za-z_][-A-Za-z0-9._]*$",
          "type" => "string"
        },
        "uriReferenceString" => %{"format" => "uri-reference", "type" => "string"},
        "uriString" => %{"format" => "uri", "type" => "string"}
      },
      "$dynamicAnchor" => "meta",
      "$id" => "https://json-schema.org/draft/2020-12/meta/core",
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "properties" => %{
        "$anchor" => %{"$ref" => "#/$defs/anchorString"},
        "$comment" => %{"type" => "string"},
        "$defs" => %{
          "additionalProperties" => %{"$dynamicRef" => "#meta"},
          "type" => "object"
        },
        "$dynamicAnchor" => %{"$ref" => "#/$defs/anchorString"},
        "$dynamicRef" => %{"$ref" => "#/$defs/uriReferenceString"},
        "$id" => %{
          "$comment" => "Non-empty fragments not allowed.",
          "$ref" => "#/$defs/uriReferenceString",
          "pattern" => "^[^#]*#?$"
        },
        "$ref" => %{"$ref" => "#/$defs/uriReferenceString"},
        "$schema" => %{"$ref" => "#/$defs/uriString"},
        "$vocabulary" => %{
          "additionalProperties" => %{"type" => "boolean"},
          "propertyNames" => %{"$ref" => "#/$defs/uriString"},
          "type" => "object"
        }
      },
      "title" => "Core vocabulary meta-schema",
      "type" => ["object", "boolean"]
    },
    "https://json-schema.org/draft/2020-12/meta/format-annotation" => %{
      "$dynamicAnchor" => "meta",
      "$id" => "https://json-schema.org/draft/2020-12/meta/format-annotation",
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "properties" => %{"format" => %{"type" => "string"}},
      "title" => "Format vocabulary meta-schema for annotation results",
      "type" => ["object", "boolean"]
    },
    "https://json-schema.org/draft/2020-12/meta/format-assertion" => %{
      "$dynamicAnchor" => "meta",
      "$id" => "https://json-schema.org/draft/2020-12/meta/format-assertion",
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "properties" => %{"format" => %{"type" => "string"}},
      "title" => "Format vocabulary meta-schema for assertion results",
      "type" => ["object", "boolean"]
    },
    "https://json-schema.org/draft/2020-12/meta/meta-data" => %{
      "$dynamicAnchor" => "meta",
      "$id" => "https://json-schema.org/draft/2020-12/meta/meta-data",
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "properties" => %{
        "default" => true,
        "deprecated" => %{"default" => false, "type" => "boolean"},
        "description" => %{"type" => "string"},
        "examples" => %{"items" => true, "type" => "array"},
        "readOnly" => %{"default" => false, "type" => "boolean"},
        "title" => %{"type" => "string"},
        "writeOnly" => %{"default" => false, "type" => "boolean"}
      },
      "title" => "Meta-data vocabulary meta-schema",
      "type" => ["object", "boolean"]
    },
    "https://json-schema.org/draft/2020-12/meta/unevaluated" => %{
      "$dynamicAnchor" => "meta",
      "$id" => "https://json-schema.org/draft/2020-12/meta/unevaluated",
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "properties" => %{
        "unevaluatedItems" => %{"$dynamicRef" => "#meta"},
        "unevaluatedProperties" => %{"$dynamicRef" => "#meta"}
      },
      "title" => "Unevaluated applicator vocabulary meta-schema",
      "type" => ["object", "boolean"]
    },
    "https://json-schema.org/draft/2020-12/meta/validation" => %{
      "$defs" => %{
        "nonNegativeInteger" => %{"minimum" => 0, "type" => "integer"},
        "nonNegativeIntegerDefault0" => %{
          "$ref" => "#/$defs/nonNegativeInteger",
          "default" => 0
        },
        "simpleTypes" => %{
          "enum" => ["array", "boolean", "integer", "null", "number", "object", "string"]
        },
        "stringArray" => %{
          "default" => [],
          "items" => %{"type" => "string"},
          "type" => "array",
          "uniqueItems" => true
        }
      },
      "$dynamicAnchor" => "meta",
      "$id" => "https://json-schema.org/draft/2020-12/meta/validation",
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "properties" => %{
        "const" => true,
        "dependentRequired" => %{
          "additionalProperties" => %{"$ref" => "#/$defs/stringArray"},
          "type" => "object"
        },
        "enum" => %{"items" => true, "type" => "array"},
        "exclusiveMaximum" => %{"type" => "number"},
        "exclusiveMinimum" => %{"type" => "number"},
        "maxContains" => %{"$ref" => "#/$defs/nonNegativeInteger"},
        "maxItems" => %{"$ref" => "#/$defs/nonNegativeInteger"},
        "maxLength" => %{"$ref" => "#/$defs/nonNegativeInteger"},
        "maxProperties" => %{"$ref" => "#/$defs/nonNegativeInteger"},
        "maximum" => %{"type" => "number"},
        "minContains" => %{"$ref" => "#/$defs/nonNegativeInteger", "default" => 1},
        "minItems" => %{"$ref" => "#/$defs/nonNegativeIntegerDefault0"},
        "minLength" => %{"$ref" => "#/$defs/nonNegativeIntegerDefault0"},
        "minProperties" => %{"$ref" => "#/$defs/nonNegativeIntegerDefault0"},
        "minimum" => %{"type" => "number"},
        "multipleOf" => %{"exclusiveMinimum" => 0, "type" => "number"},
        "pattern" => %{"format" => "regex", "type" => "string"},
        "required" => %{"$ref" => "#/$defs/stringArray"},
        "type" => %{
          "anyOf" => [
            %{"$ref" => "#/$defs/simpleTypes"},
            %{
              "items" => %{"$ref" => "#/$defs/simpleTypes"},
              "minItems" => 1,
              "type" => "array",
              "uniqueItems" => true
            }
          ]
        },
        "uniqueItems" => %{"default" => false, "type" => "boolean"}
      },
      "title" => "Validation vocabulary meta-schema",
      "type" => ["object", "boolean"]
    },
    "https://json-schema.org/draft/2020-12/schema" => %{
      "$comment" =>
        "This meta-schema also defines keywords that have appeared in previous drafts in order to prevent incompatible extensions as they remain in common use.",
      "$dynamicAnchor" => "meta",
      "$id" => "https://json-schema.org/draft/2020-12/schema",
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$vocabulary" => %{
        "https://json-schema.org/draft/2020-12/vocab/applicator" => true,
        "https://json-schema.org/draft/2020-12/vocab/content" => true,
        "https://json-schema.org/draft/2020-12/vocab/core" => true,
        "https://json-schema.org/draft/2020-12/vocab/format-annotation" => true,
        "https://json-schema.org/draft/2020-12/vocab/meta-data" => true,
        "https://json-schema.org/draft/2020-12/vocab/unevaluated" => true,
        "https://json-schema.org/draft/2020-12/vocab/validation" => true
      },
      "allOf" => [
        %{"$ref" => "meta/core"},
        %{"$ref" => "meta/applicator"},
        %{"$ref" => "meta/unevaluated"},
        %{"$ref" => "meta/validation"},
        %{"$ref" => "meta/meta-data"},
        %{"$ref" => "meta/format-annotation"},
        %{"$ref" => "meta/content"}
      ],
      "properties" => %{
        "$recursiveAnchor" => %{
          "$comment" => "\"$recursiveAnchor\" has been replaced by \"$dynamicAnchor\".",
          "$ref" => "meta/core#/$defs/anchorString",
          "deprecated" => true
        },
        "$recursiveRef" => %{
          "$comment" => "\"$recursiveRef\" has been replaced by \"$dynamicRef\".",
          "$ref" => "meta/core#/$defs/uriReferenceString",
          "deprecated" => true
        },
        "definitions" => %{
          "$comment" => "\"definitions\" has been replaced by \"$defs\".",
          "additionalProperties" => %{"$dynamicRef" => "#meta"},
          "default" => %{},
          "deprecated" => true,
          "type" => "object"
        },
        "dependencies" => %{
          "$comment" =>
            "\"dependencies\" has been split and replaced by \"dependentSchemas\" and \"dependentRequired\" in order to serve their differing semantics.",
          "additionalProperties" => %{
            "anyOf" => [
              %{"$dynamicRef" => "#meta"},
              %{"$ref" => "meta/validation#/$defs/stringArray"}
            ]
          },
          "default" => %{},
          "deprecated" => true,
          "type" => "object"
        }
      },
      "title" => "Core and Validation specifications meta-schema",
      "type" => ["object", "boolean"]
    }
  }

  @spec schema(String.t()) :: ExJsonSchema.data()
  def schema(uri \\ "https://json-schema.org/draft/2020-12/schema"), do: Map.fetch!(@schemas, uri)

  @spec all() :: %{String.t() => ExJsonSchema.data()}
  def all, do: @schemas

  @spec version() :: :"2020-12"
  def version, do: :"2020-12"
end
