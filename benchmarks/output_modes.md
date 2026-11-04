# Output mode benchmark

Measured on 2026-11-04 with the repository's default `mise` toolchain. The
fixture validates 20 nested object instances, including four failures, for 500
iterations per mode.

- Flag: 104.2 µs per validation; 23 encoded bytes.
- Basic: 550.1 µs per validation; 3939 encoded bytes.
- Detailed: 544.2 µs per validation; 28769 encoded bytes.
- Verbose: 560.9 µs per validation; 28868 encoded bytes.

Flag output is over five times faster because it can use boolean-only
evaluation without constructing diagnostics. Basic, detailed, and verbose have
similar evaluation time; detailed and verbose outputs are roughly seven times
larger than basic output for this failing nested fixture.

Re-run with:

`mise exec -- mix run benchmarks/output_modes.exs`
