defmodule ExJsonSchema.Schema.Draft4 do
  @schema %{
    "$schema" => "http://json-schema.org/draft-04/schema#",
    "default" => %{},
    "definitions" => %{
      "positiveInteger" => %{"minimum" => 0, "type" => "integer"},
      "positiveIntegerDefault0" => %{"allOf" => [%{"$ref" => "#/definitions/positiveInteger"}, %{"default" => 0}]},
      "schemaArray" => %{"items" => %{"$ref" => "#"}, "minItems" => 1, "type" => "array"},
      "simpleTypes" => %{"enum" => ["array", "boolean", "integer", "null", "number", "object", "string"]},
      "stringArray" => %{"items" => %{"type" => "string"}, "minItems" => 1, "type" => "array", "uniqueItems" => true}
    },
    "dependencies" => %{"exclusiveMaximum" => ["maximum"], "exclusiveMinimum" => ["minimum"]},
    "description" => "Core schema meta-schema",
    "id" => "http://json-schema.org/draft-04/schema#",
    "properties" => %{
      "title" => %{"type" => "string"},
      "id" => %{"type" => "string"},
      "dependencies" => %{
        "additionalProperties" => %{"anyOf" => [%{"$ref" => "#"}, %{"$ref" => "#/definitions/stringArray"}]},
        "type" => "object"
      },
      "items" => %{"anyOf" => [%{"$ref" => "#"}, %{"$ref" => "#/definitions/schemaArray"}], "default" => %{}},
      "definitions" => %{"additionalProperties" => %{"$ref" => "#"}, "default" => %{}, "type" => "object"},
      "oneOf" => %{"$ref" => "#/definitions/schemaArray"},
      "anyOf" => %{"$ref" => "#/definitions/schemaArray"},
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
      "patternProperties" => %{"additionalProperties" => %{"$ref" => "#"}, "default" => %{}, "type" => "object"},
      "maxLength" => %{"$ref" => "#/definitions/positiveInteger"},
      "$schema" => %{"type" => "string"},
      "uniqueItems" => %{"default" => false, "type" => "boolean"},
      "exclusiveMaximum" => %{"default" => false, "type" => "boolean"},
      "additionalItems" => %{"anyOf" => [%{"type" => "boolean"}, %{"$ref" => "#"}], "default" => %{}},
      "allOf" => %{"$ref" => "#/definitions/schemaArray"},
      "minItems" => %{"$ref" => "#/definitions/positiveIntegerDefault0"},
      "additionalProperties" => %{"anyOf" => [%{"type" => "boolean"}, %{"$ref" => "#"}], "default" => %{}},
      "required" => %{"$ref" => "#/definitions/stringArray"},
      "not" => %{"$ref" => "#"},
      "default" => %{},
      "multipleOf" => %{"exclusiveMinimum" => true, "minimum" => 0, "type" => "number"},
      "minimum" => %{"type" => "number"},
      "pattern" => %{"format" => "regex", "type" => "string"},
      "exclusiveMinimum" => %{"default" => false, "type" => "boolean"},
      "maxItems" => %{"$ref" => "#/definitions/positiveInteger"},
      "maxProperties" => %{"$ref" => "#/definitions/positiveInteger"},
      "description" => %{"type" => "string"},
      "minProperties" => %{"$ref" => "#/definitions/positiveIntegerDefault0"},
      "properties" => %{"additionalProperties" => %{"$ref" => "#"}, "default" => %{}, "type" => "object"},
      "minLength" => %{"$ref" => "#/definitions/positiveIntegerDefault0"},
      "format" => %{"type" => "string"},
      "maximum" => %{"type" => "number"},
      "enum" => %{"minItems" => 1, "type" => "array", "uniqueItems" => true}
    },
    "type" => "object"
  }
  @spec schema() :: ExJsonSchema.object()
  def schema, do: @schema

  @spec version() :: integer()
  def version, do: 4
end
