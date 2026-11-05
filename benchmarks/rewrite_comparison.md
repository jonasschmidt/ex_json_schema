# Legacy vs current benchmark

Generated at 2026-11-04T16:36:53Z.

- Baseline: `d298fa91199482b72e8b00f24fbd80bfc94807fd` (`ex_json_schema` 0.11.5)
- Current: `e05f3f376232ed3301882c26fc5b5191618f2170` with working-tree changes (`ex_json_schema` 1.0.0)
- Runtime: Elixir 1.19.4, OTP 28, 14 schedulers
- Samples: 5; target time per sample: 100 ms
- Sizes: 10, 100, 1000

## Boolean-only validity

| Scenario | N | Legacy µs | Current µs | Time | Legacy reductions | Current reductions | Compute | Legacy allocation | Current allocation | Allocation | Legacy result | Current result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| valid?/items-valid | 10 | 1.90 | 0.26 | 0.14x | 525 | 203 | 0.39x | 4.4 KiB | 1.1 KiB | 0.25x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 10 | 1.94 | 0.25 | 0.13x | 540 | 200 | 0.37x | 4.7 KiB | 1.1 KiB | 0.24x | 0 B | 0 B | n/a |
| valid?/items-true | 10 | 0.14 | 0.10 | 0.68x | 71 | 53 | 0.75x | 488 B | 225 B | 0.46x | 0 B | 0 B | n/a |
| valid?/contains-first | 10 | 0.34 | 0.15 | 0.43x | 165 | 92 | 0.56x | 1.3 KiB | 345 B | 0.27x | 0 B | 0 B | n/a |
| valid?/contains-none | 10 | 1.91 | 0.24 | 0.13x | 669 | 181 | 0.27x | 7.6 KiB | 705 B | 0.09x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 10 | 0.57 | 0.22 | 0.39x | 224 | 118 | 0.53x | 1.8 KiB | 553 B | 0.31x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 10 | 0.36 | 0.31 | 0.87x | 126 | 133 | 1.06x | 1.9 KiB | 1.7 KiB | 0.91x | 0 B | 0 B | n/a |
| valid?/object-properties | 10 | 4.97 | 1.67 | 0.34x | 1019 | 349 | 0.34x | 8.4 KiB | 2.5 KiB | 0.30x | 0 B | 0 B | n/a |
| valid?/object-sparse | 10 | 0.81 | 0.18 | 0.23x | 375 | 93 | 0.25x | 2.3 KiB | 564 B | 0.24x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 10 | 7.87 | 3.90 | 0.50x | 1456 | 574 | 0.39x | 12.5 KiB | 4.4 KiB | 0.35x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 10 | 0.18 | 0.14 | 0.78x | 146 | 72 | 0.49x | 1.0 KiB | 347 B | 0.32x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 10 | 0.12 | 0.09 | 0.80x | 88 | 53 | 0.60x | 489 B | 227 B | 0.46x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 10 | n/a | 1.67 | n/a | n/a | 282 | n/a | n/a | 2.5 KiB | n/a | n/a | 0 B | n/a |
| valid?/items-valid | 100 | 17.9 | 1.20 | 0.07x | 4624 | 1303 | 0.28x | 39.6 KiB | 8.1 KiB | 0.21x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 100 | 17.7 | 1.21 | 0.07x | 4639 | 1300 | 0.28x | 39.8 KiB | 8.1 KiB | 0.20x | 0 B | 0 B | n/a |
| valid?/items-true | 100 | 0.14 | 0.10 | 0.68x | 71 | 53 | 0.75x | 489 B | 226 B | 0.46x | 0 B | 0 B | n/a |
| valid?/contains-first | 100 | 1.09 | 0.15 | 0.14x | 431 | 108 | 0.25x | 4.8 KiB | 346 B | 0.07x | 0 B | 0 B | n/a |
| valid?/contains-none | 100 | 19.9 | 1.12 | 0.06x | 6216 | 1098 | 0.18x | 69.4 KiB | 4.2 KiB | 0.06x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 100 | 1.19 | 0.22 | 0.19x | 434 | 98 | 0.23x | 5.3 KiB | 555 B | 0.10x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 100 | 4.97 | 4.87 | 0.98x | 542 | 647 | 1.19x | 23.3 KiB | 24.9 KiB | 1.07x | 0 B | 0 B | n/a |
| valid?/object-properties | 100 | 36.1 | 10.8 | 0.30x | 9518 | 3198 | 0.34x | 75.1 KiB | 22.0 KiB | 0.29x | 0 B | 0 B | n/a |
| valid?/object-sparse | 100 | 2.02 | 0.22 | 0.11x | 1632 | 93 | 0.06x | 6.7 KiB | 593 B | 0.09x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 100 | 38.2 | 13.1 | 0.34x | 9984 | 3454 | 0.35x | 79.7 KiB | 23.9 KiB | 0.30x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 100 | 0.75 | 0.16 | 0.22x | 393 | 72 | 0.18x | 4.6 KiB | 364 B | 0.08x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 100 | 0.11 | 0.10 | 0.85x | 69 | 53 | 0.77x | 501 B | 249 B | 0.50x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 100 | n/a | 10.7 | n/a | n/a | 3102 | n/a | n/a | 21.9 KiB | n/a | n/a | 0 B | n/a |
| valid?/items-valid | 1000 | 180.3 | 10.9 | 0.06x | 44960 | 12285 | 0.27x | 391.2 KiB | 78.5 KiB | 0.20x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 1000 | 166.6 | 10.9 | 0.07x | 44975 | 12282 | 0.27x | 391.4 KiB | 78.5 KiB | 0.20x | 0 B | 0 B | n/a |
| valid?/items-true | 1000 | 0.22 | 0.10 | 0.44x | 71 | 53 | 0.75x | 503 B | 241 B | 0.48x | 0 B | 0 B | n/a |
| valid?/contains-first | 1000 | 7.19 | 0.15 | 0.02x | 2655 | 74 | 0.03x | 40.0 KiB | 361 B | 0.01x | 0 B | 0 B | n/a |
| valid?/contains-none | 1000 | 319.7 | 10.1 | 0.03x | 57910 | 10280 | 0.18x | 688.2 KiB | 39.4 KiB | 0.06x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 1000 | 7.73 | 0.22 | 0.03x | 2720 | 98 | 0.04x | 40.5 KiB | 569 B | 0.01x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 1000 | 57.1 | 50.6 | 0.89x | 5175 | 6367 | 1.23x | 290.3 KiB | 300.7 KiB | 1.04x | 0 B | 0 B | n/a |
| valid?/object-properties | 1000 | 384.5 | 118.8 | 0.31x | 92933 | 29850 | 0.32x | 736.1 KiB | 217.2 KiB | 0.30x | 0 B | 0 B | n/a |
| valid?/object-sparse | 1000 | 15.9 | 0.23 | 0.01x | 12286 | 93 | 0.01x | 46.6 KiB | 890 B | 0.02x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 1000 | 391.4 | 125.3 | 0.32x | 92972 | 26314 | 0.28x | 743.8 KiB | 216.3 KiB | 0.29x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 1000 | 6.91 | 0.16 | 0.02x | 2913 | 72 | 0.02x | 39.8 KiB | 543 B | 0.01x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 1000 | 0.11 | 0.10 | 0.88x | 1840 | 53 | 0.03x | 629 B | 468 B | 0.74x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 1000 | n/a | 122.1 | n/a | n/a | 25800 | n/a | n/a | 217.1 KiB | n/a | n/a | 0 B | n/a |

