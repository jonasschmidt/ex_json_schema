# Elixir JSON Schema Validator

[![Build Status](https://github.com/jonasschmidt/ex_json_schema/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/jonasschmidt/ex_json_schema/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/jonasschmidt/ex_json_schema/badge.svg?branch=master)](https://coveralls.io/github/jonasschmidt/ex_json_schema?branch=master)
[![Module Version](https://img.shields.io/hexpm/v/ex_json_schema.svg)](https://hex.pm/packages/ex_json_schema)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ex_json_schema/)
[![Total Download](https://img.shields.io/hexpm/dt/ex_json_schema.svg)](https://hex.pm/packages/ex_json_schema)
[![License](https://img.shields.io/hexpm/l/ex_json_schema.svg)](https://github.com/jonasschmidt/ex_json_schema/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/jonasschmidt/ex_json_schema.svg)](https://github.com/jonasschmidt/ex_json_schema/commits/master)

A JSON Schema compiler and validator for Elixir with support for drafts 4, 6,
7, and 2020-12. It provides the JSON Schema behavior needed by OpenAPI 3.1
schemas and passes the corresponding required official
[JSON Schema Test Suite](https://github.com/json-schema-org/JSON-Schema-Test-Suite)
cases. OpenAPI-specific dialect identifiers and extension keywords are outside
the built-in dialect set.

## Installation

```elixir
defp deps do
  [{:ex_json_schema, "~> 1.0"}]
end
```

Elixir 1.15 and OTP 25 are the minimum supported versions.

## Compile and validate

```elixir
schema = %{
  "$schema" => "https://json-schema.org/draft/2020-12/schema",
  "type" => "object",
  "properties" => %{"name" => %{"type" => "string"}},
  "required" => ["name"]
}

compiled = ExJsonSchema.compile!(schema)

ExJsonSchema.valid?(%{"name" => "Ada"}, compiled)
# => true

ExJsonSchema.validate(%{"name" => 42}, compiled)
# => %{"valid" => false, "errors" => [...]}
```

Schemas must already be decoded JSON objects or booleans, with string map
keys. Compile once and reuse the opaque compiled value. Compilation validates
the schema, eagerly resolves its reachable resource graph, and reports
`ExJsonSchema.CompileError`; validation does no resource-loading I/O.

`validate/3` returns standardized JSON Schema output. Basic output is the
default; `output: :flag`, `:detailed`, and `:verbose` are also available.
`valid?/3` is the boolean fast path.

## Resources and references

Provide known resources directly and use an explicit resolver for the rest:

```elixir
compiled =
  ExJsonSchema.compile!(schema,
    retrieval_uri: "https://example.test/root",
    resources: %{
      "https://example.test/address" => address_schema
    },
    resolver: {MySchemaStore, :fetch}
  )
```

The resolver is called only during compilation. Built-in metaschemas require
no network access. To validate from a fragment, anchor, or resource entry
point, look up another scoped handle:

```elixir
address = ExJsonSchema.fetch_schema!(compiled, "#/$defs/address")
ExJsonSchema.valid?(payload, address)
```

Resolvers used with untrusted schemas must enforce their own network, byte,
and resource-count limits. See the [security guide](guides/security.md).

## Formats and content

Drafts 4, 6, and 7 assert built-in formats by default. Draft 2020-12 records
them as annotations by default, as required by its general dialect. Pass
`assert_formats?: true` during validation to opt in.

Custom format validators and legacy content decoders are explicit compile
capabilities:

```elixir
compiled =
  ExJsonSchema.compile!(schema,
    formats: %{
      "even-string" => {MyFormats, :validate_even_string}
    },
    content_decoder: {Jason, :decode}
  )
```

Callbacks may be unary functions or `{module, function}` tuples. Prefer tuples
for schemas embedded in module attributes because they remain release-safe
data.

Any compile option can also be configured as an application-wide default:

```elixir
config :ex_json_schema,
  resolver: {MySchemaStore, :fetch},
  formats: %{"even-string" => {MyFormats, :validate_even_string}},
  content_decoder: {Jason, :decode}
```

Options passed directly to `compile/2` or `compile!/2` override matching
application defaults.

See the [format support guide](guides/format-support.md) for enabled optional
suites and intentional exclusions.

## Upgrading from 0.x

Version 1.0 removes the schema-first validator, raw error structs, legacy
callback configuration, and fragment-validator functions. See the
[migration guide](guides/migration-to-1.0.md) for direct replacements.

## License

Copyright (c) 2015 Jonas Schmidt

Released under the [MIT license](https://github.com/jonasschmidt/ex_json_schema/blob/master/LICENSE).
