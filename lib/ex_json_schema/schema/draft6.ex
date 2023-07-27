defmodule ExJsonSchema.Schema.Draft6 do
  @schema %{
    "$id" => "http://json-schema.org/draft-06/schema#",
    "$schema" => "http://json-schema.org/draft-06/schema#",
    "default" => %{},
    "definitions" => %{
      "nonNegativeInteger" => %{"minimum" => 0, "type" => "integer"},
      "nonNegativeIntegerDefault0" => %{"allOf" => [%{"$ref" => "#/definitions/nonNegativeInteger"}, %{"default" => 0}]},
      "schemaArray" => %{"items" => %{"$ref" => "#"}, "minItems" => 1, "type" => "array"},
      "simpleTypes" => %{"enum" => ["array", "boolean", "integer", "null", "number", "object", "string"]},
      "stringArray" => %{"default" => [], "items" => %{"type" => "string"}, "type" => "array", "uniqueItems" => true}
    },
    "properties" => %{
      "title" => %{"type" => "string"},
      "dependencies" => %{
        "additionalProperties" => %{"anyOf" => [%{"$ref" => "#"}, %{"$ref" => "#/definitions/stringArray"}]},
        "type" => "object"
      },
      "items" => %{"anyOf" => [%{"$ref" => "#"}, %{"$ref" => "#/definitions/schemaArray"}], "default" => %{}},
      "definitions" => %{"additionalProperties" => %{"$ref" => "#"}, "default" => %{}, "type" => "object"},
      "oneOf" => %{"$ref" => "#/definitions/schemaArray"},
      "anyOf" => %{"$ref" => "#/definitions/schemaArray"},
      "const" => %{},
      "type" => %{
        "anyOf" => [
          %{"$ref" => "#/definitions/simpleTypes"},
          %{
            "items" => %{"$ref" => "#/definitions/simpleTypes"},
            "minItems" => 1,
            "type" => "array",
            "uniqueItems" => true
          }
        ]
      },
      "contains" => %{"$ref" => "#"},
      "patternProperties" => %{
        "additionalProperties" => %{"$ref" => "#"},
        "default" => %{},
        "propertyNames" => %{"format" => "regex"},
        "type" => "object"
      },
      "maxLength" => %{"$ref" => "#/definitions/nonNegativeInteger"},
      "$schema" => %{"format" => "uri", "type" => "string"},
      "$id" => %{"format" => "uri-reference", "type" => "string"},
      "uniqueItems" => %{"default" => false, "type" => "boolean"},
      "exclusiveMaximum" => %{"type" => "number"},
      "additionalItems" => %{"$ref" => "#"},
      "allOf" => %{"$ref" => "#/definitions/schemaArray"},
      "minItems" => %{"$ref" => "#/definitions/nonNegativeIntegerDefault0"},
      "additionalProperties" => %{"$ref" => "#"},
      "required" => %{"$ref" => "#/definitions/stringArray"},
      "not" => %{"$ref" => "#"},
      "default" => %{},
      "multipleOf" => %{"exclusiveMinimum" => 0, "type" => "number"},
      "minimum" => %{"type" => "number"},
      "pattern" => %{"format" => "regex", "type" => "string"},
      "$ref" => %{"format" => "uri-reference", "type" => "string"},
      "exclusiveMinimum" => %{"type" => "number"},
      "maxItems" => %{"$ref" => "#/definitions/nonNegativeInteger"},
      "maxProperties" => %{"$ref" => "#/definitions/nonNegativeInteger"},
      "description" => %{"type" => "string"},
      "propertyNames" => %{"$ref" => "#"},
      "minProperties" => %{"$ref" => "#/definitions/nonNegativeIntegerDefault0"},
      "properties" => %{"additionalProperties" => %{"$ref" => "#"}, "default" => %{}, "type" => "object"},
      "minLength" => %{"$ref" => "#/definitions/nonNegativeIntegerDefault0"},
      "format" => %{"type" => "string"},
      "examples" => %{"items" => %{}, "type" => "array"},
      "maximum" => %{"type" => "number"},
      "enum" => %{"minItems" => 1, "type" => "array", "uniqueItems" => true}
    },
    "title" => "Core schema meta-schema",
    "type" => ["object", "boolean"]
  }
  @spec schema() :: ExJsonSchema.data()
  def schema, do: @schema

  @spec version() :: integer()
  def version, do: 6
end
