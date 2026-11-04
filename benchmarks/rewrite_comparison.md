# Legacy vs current benchmark

Generated at 2026-11-04T16:05:45Z.

- Baseline: `d298fa91199482b72e8b00f24fbd80bfc94807fd` (`ex_json_schema` 0.11.5)
- Current: `a7820fad0592f4fcef5f98e8bf452d261e75c89e` with working-tree changes (`ex_json_schema` 1.0.0)
- Runtime: Elixir 1.19.4, OTP 28, 14 schedulers
- Samples: 5; target time per sample: 100 ms
- Sizes: 10, 100, 1000

## Boolean-only validity

| Scenario | N | Legacy µs | Current µs | Time | Legacy reductions | Current reductions | Compute | Legacy allocation | Current allocation | Allocation | Legacy result | Current result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| valid?/items-valid | 10 | 1.74 | 0.25 | 0.15x | 525 | 203 | 0.39x | 4.4 KiB | 1.1 KiB | 0.25x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 10 | 1.77 | 0.24 | 0.14x | 540 | 200 | 0.37x | 4.7 KiB | 1.1 KiB | 0.24x | 0 B | 0 B | n/a |
| valid?/items-true | 10 | 0.14 | 0.10 | 0.70x | 71 | 53 | 0.75x | 488 B | 225 B | 0.46x | 0 B | 0 B | n/a |
| valid?/contains-first | 10 | 0.34 | 0.14 | 0.42x | 165 | 92 | 0.56x | 1.3 KiB | 345 B | 0.27x | 0 B | 0 B | n/a |
| valid?/contains-none | 10 | 1.93 | 0.23 | 0.12x | 669 | 181 | 0.27x | 7.6 KiB | 705 B | 0.09x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 10 | 0.47 | 0.22 | 0.46x | 224 | 118 | 0.53x | 1.8 KiB | 553 B | 0.31x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 10 | 0.34 | 0.32 | 0.93x | 126 | 133 | 1.06x | 1.9 KiB | 1.7 KiB | 0.91x | 0 B | 0 B | n/a |
| valid?/object-properties | 10 | 4.35 | 1.68 | 0.39x | 1019 | 349 | 0.34x | 8.4 KiB | 2.5 KiB | 0.30x | 0 B | 0 B | n/a |
| valid?/object-sparse | 10 | 0.75 | 0.19 | 0.25x | 375 | 93 | 0.25x | 2.3 KiB | 564 B | 0.24x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 10 | 7.60 | 3.96 | 0.52x | 1456 | 573 | 0.39x | 12.5 KiB | 4.4 KiB | 0.35x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 10 | 0.18 | 0.14 | 0.76x | 146 | 72 | 0.49x | 1.0 KiB | 347 B | 0.32x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 10 | 0.12 | 0.09 | 0.78x | 88 | 53 | 0.60x | 489 B | 227 B | 0.46x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 10 | n/a | 1.66 | n/a | n/a | 282 | n/a | n/a | 2.5 KiB | n/a | n/a | 0 B | n/a |
| valid?/items-valid | 100 | 16.9 | 1.22 | 0.07x | 4624 | 1303 | 0.28x | 39.6 KiB | 8.1 KiB | 0.21x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 100 | 16.8 | 1.21 | 0.07x | 4639 | 1300 | 0.28x | 39.8 KiB | 8.1 KiB | 0.20x | 0 B | 0 B | n/a |
| valid?/items-true | 100 | 0.14 | 0.10 | 0.68x | 71 | 53 | 0.75x | 489 B | 226 B | 0.46x | 0 B | 0 B | n/a |
| valid?/contains-first | 100 | 1.02 | 0.14 | 0.14x | 431 | 108 | 0.25x | 4.8 KiB | 346 B | 0.07x | 0 B | 0 B | n/a |
| valid?/contains-none | 100 | 20.3 | 1.10 | 0.05x | 6216 | 1098 | 0.18x | 69.4 KiB | 4.2 KiB | 0.06x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 100 | 1.23 | 0.22 | 0.18x | 434 | 98 | 0.23x | 5.3 KiB | 555 B | 0.10x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 100 | 5.48 | 5.06 | 0.92x | 542 | 647 | 1.19x | 23.3 KiB | 24.9 KiB | 1.07x | 0 B | 0 B | n/a |
| valid?/object-properties | 100 | 35.7 | 10.7 | 0.30x | 9427 | 3198 | 0.34x | 75.1 KiB | 22.0 KiB | 0.29x | 0 B | 0 B | n/a |
| valid?/object-sparse | 100 | 2.03 | 0.22 | 0.11x | 1632 | 93 | 0.06x | 6.7 KiB | 593 B | 0.09x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 100 | 37.8 | 13.1 | 0.35x | 9980 | 3453 | 0.35x | 79.7 KiB | 24.0 KiB | 0.30x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 100 | 0.83 | 0.17 | 0.21x | 393 | 72 | 0.18x | 4.6 KiB | 364 B | 0.08x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 100 | 0.12 | 0.10 | 0.84x | 69 | 53 | 0.77x | 501 B | 249 B | 0.50x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 100 | n/a | 10.6 | n/a | n/a | 3102 | n/a | n/a | 21.9 KiB | n/a | n/a | 0 B | n/a |
| valid?/items-valid | 1000 | 170.0 | 10.8 | 0.06x | 44960 | 12285 | 0.27x | 391.2 KiB | 78.5 KiB | 0.20x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 1000 | 167.8 | 10.9 | 0.07x | 44975 | 12282 | 0.27x | 391.4 KiB | 78.5 KiB | 0.20x | 0 B | 0 B | n/a |
| valid?/items-true | 1000 | 0.14 | 0.09 | 0.67x | 71 | 53 | 0.75x | 503 B | 241 B | 0.48x | 0 B | 0 B | n/a |
| valid?/contains-first | 1000 | 7.33 | 0.14 | 0.02x | 2655 | 74 | 0.03x | 40.0 KiB | 361 B | 0.01x | 0 B | 0 B | n/a |
| valid?/contains-none | 1000 | 341.2 | 9.79 | 0.03x | 57910 | 10280 | 0.18x | 688.2 KiB | 39.4 KiB | 0.06x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 1000 | 7.58 | 0.22 | 0.03x | 2720 | 98 | 0.04x | 40.5 KiB | 569 B | 0.01x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 1000 | 57.0 | 52.4 | 0.92x | 5175 | 6367 | 1.23x | 290.5 KiB | 300.7 KiB | 1.03x | 0 B | 0 B | n/a |
| valid?/object-properties | 1000 | 400.1 | 119.1 | 0.30x | 92932 | 29850 | 0.32x | 736.5 KiB | 217.2 KiB | 0.29x | 0 B | 0 B | n/a |
| valid?/object-sparse | 1000 | 14.9 | 0.24 | 0.02x | 12286 | 93 | 0.01x | 46.6 KiB | 890 B | 0.02x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 1000 | 403.2 | 123.6 | 0.31x | 92972 | 26315 | 0.28x | 742.5 KiB | 216.3 KiB | 0.29x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 1000 | 6.82 | 0.25 | 0.04x | 2913 | 72 | 0.02x | 39.8 KiB | 543 B | 0.01x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 1000 | 0.12 | 0.10 | 0.88x | 1840 | 53 | 0.03x | 629 B | 468 B | 0.74x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 1000 | n/a | 121.7 | n/a | n/a | 25800 | n/a | n/a | 217.1 KiB | n/a | n/a | 0 B | n/a |

