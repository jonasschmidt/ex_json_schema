# Benchmarks

## Current vs legacy comparison

`compare_rewrite.exs` compares the current working tree with the legacy
`v0.11.5` implementation. It checks out the baseline in a temporary detached
worktree, runs the shared Draft 7 workload against both versions, prints a
comparison, and removes the temporary worktree.

Run the default workload:

```shell
mise exec -- elixir benchmarks/compare_rewrite.exs
```

Record a Markdown report:

```shell
mise exec -- elixir benchmarks/compare_rewrite.exs \
  --output benchmarks/rewrite_comparison.md
```

The most recent recorded run is in `rewrite_comparison.md`.

Use `--baseline-ref` to compare another release or commit. `--sizes`,
`--samples`, and `--target-ms` control the generated collection sizes and
measurement duration:

```shell
mise exec -- elixir benchmarks/compare_rewrite.exs \
  --baseline-ref v0.11.5 \
  --sizes 10,100,1000,5000 \
  --samples 7 \
  --target-ms 200
```

The report includes median wall time, BEAM reductions, estimated temporary
allocation, retained result size, and compiled-validator footprint. Allocation
is estimated from words reclaimed by garbage collection over repeated calls.
Retained sizes count shared BEAM subterms once; flat sizes count shared terms
for each reference and approximate copying without preserved sharing.

The shared scenarios match the JSV comparison where Draft 7 has equivalent
semantics:

- valid arrays and arrays invalid at the last item;
- trivial `items: true` and nested `contains` arrays;
- an early and absent `contains` match;
- unique scalar arrays;
- dense and sparse objects with many declared properties;
- API-style required, enum, string, and numeric assertions;
- early-success `anyOf` and unused annotated definitions;
- boolean-only and diagnostic validation for every scenario; and
- compilation of increasingly wide object schemas.

The report also records the Draft 2020-12 `unevaluatedProperties` scenario for
the current version without a legacy ratio because 0.11 does not support that
keyword. Validation schemas are prepared outside the timed operation. The
compile scenario compares the current no-metaschema-validation path with the
legacy resolver, which always validates its schema. Diagnostic result sizes are
not directly equivalent because 0.11 returns legacy errors while 1.0 returns
standardized output.

The low-level `rewrite_workload.exs` script can also run directly in either
checkout. Its final output is a machine-readable marker consumed by the
comparison runner.

## JSV comparison

`compare_jsv.exs` compares this working tree with JSV 0.26.2 using shared
Draft 2020-12 workloads:

```shell
mise exec -- elixir benchmarks/compare_jsv.exs \
  --output benchmarks/jsv_comparison.md
```

The script installs JSV in Mix's script cache and does not add it as a project
dependency. JSV 0.26.2 does not expose `valid?`, so its validation rows classify
the result of `JSV.validate(cast: false)`. The most recent recorded run is in
`jsv_comparison.md`. The report uses the same allocation and compiled-validator
footprint metrics as the legacy comparison.

## Output modes

`output_modes.exs` compares flag, basic, detailed, and verbose output for the
rewrite using one representative nested schema:

```shell
mise exec -- mix run benchmarks/output_modes.exs
```

The most recent recorded result and interpretation are in `output_modes.md`.