## Full public validation

| Scenario | N | Legacy µs | Current µs | Time | Legacy reductions | Current reductions | Compute | Legacy allocation | Current allocation | Allocation | Legacy result | Current result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| validate/items-valid | 10 | 1.82 | 0.26 | 0.14x | 530 | 209 | 0.39x | 4.4 KiB | 1.1 KiB | 0.25x | 0 B | 200 B | n/a |
| validate/items-invalid-last | 10 | 1.72 | 2.28 | 1.33x | 545 | 823 | 1.51x | 4.7 KiB | 6.8 KiB | 1.44x | 328 B | 640 B | 1.95x |
| validate/items-true | 10 | 0.14 | 0.10 | 0.71x | 74 | 60 | 0.81x | 488 B | 241 B | 0.49x | 0 B | 200 B | n/a |
| validate/contains-first | 10 | 0.39 | 0.16 | 0.41x | 168 | 98 | 0.58x | 1.3 KiB | 361 B | 0.28x | 0 B | 200 B | n/a |
| validate/contains-none | 10 | 1.95 | 1.21 | 0.62x | 673 | 492 | 0.73x | 7.7 KiB | 3.2 KiB | 0.42x | 2.6 KiB | 440 B | 0.17x |
| validate/nested-contains-first | 10 | 0.48 | 0.23 | 0.48x | 226 | 125 | 0.55x | 1.8 KiB | 569 B | 0.31x | 0 B | 200 B | n/a |
| validate/unique-scalars | 10 | 0.33 | 0.32 | 0.98x | 129 | 140 | 1.09x | 1.9 KiB | 1.8 KiB | 0.94x | 0 B | 200 B | n/a |
| validate/object-properties | 10 | 4.33 | 1.71 | 0.40x | 1030 | 355 | 0.34x | 8.4 KiB | 2.5 KiB | 0.30x | 0 B | 200 B | n/a |
| validate/object-sparse | 10 | 0.73 | 0.19 | 0.26x | 378 | 153 | 0.40x | 2.3 KiB | 580 B | 0.25x | 0 B | 200 B | n/a |
| validate/object-api-assertions | 10 | 7.92 | 4.01 | 0.51x | 1460 | 581 | 0.40x | 12.5 KiB | 4.4 KiB | 0.35x | 0 B | 200 B | n/a |
| validate/anyOf-first | 10 | 0.18 | 0.15 | 0.81x | 150 | 79 | 0.53x | 1.0 KiB | 362 B | 0.34x | 0 B | 200 B | n/a |
| validate/unused-definitions | 10 | 0.12 | 0.10 | 0.84x | 91 | 60 | 0.66x | 489 B | 243 B | 0.50x | 0 B | 200 B | n/a |
| validate/object-unevaluated | 10 | n/a | 1.65 | n/a | n/a | 289 | n/a | n/a | 2.5 KiB | n/a | n/a | 200 B | n/a |
| validate/items-valid | 100 | 18.5 | 1.22 | 0.07x | 4626 | 1310 | 0.28x | 39.6 KiB | 8.2 KiB | 0.21x | 0 B | 200 B | n/a |
| validate/items-invalid-last | 100 | 16.8 | 5.41 | 0.32x | 4641 | 3537 | 0.76x | 39.9 KiB | 27.9 KiB | 0.70x | 328 B | 640 B | 1.95x |
| validate/items-true | 100 | 0.15 | 0.11 | 0.72x | 74 | 93 | 1.26x | 489 B | 242 B | 0.49x | 0 B | 200 B | n/a |
| validate/contains-first | 100 | 1.01 | 0.16 | 0.16x | 431 | 115 | 0.27x | 4.8 KiB | 362 B | 0.07x | 0 B | 200 B | n/a |
| validate/contains-none | 100 | 19.6 | 3.12 | 0.16x | 6217 | 2310 | 0.37x | 69.5 KiB | 10.2 KiB | 0.15x | 23.0 KiB | 440 B | 0.02x |
| validate/nested-contains-first | 100 | 1.17 | 0.23 | 0.20x | 436 | 105 | 0.24x | 5.3 KiB | 568 B | 0.11x | 0 B | 200 B | n/a |
| validate/unique-scalars | 100 | 5.07 | 4.92 | 0.97x | 554 | 653 | 1.18x | 24.0 KiB | 24.9 KiB | 1.04x | 0 B | 200 B | n/a |
| validate/object-properties | 100 | 40.2 | 10.6 | 0.26x | 9429 | 3206 | 0.34x | 75.1 KiB | 22.0 KiB | 0.29x | 0 B | 200 B | n/a |
| validate/object-sparse | 100 | 2.01 | 0.23 | 0.11x | 1635 | 100 | 0.06x | 6.7 KiB | 609 B | 0.09x | 0 B | 200 B | n/a |
| validate/object-api-assertions | 100 | 42.6 | 13.1 | 0.31x | 9991 | 3465 | 0.35x | 79.9 KiB | 23.1 KiB | 0.29x | 0 B | 200 B | n/a |
| validate/anyOf-first | 100 | 0.76 | 0.17 | 0.23x | 396 | 79 | 0.20x | 4.6 KiB | 380 B | 0.08x | 0 B | 200 B | n/a |
| validate/unused-definitions | 100 | 0.12 | 0.11 | 0.88x | 72 | 60 | 0.83x | 502 B | 265 B | 0.53x | 0 B | 200 B | n/a |
| validate/object-unevaluated | 100 | n/a | 10.7 | n/a | n/a | 3110 | n/a | n/a | 22.0 KiB | n/a | n/a | 200 B | n/a |
| validate/items-valid | 1000 | 164.5 | 10.8 | 0.07x | 44963 | 12292 | 0.27x | 391.2 KiB | 78.5 KiB | 0.20x | 0 B | 200 B | n/a |
| validate/items-invalid-last | 1000 | 166.0 | 37.7 | 0.23x | 44978 | 30222 | 0.67x | 391.5 KiB | 238.9 KiB | 0.61x | 328 B | 640 B | 1.95x |
| validate/items-true | 1000 | 0.15 | 0.10 | 0.71x | 74 | 60 | 0.81x | 504 B | 257 B | 0.51x | 0 B | 200 B | n/a |
| validate/contains-first | 1000 | 7.60 | 0.16 | 0.02x | 2658 | 81 | 0.03x | 40.0 KiB | 377 B | 0.01x | 0 B | 200 B | n/a |
| validate/contains-none | 1000 | 321.7 | 20.6 | 0.06x | 57915 | 20492 | 0.35x | 688.2 KiB | 80.6 KiB | 0.12x | 226.9 KiB | 440 B | 0.00x |
| validate/nested-contains-first | 1000 | 7.81 | 0.23 | 0.03x | 2722 | 105 | 0.04x | 40.5 KiB | 585 B | 0.01x | 0 B | 200 B | n/a |
| validate/unique-scalars | 1000 | 54.5 | 51.2 | 0.94x | 5220 | 6208 | 1.19x | 289.6 KiB | 300.7 KiB | 1.04x | 0 B | 200 B | n/a |
| validate/object-properties | 1000 | 384.7 | 119.2 | 0.31x | 92937 | 29869 | 0.32x | 736.8 KiB | 216.9 KiB | 0.29x | 0 B | 200 B | n/a |
| validate/object-sparse | 1000 | 17.3 | 0.24 | 0.01x | 12290 | 100 | 0.01x | 45.3 KiB | 906 B | 0.02x | 0 B | 200 B | n/a |
| validate/object-api-assertions | 1000 | 390.5 | 123.4 | 0.32x | 92974 | 26339 | 0.28x | 742.5 KiB | 218.1 KiB | 0.29x | 0 B | 200 B | n/a |
| validate/anyOf-first | 1000 | 6.75 | 0.17 | 0.03x | 2916 | 79 | 0.03x | 39.8 KiB | 559 B | 0.01x | 0 B | 200 B | n/a |
| validate/unused-definitions | 1000 | 0.12 | 0.11 | 0.94x | 1843 | 60 | 0.03x | 629 B | 484 B | 0.77x | 0 B | 200 B | n/a |
| validate/object-unevaluated | 1000 | n/a | 120.0 | n/a | n/a | 25801 | n/a | n/a | 217.3 KiB | n/a | n/a | 200 B | n/a |

