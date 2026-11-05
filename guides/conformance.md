# Conformance

The official JSON Schema Test Suite submodule is pinned to commit
`3f05891cac5d51ffa068d7076d1372130e00c829` from 2026-10-31.

Release verification on the supported runtimes reports 6,842 ExUnit tests,
zero failures, and 2,846 generated skips. Skips are the optional upstream
cases intentionally excluded by the explicit manifest, plus suite cases that
do not apply to a tested dialect.

The release matrix includes:

- Drafts 4, 6, and 7 required validation: 4,226 generated tests pass,
  with 1,789 non-applicable or optional generated skips.
- Draft 2020-12 required validation: 2,355 generated tests pass, with
  1,057 optional generated skips.
- Compatible annotation fixtures: all enabled cases pass for drafts 4, 6, 7,
  and 2020-12.
- Draft 2020-12 standardized output fixtures: all enabled basic-output cases
  pass.
- Every enabled Draft 2020-12 validation and format case exercises flag,
  basic, detailed, and verbose output. Independent assertions verify root
  validity, JSON Pointer and absolute locations, flat basic output, condensed
  detailed output, recursive verbose structure, and semantic agreement between
  the optimized and contextual basic paths.
- Optional validation and format fixtures: all 21 enabled suite files pass.
- Optional exclusions: all 13 excluded suite files have a technical
  classification and reason in
  `ExJsonSchema.Test.Support.OptionalSuiteManifest`.

The CI runtime matrix is Elixir 1.15.8 / OTP 25.3.2.9, Elixir 1.18.1 /
OTP 27.2, and Elixir 1.19.4 / OTP 28.3.
