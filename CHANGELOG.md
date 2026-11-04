# Changelog

## 1.0.0 - 2026-11-02

### Added

- JSON Schema draft 2020-12, including standard vocabularies, dynamic
  references, unevaluated keywords, annotations, and standardized output
- Eager immutable compilation with explicit preloaded resources and resolver
  callbacks
- Payload-first `ExJsonSchema.validate/3` and `valid?/3`
- Scoped compiled handles through `fetch_schema/2` and `fetch_schema!/2`
- Flag, basic, detailed, and verbose output modes
- Explicit custom format and legacy content-decoder capabilities
- Release-safe `{module, function}` callbacks and application-wide compile
  option defaults

### Changed

- The minimum runtime is Elixir 1.15 and OTP 25.
- Draft 2020-12 formats are annotations by default; drafts 4, 6, and 7 retain
  format assertion by default.
- Validation performs no resource-loading I/O after successful compilation.

### Removed

- The schema-first `ExJsonSchema.Schema` and `ExJsonSchema.Validator` APIs
- Public root, reference, keyword evaluator, and legacy error structs
- Raw-map validation and custom error formatter options

See `guides/migration-to-1.0.md` for replacements.
