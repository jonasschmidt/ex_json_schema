# Legacy vs current benchmark

Generated at 2026-11-03T16:05:06Z.

- Baseline: `d298fa91199482b72e8b00f24fbd80bfc94807fd` (`ex_json_schema` 0.11.5)
- Current: `d298fa91199482b72e8b00f24fbd80bfc94807fd` with working-tree changes (`ex_json_schema` 1.0.0)
- Runtime: Elixir 1.19.4, OTP 28, 14 schedulers
- Samples: 5; target time per sample: 100 ms
- Sizes: 10, 100, 1000

## Boolean-only validity

| Scenario | N | Legacy µs | Current µs | Time | Legacy reductions | Current reductions | Compute | Legacy allocation | Current allocation | Allocation | Legacy result | Current result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| valid?/items-valid | 10 | 2.07 | 0.24 | 0.12x | 525 | 197 | 0.38x | 4.4 KiB | 1017 B | 0.22x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 10 | 2.08 | 0.22 | 0.11x | 540 | 194 | 0.36x | 4.7 KiB | 1017 B | 0.21x | 0 B | 0 B | n/a |
| valid?/items-true | 10 | 0.15 | 0.08 | 0.51x | 71 | 49 | 0.69x | 488 B | 153 B | 0.31x | 0 B | 0 B | n/a |
| valid?/contains-first | 10 | 0.39 | 0.12 | 0.30x | 165 | 86 | 0.52x | 1.3 KiB | 225 B | 0.17x | 0 B | 0 B | n/a |
| valid?/contains-none | 10 | 2.13 | 0.21 | 0.10x | 669 | 175 | 0.26x | 7.6 KiB | 585 B | 0.07x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 10 | 0.52 | 0.17 | 0.33x | 224 | 88 | 0.39x | 1.8 KiB | 386 B | 0.21x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 10 | 0.34 | 0.32 | 0.93x | 126 | 129 | 1.02x | 1.9 KiB | 1.6 KiB | 0.88x | 0 B | 0 B | n/a |
| valid?/object-properties | 10 | 5.02 | 1.53 | 0.30x | 1019 | 257 | 0.25x | 8.4 KiB | 2.0 KiB | 0.24x | 0 B | 0 B | n/a |
| valid?/object-sparse | 10 | 0.89 | 0.16 | 0.18x | 375 | 86 | 0.23x | 2.3 KiB | 448 B | 0.19x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 10 | 9.02 | 4.23 | 0.47x | 1456 | 631 | 0.43x | 12.5 KiB | 4.1 KiB | 0.33x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 10 | 0.19 | 3.25 | 16.75x | 146 | 400 | 2.74x | 1.0 KiB | 5.2 KiB | 4.94x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 10 | 0.12 | 0.08 | 0.66x | 88 | 49 | 0.56x | 489 B | 159 B | 0.33x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 10 | n/a | 1.48 | n/a | n/a | 248 | n/a | n/a | 2.0 KiB | n/a | n/a | 0 B | n/a |
| valid?/items-valid | 100 | 18.5 | 1.19 | 0.06x | 4624 | 1298 | 0.28x | 39.6 KiB | 8.0 KiB | 0.20x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 100 | 19.8 | 1.21 | 0.06x | 4639 | 1295 | 0.28x | 39.8 KiB | 8.0 KiB | 0.20x | 0 B | 0 B | n/a |
| valid?/items-true | 100 | 0.15 | 0.08 | 0.54x | 71 | 84 | 1.18x | 489 B | 154 B | 0.31x | 0 B | 0 B | n/a |
| valid?/contains-first | 100 | 1.01 | 0.12 | 0.11x | 431 | 67 | 0.16x | 4.8 KiB | 227 B | 0.05x | 0 B | 0 B | n/a |
| valid?/contains-none | 100 | 18.5 | 1.12 | 0.06x | 6216 | 1094 | 0.18x | 69.4 KiB | 4.1 KiB | 0.06x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 100 | 1.20 | 0.17 | 0.15x | 434 | 88 | 0.20x | 5.3 KiB | 387 B | 0.07x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 100 | 5.53 | 5.03 | 0.91x | 542 | 656 | 1.21x | 23.5 KiB | 24.6 KiB | 1.05x | 0 B | 0 B | n/a |
| valid?/object-properties | 100 | 34.1 | 9.44 | 0.28x | 9427 | 2369 | 0.25x | 75.1 KiB | 17.2 KiB | 0.23x | 0 B | 0 B | n/a |
| valid?/object-sparse | 100 | 2.00 | 0.19 | 0.09x | 1632 | 86 | 0.05x | 6.7 KiB | 526 B | 0.08x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 100 | 45.2 | 11.5 | 0.26x | 9990 | 2600 | 0.26x | 79.8 KiB | 19.4 KiB | 0.24x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 100 | 0.84 | 3.22 | 3.85x | 393 | 977 | 2.49x | 4.6 KiB | 5.2 KiB | 1.14x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 100 | 0.12 | 0.08 | 0.69x | 69 | 49 | 0.71x | 501 B | 224 B | 0.45x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 100 | n/a | 9.25 | n/a | n/a | 2270 | n/a | n/a | 17.2 KiB | n/a | n/a | 0 B | n/a |
| valid?/items-valid | 1000 | 189.4 | 10.8 | 0.06x | 44960 | 12280 | 0.27x | 391.2 KiB | 78.4 KiB | 0.20x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 1000 | 170.4 | 11.1 | 0.07x | 44975 | 12277 | 0.27x | 391.4 KiB | 78.4 KiB | 0.20x | 0 B | 0 B | n/a |
| valid?/items-true | 1000 | 0.15 | 0.08 | 0.53x | 71 | 49 | 0.69x | 503 B | 169 B | 0.34x | 0 B | 0 B | n/a |
| valid?/contains-first | 1000 | 7.63 | 0.11 | 0.01x | 2655 | 67 | 0.03x | 40.0 KiB | 241 B | 0.01x | 0 B | 0 B | n/a |
| valid?/contains-none | 1000 | 329.0 | 10.1 | 0.03x | 57910 | 10275 | 0.18x | 688.2 KiB | 39.3 KiB | 0.06x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 1000 | 8.11 | 0.17 | 0.02x | 2720 | 88 | 0.03x | 40.5 KiB | 401 B | 0.01x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 1000 | 56.6 | 52.6 | 0.93x | 5175 | 6313 | 1.22x | 290.4 KiB | 300.2 KiB | 1.03x | 0 B | 0 B | n/a |
| valid?/object-properties | 1000 | 408.3 | 99.9 | 0.24x | 92933 | 24705 | 0.27x | 736.8 KiB | 167.9 KiB | 0.23x | 0 B | 0 B | n/a |
| valid?/object-sparse | 1000 | 16.3 | 0.21 | 0.01x | 12286 | 86 | 0.01x | 46.6 KiB | 1.3 KiB | 0.03x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 1000 | 426.8 | 103.9 | 0.24x | 92971 | 25303 | 0.27x | 742.7 KiB | 171.6 KiB | 0.23x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 1000 | 7.36 | 3.29 | 0.45x | 2913 | 315 | 0.11x | 39.8 KiB | 5.7 KiB | 0.14x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 1000 | 0.13 | 0.08 | 0.64x | 1840 | 49 | 0.03x | 629 B | 871 B | 1.38x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 1000 | n/a | 103.8 | n/a | n/a | 23883 | n/a | n/a | 164.7 KiB | n/a | n/a | 0 B | n/a |

