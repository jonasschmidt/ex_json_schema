# Migrating from 0.x to 1.0

Version 1.0 replaces schema rewriting and the schema-first validator with an
eager compiler, opaque reusable handles, payload-first validation, and
standardized JSON Schema output.

## Compile schemas once

Replace:

```elixir
resolved = ExJsonSchema.Schema.resolve(schema)
```

with:

```elixir
compiled = ExJsonSchema.compile!(schema)
```

`compile/2` returns `{:ok, compiled}` or
`{:error, %ExJsonSchema.CompileError{}}`. `compile!/2` raises the same
structured error. Inputs must be decoded maps or booleans; raw JSON strings
are no longer accepted.

Schema meta-validation is enabled by default. Use `validate_schema: false`
only when the caller has a deliberate reason to accept a schema without that
check.

## Use payload-first validation

Replace schema-first calls:

```elixir
ExJsonSchema.Validator.valid?(resolved, payload)
ExJsonSchema.Validator.validate(resolved, payload)
```

with:

```elixir
ExJsonSchema.valid?(payload, compiled)
ExJsonSchema.validate(payload, compiled)
```

There is no raw-map validation overload. This prevents references and
meta-validation from being repeated accidentally for every payload.

## Consume standardized output

`validate/3` no longer returns `:ok` or legacy error tuples/structs. It returns
JSON-compatible standardized output with string keys. Basic output is the
default:

```elixir
%{"valid" => false, "errors" => errors}
```

Select `output: :flag`, `:basic`, `:detailed`, or `:verbose`. The
`error_formatter` option and per-keyword error structs were removed. Code
that needs only a boolean should call `valid?/3`.

## Fetch schemas by reference

Replace `Schema.get_fragment/2`, `validate_fragment/3`, and
`valid_fragment?/3` with a scoped compiled handle:

```elixir
with {:ok, fragment} <- ExJsonSchema.fetch_schema(compiled, "#/$defs/address") do
  ExJsonSchema.validate(payload, fragment)
end
```

`fetch_schema!/2` raises `ExJsonSchema.ReferenceError`. The returned handle
retains the same compiled resource graph and reports canonical locations from
its new entry point.

## Make remote loading explicit

The old `:remote_schema_resolver` application key is no longer read. Preload
resources or pass a resolver when compiling:

```elixir
ExJsonSchema.compile(schema,
  retrieval_uri: "https://example.test/root",
  resources: %{"https://example.test/known" => known_schema},
  resolver: {MySchemaStore, :fetch}
)
```

Resolvers must return `{:ok, decoded_schema}` or `{:error, reason}`. All
statically reachable resources are loaded eagerly. Successfully compiled
schemas perform no resolver calls during validation.

To retain an application-wide default, configure the corresponding compile
option directly:

```elixir
config :ex_json_schema,
  resolver: {MySchemaStore, :fetch}
```

Explicit options passed to `compile/2` override application defaults.

## Register custom formats explicitly

The old `:custom_format_validator` application setting and
`custom_format_validator` resolve option were removed. Register one-argument
validators by format name:

```elixir
ExJsonSchema.compile!(schema,
  formats: %{
    "custom" => {MyFormat, :validate}
  }
)
```

Draft 2020-12 formats are annotations by default. Set
`assert_formats?: true` on `validate/3` or `valid?/3` to assert them. Drafts
4, 6, and 7 retain assertion-by-default behavior.

Resolvers, format validators, and content decoders accept either unary
functions or `{module, function}` tuples. Tuples are recommended when a
compiled schema is stored in a module attribute.

## Pass content decoding directly

The old `:decode_json` application callback was removed. If legacy draft 6/7
content assertions need a decoder, pass
`content_decoder: {Jason, :decode}` to `compile/2`. Draft 2020-12 content
keywords remain annotations. Formats and content decoders can also be placed
directly in the `:ex_json_schema` application configuration.

## Inspect stable metadata

Compiled schemas are opaque. Replace matches on `Schema.Root`, `Schema.Ref`,
or rewritten maps with:

```elixir
ExJsonSchema.dialect(compiled)
ExJsonSchema.schema_location(compiled)
ExJsonSchema.resource_uris(compiled)
```

Internal graph and keyword evaluator structs are not part of the public API.