## Compilation

| Scenario | N | Legacy µs | Current µs | Time | Legacy reductions | Current reductions | Compute | Legacy allocation | Current allocation | Allocation | Legacy result | Current result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| compile/object-properties | 10 | 815.1 | 20.7 | 0.03x | 53542 | 4264 | 0.08x | 574.1 KiB | 47.2 KiB | 0.08x | 1.4 KiB | 4.3 KiB | 3.11x |
| compile/object-properties | 100 | 1032.0 | 164.9 | 0.16x | 157337 | 32322 | 0.21x | 1.2 MiB | 378.9 KiB | 0.32x | 11.1 KiB | 25.1 KiB | 2.26x |
| compile/object-properties | 1000 | 3277.6 | 1978.6 | 0.60x | 1199493 | 306781 | 0.26x | 7.2 MiB | 3.7 MiB | 0.51x | 107.4 KiB | 230.0 KiB | 2.14x |

## Compiled validator footprint

| Scenario | N | Legacy retained | Current retained | Retained | Legacy flat | Current flat | Flat |
| --- | --- | --- | --- | --- | --- | --- | --- |
| items-valid | 10 | 480 B | 2.5 KiB | 5.30x | 480 B | 3.0 KiB | 6.42x |
| items-invalid-last | 10 | 480 B | 2.5 KiB | 5.30x | 480 B | 3.0 KiB | 6.42x |
| items-true | 10 | 384 B | 2.2 KiB | 5.94x | 384 B | 2.7 KiB | 7.21x |
| contains-first | 10 | 456 B | 2.5 KiB | 5.54x | 456 B | 3.0 KiB | 6.67x |
| contains-none | 10 | 456 B | 2.5 KiB | 5.54x | 456 B | 3.0 KiB | 6.67x |
| nested-contains-first | 10 | 592 B | 3.0 KiB | 5.11x | 592 B | 3.6 KiB | 6.27x |
| unique-scalars | 10 | 392 B | 2.1 KiB | 5.47x | 392 B | 2.5 KiB | 6.53x |
| object-properties | 10 | 1.4 KiB | 4.3 KiB | 3.11x | 1.8 KiB | 7.2 KiB | 3.97x |
| object-sparse | 10 | 1.4 KiB | 4.3 KiB | 3.11x | 1.8 KiB | 7.2 KiB | 3.97x |
| object-api-assertions | 10 | 2.3 KiB | 6.8 KiB | 2.92x | 2.8 KiB | 10.8 KiB | 3.92x |
| anyOf-first | 10 | 1008 B | 4.0 KiB | 4.09x | 1.2 KiB | 5.5 KiB | 4.73x |
| unused-definitions | 10 | 1.5 KiB | 3.9 KiB | 2.54x | 1.8 KiB | 5.3 KiB | 3.02x |
| object-unevaluated | 10 | n/a | 5.2 KiB | n/a | n/a | 8.2 KiB | n/a |
| items-valid | 100 | 480 B | 2.5 KiB | 5.30x | 480 B | 3.0 KiB | 6.42x |
| items-invalid-last | 100 | 480 B | 2.5 KiB | 5.30x | 480 B | 3.0 KiB | 6.42x |
| items-true | 100 | 384 B | 2.2 KiB | 5.94x | 384 B | 2.7 KiB | 7.21x |
| contains-first | 100 | 456 B | 2.5 KiB | 5.54x | 456 B | 3.0 KiB | 6.67x |
| contains-none | 100 | 456 B | 2.5 KiB | 5.54x | 456 B | 3.0 KiB | 6.67x |
| nested-contains-first | 100 | 592 B | 3.0 KiB | 5.11x | 592 B | 3.6 KiB | 6.27x |
| unique-scalars | 100 | 392 B | 2.1 KiB | 5.47x | 392 B | 2.5 KiB | 6.53x |
| object-properties | 100 | 11.1 KiB | 25.1 KiB | 2.26x | 15.7 KiB | 50.4 KiB | 3.21x |
| object-sparse | 100 | 11.1 KiB | 25.1 KiB | 2.26x | 15.7 KiB | 50.4 KiB | 3.21x |
| object-api-assertions | 100 | 12.0 KiB | 27.6 KiB | 2.30x | 16.7 KiB | 54.1 KiB | 3.25x |
| anyOf-first | 100 | 6.6 KiB | 19.3 KiB | 2.92x | 8.9 KiB | 31.4 KiB | 3.52x |
| unused-definitions | 100 | 14.1 KiB | 22.7 KiB | 1.61x | 16.4 KiB | 33.2 KiB | 2.02x |
| object-unevaluated | 100 | n/a | 25.9 KiB | n/a | n/a | 51.4 KiB | n/a |
| items-valid | 1000 | 480 B | 2.5 KiB | 5.30x | 480 B | 3.0 KiB | 6.42x |
| items-invalid-last | 1000 | 480 B | 2.5 KiB | 5.30x | 480 B | 3.0 KiB | 6.42x |
| items-true | 1000 | 384 B | 2.2 KiB | 5.94x | 384 B | 2.7 KiB | 7.21x |
| contains-first | 1000 | 456 B | 2.5 KiB | 5.54x | 456 B | 3.0 KiB | 6.67x |
| contains-none | 1000 | 456 B | 2.5 KiB | 5.54x | 456 B | 3.0 KiB | 6.67x |
| nested-contains-first | 1000 | 592 B | 3.0 KiB | 5.11x | 592 B | 3.6 KiB | 6.27x |
| unique-scalars | 1000 | 392 B | 2.1 KiB | 5.47x | 392 B | 2.5 KiB | 6.53x |
| object-properties | 1000 | 107.4 KiB | 230.0 KiB | 2.14x | 154.2 KiB | 480.4 KiB | 3.11x |
| object-sparse | 1000 | 107.4 KiB | 230.0 KiB | 2.14x | 154.2 KiB | 480.4 KiB | 3.11x |
| object-api-assertions | 1000 | 108.4 KiB | 232.7 KiB | 2.15x | 155.2 KiB | 484.2 KiB | 3.12x |
| anyOf-first | 1000 | 62.9 KiB | 172.2 KiB | 2.74x | 86.3 KiB | 289.7 KiB | 3.36x |
| unused-definitions | 1000 | 138.6 KiB | 208.5 KiB | 1.50x | 162.0 KiB | 310.4 KiB | 1.92x |
| object-unevaluated | 1000 | n/a | 230.8 KiB | n/a | n/a | 481.4 KiB | n/a |

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