## Full public validation

| Scenario | N | Legacy µs | Current µs | Time | Legacy reductions | Current reductions | Compute | Legacy allocation | Current allocation | Allocation | Legacy result | Current result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| validate/items-valid | 10 | 2.03 | 0.80 | 0.39x | 530 | 385 | 0.73x | 4.4 KiB | 2.8 KiB | 0.63x | 0 B | 184 B | n/a |
| validate/items-invalid-last | 10 | 2.29 | 2.21 | 0.97x | 545 | 673 | 1.23x | 4.7 KiB | 5.4 KiB | 1.15x | 328 B | 640 B | 1.95x |
| validate/items-true | 10 | 0.16 | 0.54 | 3.32x | 74 | 189 | 2.55x | 488 B | 1.3 KiB | 2.69x | 0 B | 184 B | n/a |
| validate/contains-first | 10 | 0.40 | 0.64 | 1.63x | 168 | 225 | 1.34x | 1.3 KiB | 1.5 KiB | 1.21x | 0 B | 184 B | n/a |
| validate/contains-none | 10 | 2.03 | 1.05 | 0.51x | 673 | 370 | 0.55x | 7.7 KiB | 2.5 KiB | 0.33x | 2.6 KiB | 440 B | 0.17x |
| validate/nested-contains-first | 10 | 0.53 | 0.71 | 1.33x | 226 | 263 | 1.16x | 1.8 KiB | 1.7 KiB | 0.96x | 0 B | 184 B | n/a |
| validate/unique-scalars | 10 | 0.35 | 0.86 | 2.50x | 129 | 263 | 2.04x | 1.9 KiB | 2.8 KiB | 1.52x | 0 B | 184 B | n/a |
| validate/object-properties | 10 | 4.93 | 2.05 | 0.42x | 1030 | 547 | 0.53x | 8.4 KiB | 3.8 KiB | 0.46x | 0 B | 184 B | n/a |
| validate/object-sparse | 10 | 0.79 | 0.71 | 0.90x | 378 | 229 | 0.61x | 2.3 KiB | 1.8 KiB | 0.78x | 0 B | 184 B | n/a |
| validate/object-api-assertions | 10 | 8.72 | 5.49 | 0.63x | 1460 | 856 | 0.59x | 12.5 KiB | 6.8 KiB | 0.54x | 0 B | 184 B | n/a |
| validate/anyOf-first | 10 | 0.19 | 20.7 | 106.55x | 150 | 4955 | 33.03x | 1.0 KiB | 36.7 KiB | 35.05x | 0 B | 184 B | n/a |
| validate/unused-definitions | 10 | 0.13 | 0.58 | 4.63x | 91 | 280 | 3.08x | 489 B | 1.4 KiB | 2.88x | 0 B | 184 B | n/a |
| validate/object-unevaluated | 10 | n/a | 2.08 | n/a | n/a | 511 | n/a | n/a | 3.5 KiB | n/a | n/a | 184 B | n/a |
| validate/items-valid | 100 | 15.4 | 2.89 | 0.19x | 4626 | 1933 | 0.42x | 39.6 KiB | 14.7 KiB | 0.37x | 0 B | 184 B | n/a |
| validate/items-invalid-last | 100 | 15.5 | 4.39 | 0.28x | 4641 | 2214 | 0.48x | 39.9 KiB | 17.4 KiB | 0.44x | 328 B | 640 B | 1.95x |
| validate/items-true | 100 | 0.15 | 0.54 | 3.58x | 74 | 207 | 2.80x | 489 B | 1.3 KiB | 2.69x | 0 B | 184 B | n/a |
| validate/contains-first | 100 | 1.04 | 0.68 | 0.66x | 431 | 206 | 0.48x | 4.8 KiB | 1.5 KiB | 0.32x | 0 B | 184 B | n/a |
| validate/contains-none | 100 | 19.5 | 2.03 | 0.10x | 6217 | 1287 | 0.21x | 69.5 KiB | 6.1 KiB | 0.09x | 23.0 KiB | 440 B | 0.02x |
| validate/nested-contains-first | 100 | 1.18 | 0.70 | 0.59x | 436 | 279 | 0.64x | 5.3 KiB | 1.7 KiB | 0.32x | 0 B | 184 B | n/a |
| validate/unique-scalars | 100 | 5.13 | 5.59 | 1.09x | 554 | 778 | 1.40x | 23.6 KiB | 26.3 KiB | 1.12x | 0 B | 184 B | n/a |
| validate/object-properties | 100 | 40.1 | 10.6 | 0.26x | 9428 | 2809 | 0.30x | 75.2 KiB | 24.2 KiB | 0.32x | 0 B | 184 B | n/a |
| validate/object-sparse | 100 | 2.26 | 0.62 | 0.27x | 1635 | 1308 | 0.80x | 6.7 KiB | 1.9 KiB | 0.28x | 0 B | 184 B | n/a |
| validate/object-api-assertions | 100 | 41.8 | 13.8 | 0.33x | 9993 | 3100 | 0.31x | 80.0 KiB | 26.6 KiB | 0.33x | 0 B | 184 B | n/a |
| validate/anyOf-first | 100 | 0.88 | 165.0 | 187.51x | 396 | 44181 | 111.57x | 4.6 KiB | 300.5 KiB | 65.77x | 0 B | 184 B | n/a |
| validate/unused-definitions | 100 | 0.12 | 0.57 | 4.66x | 72 | 188 | 2.61x | 502 B | 1.4 KiB | 2.93x | 0 B | 184 B | n/a |
| validate/object-unevaluated | 100 | n/a | 9.99 | n/a | n/a | 2407 | n/a | n/a | 21.0 KiB | n/a | n/a | 184 B | n/a |
| validate/items-valid | 1000 | 197.4 | 26.4 | 0.13x | 44963 | 17844 | 0.40x | 391.2 KiB | 134.3 KiB | 0.34x | 0 B | 184 B | n/a |
| validate/items-invalid-last | 1000 | 181.1 | 27.4 | 0.15x | 44978 | 18124 | 0.40x | 391.5 KiB | 136.9 KiB | 0.35x | 328 B | 640 B | 1.95x |
| validate/items-true | 1000 | 0.15 | 0.58 | 3.84x | 74 | 172 | 2.32x | 504 B | 1.3 KiB | 2.64x | 0 B | 184 B | n/a |
| validate/contains-first | 1000 | 7.47 | 0.68 | 0.09x | 2658 | 206 | 0.08x | 40.0 KiB | 1.5 KiB | 0.04x | 0 B | 184 B | n/a |
| validate/contains-none | 1000 | 331.2 | 12.0 | 0.04x | 57915 | 10468 | 0.18x | 688.2 KiB | 41.2 KiB | 0.06x | 226.9 KiB | 440 B | 0.00x |
| validate/nested-contains-first | 1000 | 7.77 | 0.72 | 0.09x | 2722 | 234 | 0.09x | 40.5 KiB | 1.7 KiB | 0.04x | 0 B | 184 B | n/a |
| validate/unique-scalars | 1000 | 58.6 | 52.7 | 0.90x | 5220 | 6339 | 1.21x | 289.6 KiB | 302.0 KiB | 1.04x | 0 B | 184 B | n/a |
| validate/object-properties | 1000 | 414.1 | 104.3 | 0.25x | 92937 | 27588 | 0.30x | 736.8 KiB | 227.2 KiB | 0.31x | 0 B | 184 B | n/a |
| validate/object-sparse | 1000 | 17.2 | 0.76 | 0.04x | 12290 | 229 | 0.02x | 45.3 KiB | 2.6 KiB | 0.06x | 0 B | 184 B | n/a |
| validate/object-api-assertions | 1000 | 445.4 | 109.8 | 0.25x | 92976 | 28201 | 0.30x | 744.2 KiB | 230.4 KiB | 0.31x | 0 B | 184 B | n/a |
| validate/anyOf-first | 1000 | 7.44 | 1828.0 | 245.55x | 2916 | 410143 | 140.65x | 39.8 KiB | 2.9 MiB | 74.25x | 0 B | 184 B | n/a |
| validate/unused-definitions | 1000 | 0.13 | 0.65 | 4.90x | 1843 | 188 | 0.10x | 629 B | 2.1 KiB | 3.37x | 0 B | 184 B | n/a |
| validate/object-unevaluated | 1000 | n/a | 110.3 | n/a | n/a | 24357 | n/a | n/a | 172.0 KiB | n/a | n/a | 184 B | n/a |