## Full public validation

| Scenario | N | Legacy µs | Current µs | Time | Legacy reductions | Current reductions | Compute | Legacy allocation | Current allocation | Allocation | Legacy result | Current result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| validate/items-valid | 10 | 1.73 | 0.26 | 0.15x | 530 | 211 | 0.40x | 4.4 KiB | 1.1 KiB | 0.25x | 0 B | 200 B | n/a |
| validate/items-invalid-last | 10 | 1.77 | 2.55 | 1.44x | 545 | 825 | 1.51x | 4.7 KiB | 6.8 KiB | 1.44x | 328 B | 640 B | 1.95x |
| validate/items-true | 10 | 0.14 | 0.10 | 0.72x | 74 | 60 | 0.81x | 488 B | 241 B | 0.49x | 0 B | 200 B | n/a |
| validate/contains-first | 10 | 0.34 | 0.15 | 0.44x | 168 | 100 | 0.60x | 1.3 KiB | 377 B | 0.29x | 0 B | 200 B | n/a |
| validate/contains-none | 10 | 1.90 | 1.16 | 0.61x | 673 | 494 | 0.73x | 7.7 KiB | 3.2 KiB | 0.42x | 2.6 KiB | 440 B | 0.17x |
| validate/nested-contains-first | 10 | 0.48 | 0.22 | 0.47x | 226 | 128 | 0.57x | 1.8 KiB | 577 B | 0.32x | 0 B | 200 B | n/a |
| validate/unique-scalars | 10 | 0.34 | 0.33 | 0.96x | 129 | 140 | 1.09x | 1.9 KiB | 1.8 KiB | 0.94x | 0 B | 200 B | n/a |
| validate/object-properties | 10 | 4.40 | 1.70 | 0.39x | 1030 | 344 | 0.33x | 8.4 KiB | 2.7 KiB | 0.33x | 0 B | 200 B | n/a |
| validate/object-sparse | 10 | 0.75 | 0.32 | 0.43x | 378 | 210 | 0.56x | 2.3 KiB | 939 B | 0.40x | 0 B | 200 B | n/a |
| validate/object-api-assertions | 10 | 7.67 | 3.95 | 0.51x | 1460 | 566 | 0.39x | 12.5 KiB | 4.7 KiB | 0.38x | 0 B | 200 B | n/a |
| validate/anyOf-first | 10 | 0.19 | 0.15 | 0.80x | 150 | 79 | 0.53x | 1.0 KiB | 355 B | 0.33x | 0 B | 200 B | n/a |
| validate/unused-definitions | 10 | 0.12 | 0.10 | 0.82x | 91 | 60 | 0.66x | 489 B | 243 B | 0.50x | 0 B | 200 B | n/a |
| validate/object-unevaluated | 10 | n/a | 1.71 | n/a | n/a | 290 | n/a | n/a | 2.8 KiB | n/a | n/a | 200 B | n/a |
| validate/items-valid | 100 | 16.6 | 1.25 | 0.08x | 4626 | 1311 | 0.28x | 39.6 KiB | 8.2 KiB | 0.21x | 0 B | 200 B | n/a |
| validate/items-invalid-last | 100 | 16.7 | 5.65 | 0.34x | 4641 | 3538 | 0.76x | 39.9 KiB | 27.9 KiB | 0.70x | 328 B | 640 B | 1.95x |
| validate/items-true | 100 | 0.15 | 0.10 | 0.68x | 74 | 93 | 1.26x | 489 B | 242 B | 0.49x | 0 B | 200 B | n/a |
| validate/contains-first | 100 | 1.04 | 0.15 | 0.15x | 431 | 117 | 0.27x | 4.8 KiB | 378 B | 0.08x | 0 B | 200 B | n/a |
| validate/contains-none | 100 | 20.3 | 3.03 | 0.15x | 6217 | 2312 | 0.37x | 69.5 KiB | 10.3 KiB | 0.15x | 23.0 KiB | 440 B | 0.02x |
| validate/nested-contains-first | 100 | 1.27 | 0.23 | 0.18x | 436 | 108 | 0.25x | 5.3 KiB | 579 B | 0.11x | 0 B | 200 B | n/a |
| validate/unique-scalars | 100 | 5.26 | 5.06 | 0.96x | 554 | 653 | 1.18x | 24.0 KiB | 24.8 KiB | 1.03x | 0 B | 200 B | n/a |
| validate/object-properties | 100 | 35.7 | 10.7 | 0.30x | 9430 | 3108 | 0.33x | 75.1 KiB | 24.3 KiB | 0.32x | 0 B | 200 B | n/a |
| validate/object-sparse | 100 | 2.05 | 1.62 | 0.79x | 1635 | 1094 | 0.67x | 6.7 KiB | 4.2 KiB | 0.63x | 0 B | 200 B | n/a |
| validate/object-api-assertions | 100 | 38.3 | 13.0 | 0.34x | 9983 | 3342 | 0.33x | 80.0 KiB | 26.5 KiB | 0.33x | 0 B | 200 B | n/a |
| validate/anyOf-first | 100 | 0.83 | 0.18 | 0.22x | 396 | 79 | 0.20x | 4.6 KiB | 372 B | 0.08x | 0 B | 200 B | n/a |
| validate/unused-definitions | 100 | 0.12 | 0.11 | 0.89x | 72 | 60 | 0.83x | 502 B | 265 B | 0.53x | 0 B | 200 B | n/a |
| validate/object-unevaluated | 100 | n/a | 10.7 | n/a | n/a | 3114 | n/a | n/a | 24.0 KiB | n/a | n/a | 200 B | n/a |
| validate/items-valid | 1000 | 169.1 | 10.9 | 0.06x | 44963 | 12293 | 0.27x | 391.2 KiB | 78.5 KiB | 0.20x | 0 B | 200 B | n/a |
| validate/items-invalid-last | 1000 | 169.5 | 38.2 | 0.23x | 44978 | 30223 | 0.67x | 391.5 KiB | 238.9 KiB | 0.61x | 328 B | 640 B | 1.95x |
| validate/items-true | 1000 | 0.15 | 0.10 | 0.70x | 74 | 60 | 0.81x | 504 B | 257 B | 0.51x | 0 B | 200 B | n/a |
| validate/contains-first | 1000 | 7.72 | 0.15 | 0.02x | 2658 | 83 | 0.03x | 40.0 KiB | 393 B | 0.01x | 0 B | 200 B | n/a |
| validate/contains-none | 1000 | 341.8 | 20.6 | 0.06x | 57915 | 20495 | 0.35x | 688.2 KiB | 80.6 KiB | 0.12x | 226.9 KiB | 440 B | 0.00x |
| validate/nested-contains-first | 1000 | 7.55 | 0.23 | 0.03x | 2722 | 108 | 0.04x | 40.5 KiB | 592 B | 0.01x | 0 B | 200 B | n/a |
| validate/unique-scalars | 1000 | 54.5 | 52.5 | 0.96x | 5220 | 6208 | 1.19x | 289.6 KiB | 301.0 KiB | 1.04x | 0 B | 200 B | n/a |
| validate/object-properties | 1000 | 396.8 | 118.3 | 0.30x | 92938 | 27996 | 0.30x | 736.8 KiB | 240.4 KiB | 0.33x | 0 B | 200 B | n/a |
| validate/object-sparse | 1000 | 15.5 | 14.3 | 0.92x | 12290 | 10096 | 0.82x | 45.3 KiB | 29.6 KiB | 0.65x | 0 B | 200 B | n/a |
| validate/object-api-assertions | 1000 | 403.1 | 123.3 | 0.31x | 92975 | 28395 | 0.31x | 744.0 KiB | 240.6 KiB | 0.32x | 0 B | 200 B | n/a |
| validate/anyOf-first | 1000 | 6.95 | 0.17 | 0.02x | 2916 | 79 | 0.03x | 39.8 KiB | 551 B | 0.01x | 0 B | 200 B | n/a |
| validate/unused-definitions | 1000 | 0.12 | 0.11 | 0.94x | 1843 | 60 | 0.03x | 629 B | 484 B | 0.77x | 0 B | 200 B | n/a |
| validate/object-unevaluated | 1000 | n/a | 118.4 | n/a | n/a | 28018 | n/a | n/a | 240.4 KiB | n/a | n/a | 200 B | n/a |

## Compilation

| Scenario | N | Legacy µs | Current µs | Time | Legacy reductions | Current reductions | Compute | Legacy allocation | Current allocation | Allocation | Legacy result | Current result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| compile/object-properties | 10 | 810.7 | 20.0 | 0.02x | 53542 | 4264 | 0.08x | 574.1 KiB | 47.1 KiB | 0.08x | 1.4 KiB | 4.3 KiB | 3.11x |
| compile/object-properties | 100 | 1037.6 | 163.8 | 0.16x | 157334 | 32322 | 0.21x | 1.2 MiB | 379.1 KiB | 0.32x | 11.1 KiB | 25.1 KiB | 2.26x |
| compile/object-properties | 1000 | 3294.8 | 1854.1 | 0.56x | 1199266 | 306755 | 0.26x | 7.2 MiB | 3.7 MiB | 0.51x | 107.4 KiB | 230.0 KiB | 2.14x |

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
