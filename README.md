# Elixir JSON Schema Validator

[![Build Status](https://travis-ci.org/jonasschmidt/ex_json_schema.svg?branch=master)](https://travis-ci.org/jonasschmidt/ex_json_schema)

A JSON Schema validator with full support for the draft v4 specification. Passes the official [JSON Schema Test Suite](https://github.com/json-schema/JSON-Schema-Test-Suite) (with the exception of the `optional/format` tests for now).

## Usage

### Resolving a schema

In this step the schema is validated against its meta-schema (the draft v4 schema definition) and `$ref`s are being resolved (making sure that the reference points to an existing fragment). You should only resolve a schema once to avoid the overhead of resolving it in every validation call.

```elixir
iex> schema = %{
  "type" => "object",
  "properties" => %{
    "foo" => %{
      "type" => "string"
    }
  }
} |> ExJsonSchema.Schema.resolve
```

Note that map keys are expected to be strings, since in practice that data will always come from some JSON parser.

### Validation

If you're only interested in whether a piece of data is valid according to the schema:

```elixir
iex> ExJsonSchema.Validator.valid?(schema, %{"foo" => "bar"})
true

iex> ExJsonSchema.Validator.valid?(schema, %{"foo" => 1})
false
```

Or in case you want to have detailed validation errors:

```elixir
iex> ExJsonSchema.Validator.validate(schema, %{"foo" => "bar"})
:ok

iex> ExJsonSchema.Validator.validate(schema, %{"foo" => 1})
{:error, [{"Type mismatch. Expected String but got Integer.", "#/foo"}]}
```

Errors are tuples of a message and the path to the element not matching the schema. The path is following the same conventions used in JSON Schema for referencing JSON elements.

## TODO

* Create Hex package
* Update README with installation instructions
* Implement format checks to pass the official `optional/format` tests
* Add some source code documentation
* Add URLs resolved in remote schemata to root's refs
* Enable providing JSON for known schemata at resolve time
