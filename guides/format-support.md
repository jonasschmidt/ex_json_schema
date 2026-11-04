# Optional format support

Draft 2020-12 treats `format` as an annotation unless format assertion is
explicitly enabled. When assertions are enabled, this release provides
dependency-free validators for:

- `date`, `date-time`, `duration`, and `time`
- `email`, `ipv4`, `ipv6`, and `uuid`
- `hostname` for ordinary LDH labels (IDNA A-label conformance is excluded)
- `json-pointer`, `relative-json-pointer`, and `regex`
- `uri`, `uri-reference`, and `uri-template`

Unknown formats remain annotations and do not invalidate an instance. Custom
validators can be registered through the `:formats` compile option.

The executable list of enabled and skipped upstream optional suites is
`ExJsonSchema.Test.Support.OptionalSuiteManifest`. A test compares that
manifest with every JSON file in the pinned upstream optional directory, so a
new or unclassified exclusion fails the test suite.

## IDNA dependency spike

The spike evaluated Erlang `:idna` 6.1.1, currently present only as a
test-only transitive dependency of HTTPoison/Hackney. A wrapper around
`:idna.encode/1` passed 83 of 95 string cases in the upstream
`idn-hostname` suite and 16 of 18 string cases in `idn-email`.

The failures include required UTS 46 mapping and normalization, Bidi checks,
canonical A-label checks, and empty-label handling. In particular, fullwidth
digits, zero-width-space mapping, and decomposed NFC input are valid upstream
cases but are rejected by this package. Adding it directly would also add
`unicode_util_compat` as a runtime dependency and would not produce conformant
results. IDN hostname/email and the A-label-dependent hostname suite therefore
remain classified skips.

## URI/IRI dependency spike

The spike evaluated `:gluri` 2.0.8. It is a Gleam package with transitive
`gleam_stdlib` and `splitter` dependencies. Hex exposes no `mix.exs`,
`rebar.config`, or `Makefile`, so Mix cannot compile or install it without
adding a separate Gleam build integration. As a result, the IRI suites could
not be executed through the supported Elixir build and runtime matrix.

The dependency is not added. `iri` and `iri-reference` remain classified
skips; dependency-free RFC 3986 validators cover `uri` and `uri-reference`.
