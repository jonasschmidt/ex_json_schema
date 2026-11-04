# Output mode benchmark

Measured on 2026-11-02 with the repository's default `mise` toolchain. The
fixture validates 20 nested object instances, including four failures, for 500
iterations per mode.

- Flag: 1359.0 µs per validation; 23 encoded bytes.
- Basic: 1371.2 µs per validation; 3939 encoded bytes.
- Detailed: 1411.8 µs per validation; 28769 encoded bytes.
- Verbose: 1425.1 µs per validation; 28868 encoded bytes.

This run found little evaluation-time difference because the evaluator retains
the annotations needed by unevaluated keywords in every mode. Output allocation
is the material cost: detailed and verbose outputs were roughly seven times
larger than basic output for this failing nested fixture.

Re-run with:

`mise exec -- mix run benchmarks/output_modes.exs`
