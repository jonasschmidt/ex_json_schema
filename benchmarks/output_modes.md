# Output mode benchmark

Measured on 2026-11-04 with the repository's default `mise` toolchain. The
fixture validates 20 nested object instances, including four failures, for 500
iterations per mode.

- Flag: 105.7 µs per validation; 23 encoded bytes.
- Basic: 544.6 µs per validation; 3939 encoded bytes.
- Detailed: 525.8 µs per validation; 3666 encoded bytes.
- Verbose: 531.1 µs per validation; 28868 encoded bytes.

Flag output is over five times faster because it can use boolean-only
evaluation without constructing diagnostics. Basic, detailed, and verbose have
similar evaluation time. Detailed output is smaller than basic because it
prunes irrelevant branches and collapses single-child nodes, while verbose
retains the complete tree and is roughly seven times larger than basic.

Re-run with:

`mise exec -- mix run benchmarks/output_modes.exs`