## Compilation

| Scenario | N | Legacy µs | Current µs | Time | Legacy reductions | Current reductions | Compute | Legacy allocation | Current allocation | Allocation | Legacy result | Current result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| compile/object-properties | 10 | 839.5 | 27.4 | 0.03x | 53542 | 6211 | 0.12x | 574.1 KiB | 57.8 KiB | 0.10x | 1.4 KiB | 19.2 KiB | 13.73x |
| compile/object-properties | 100 | 1040.0 | 229.4 | 0.22x | 157335 | 53931 | 0.34x | 1.2 MiB | 503.2 KiB | 0.42x | 11.1 KiB | 51.0 KiB | 4.61x |
| compile/object-properties | 1000 | 3568.1 | 2567.2 | 0.72x | 1199266 | 528091 | 0.44x | 7.2 MiB | 4.9 MiB | 0.67x | 107.4 KiB | 364.8 KiB | 3.40x |

## Compiled validator footprint

| Scenario | N | Legacy retained | Current retained | Retained | Legacy flat | Current flat | Flat |
| --- | --- | --- | --- | --- | --- | --- | --- |
| items-valid | 10 | 480 B | 16.5 KiB | 35.17x | 480 B | 17.4 KiB | 37.05x |
| items-invalid-last | 10 | 480 B | 16.5 KiB | 35.17x | 480 B | 17.4 KiB | 37.05x |
| items-true | 10 | 384 B | 16.2 KiB | 43.27x | 384 B | 17.1 KiB | 45.50x |
| contains-first | 10 | 456 B | 16.5 KiB | 37.00x | 456 B | 17.3 KiB | 38.93x |
| contains-none | 10 | 456 B | 16.5 KiB | 37.00x | 456 B | 17.3 KiB | 38.93x |
| nested-contains-first | 10 | 592 B | 17.0 KiB | 29.46x | 592 B | 18.4 KiB | 31.89x |
| unique-scalars | 10 | 392 B | 16.0 KiB | 41.86x | 392 B | 16.5 KiB | 43.18x |
| object-properties | 10 | 1.4 KiB | 19.2 KiB | 13.73x | 1.8 KiB | 28.7 KiB | 15.78x |
| object-sparse | 10 | 1.4 KiB | 19.2 KiB | 13.73x | 1.8 KiB | 28.7 KiB | 15.78x |
| object-api-assertions | 10 | 2.3 KiB | 21.9 KiB | 9.38x | 2.8 KiB | 33.8 KiB | 12.24x |
| anyOf-first | 10 | 1008 B | 17.9 KiB | 18.21x | 1.2 KiB | 24.2 KiB | 20.65x |
| unused-definitions | 10 | 1.5 KiB | 19.8 KiB | 12.78x | 1.8 KiB | 26.0 KiB | 14.77x |
| object-unevaluated | 10 | n/a | 12.5 KiB | n/a | n/a | 23.0 KiB | n/a |
| items-valid | 100 | 480 B | 16.5 KiB | 35.17x | 480 B | 17.4 KiB | 37.05x |
| items-invalid-last | 100 | 480 B | 16.5 KiB | 35.17x | 480 B | 17.4 KiB | 37.05x |
| items-true | 100 | 384 B | 16.2 KiB | 43.27x | 384 B | 17.1 KiB | 45.50x |
| contains-first | 100 | 456 B | 16.5 KiB | 37.00x | 456 B | 17.3 KiB | 38.93x |
| contains-none | 100 | 456 B | 16.5 KiB | 37.00x | 456 B | 17.3 KiB | 38.93x |
| nested-contains-first | 100 | 592 B | 17.0 KiB | 29.46x | 592 B | 18.4 KiB | 31.89x |
| unique-scalars | 100 | 392 B | 16.0 KiB | 41.86x | 392 B | 16.5 KiB | 43.18x |
| object-properties | 100 | 11.1 KiB | 51.0 KiB | 4.61x | 15.7 KiB | 144.2 KiB | 9.18x |
| object-sparse | 100 | 11.1 KiB | 51.0 KiB | 4.61x | 15.7 KiB | 144.2 KiB | 9.18x |
| object-api-assertions | 100 | 12.0 KiB | 53.9 KiB | 4.48x | 16.7 KiB | 149.4 KiB | 8.96x |
| anyOf-first | 100 | 6.6 KiB | 37.2 KiB | 5.62x | 8.9 KiB | 99.7 KiB | 11.19x |
| unused-definitions | 100 | 14.1 KiB | 59.4 KiB | 4.21x | 16.4 KiB | 119.8 KiB | 7.29x |
| object-unevaluated | 100 | n/a | 44.4 KiB | n/a | n/a | 138.6 KiB | n/a |
| items-valid | 1000 | 480 B | 16.5 KiB | 35.17x | 480 B | 17.4 KiB | 37.05x |
| items-invalid-last | 1000 | 480 B | 16.5 KiB | 35.17x | 480 B | 17.4 KiB | 37.05x |
| items-true | 1000 | 384 B | 16.2 KiB | 43.27x | 384 B | 17.1 KiB | 45.50x |
| contains-first | 1000 | 456 B | 16.5 KiB | 37.00x | 456 B | 17.3 KiB | 38.93x |
| contains-none | 1000 | 456 B | 16.5 KiB | 37.00x | 456 B | 17.3 KiB | 38.93x |
| nested-contains-first | 1000 | 592 B | 17.0 KiB | 29.46x | 592 B | 18.4 KiB | 31.89x |
| unique-scalars | 1000 | 392 B | 16.0 KiB | 41.86x | 392 B | 16.5 KiB | 43.18x |
| object-properties | 1000 | 107.4 KiB | 364.8 KiB | 3.40x | 154.2 KiB | 1.3 MiB | 8.40x |
| object-sparse | 1000 | 107.4 KiB | 364.8 KiB | 3.40x | 154.2 KiB | 1.3 MiB | 8.40x |
| object-api-assertions | 1000 | 108.4 KiB | 367.8 KiB | 3.39x | 155.2 KiB | 1.3 MiB | 8.37x |
| anyOf-first | 1000 | 62.9 KiB | 228.5 KiB | 3.64x | 86.3 KiB | 853.5 KiB | 9.90x |
| unused-definitions | 1000 | 138.6 KiB | 452.1 KiB | 3.26x | 162.0 KiB | 1.0 MiB | 6.50x |
| object-unevaluated | 1000 | n/a | 358.2 KiB | n/a | n/a | 1.3 MiB | n/a |

Ratios are current divided by legacy; values above `1.00x` are regressions.
Time is the median wall time per operation. Reductions are measured for one
operation in an isolated process. Allocation is estimated from words
reclaimed by BEAM garbage collections over repeated calls. Result and
retained-schema sizes count shared subterms once; flat schema size counts
shared subterms each time they are referenced.

Validation scenarios compile their schema outside the measured operation.
Shared validation scenarios use Draft 7. `object-unevaluated` is a current-only
Draft 2020-12 scenario because the legacy release does not support that
keyword. `compile/*` compares the current no-metaschema-validation path with
the legacy release's normal resolve path, which always validates its schema.
Diagnostic output differs by API contract: legacy returns raw error structs
and current returns standardized basic output.
