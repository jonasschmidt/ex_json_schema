# ex_json_schema vs JSV benchmark

Generated at 2026-11-04T16:35:46Z.

- ex_json_schema: 1.0.0
- JSV: 0.26.2
- Runtime: Elixir 1.19.4, OTP 28, 14 schedulers
- Samples: 5; target time per sample: 100 ms
- Sizes: 10, 100, 1000
- Dialect: JSON Schema Draft 2020-12

## Boolean-only validity

| Scenario | N | ex_json_schema µs | JSV µs | Time | ex_json_schema reductions | JSV reductions | Compute | ex_json_schema allocation | JSV allocation | Allocation | ex_json_schema result | JSV result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| valid?/items-valid | 10 | 0.26 | 1.16 | 0.22x | 193 | 505 | 0.38x | 1.1 KiB | 5.7 KiB | 0.19x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 10 | 0.25 | 1.29 | 0.19x | 190 | 537 | 0.35x | 1.1 KiB | 6.4 KiB | 0.17x | 0 B | 0 B | n/a |
| valid?/items-true | 10 | 0.08 | 1.02 | 0.08x | 43 | 358 | 0.12x | 201 B | 3.9 KiB | 0.05x | 0 B | 0 B | n/a |
| valid?/contains-first | 10 | 0.14 | 1.44 | 0.10x | 64 | 503 | 0.13x | 321 B | 8.5 KiB | 0.04x | 0 B | 0 B | n/a |
| valid?/contains-none | 10 | 0.23 | 1.46 | 0.16x | 170 | 514 | 0.33x | 681 B | 9.2 KiB | 0.07x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 10 | 0.21 | 1.55 | 0.13x | 109 | 580 | 0.19x | 521 B | 9.1 KiB | 0.06x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 10 | 0.32 | 0.31 | 1.02x | 129 | 145 | 0.89x | 1.7 KiB | 2.3 KiB | 0.73x | 0 B | 0 B | n/a |
| valid?/object-properties | 10 | 1.63 | 2.43 | 0.67x | 345 | 631 | 0.55x | 2.5 KiB | 6.8 KiB | 0.37x | 0 B | 0 B | n/a |
| valid?/object-sparse | 10 | 0.18 | 0.41 | 0.44x | 89 | 238 | 0.37x | 564 B | 1.7 KiB | 0.32x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 10 | 4.24 | 3.77 | 1.12x | 570 | 865 | 0.66x | 4.4 KiB | 9.6 KiB | 0.46x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 10 | 1.68 | 3.86 | 0.43x | 278 | 786 | 0.35x | 2.5 KiB | 10.5 KiB | 0.24x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 10 | 0.13 | 1.05 | 0.12x | 62 | 409 | 0.15x | 323 B | 7.5 KiB | 0.04x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 10 | 0.08 | 0.08 | 1.00x | 43 | 64 | 0.67x | 204 B | 467 B | 0.44x | 0 B | 0 B | n/a |
| valid?/items-valid | 100 | 1.21 | 11.4 | 0.11x | 1293 | 4494 | 0.29x | 8.1 KiB | 52.1 KiB | 0.16x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 100 | 1.20 | 10.9 | 0.11x | 1290 | 4516 | 0.29x | 8.1 KiB | 52.7 KiB | 0.15x | 0 B | 0 B | n/a |
| valid?/items-true | 100 | 0.08 | 7.45 | 0.01x | 43 | 3077 | 0.01x | 200 B | 33.4 KiB | 0.01x | 0 B | 0 B | n/a |
| valid?/contains-first | 100 | 0.13 | 14.0 | 0.01x | 98 | 4422 | 0.02x | 322 B | 83.0 KiB | 0.00x | 0 B | 0 B | n/a |
| valid?/contains-none | 100 | 1.12 | 14.0 | 0.08x | 1088 | 4468 | 0.24x | 4.2 KiB | 83.6 KiB | 0.05x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 100 | 0.21 | 14.2 | 0.01x | 88 | 4498 | 0.02x | 531 B | 83.6 KiB | 0.01x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 100 | 5.00 | 5.60 | 0.89x | 643 | 1107 | 0.58x | 24.9 KiB | 30.4 KiB | 0.82x | 0 B | 0 B | n/a |
| valid?/object-properties | 100 | 11.3 | 19.1 | 0.59x | 3194 | 5895 | 0.54x | 22.0 KiB | 62.4 KiB | 0.35x | 0 B | 0 B | n/a |
| valid?/object-sparse | 100 | 0.22 | 1.60 | 0.14x | 89 | 1319 | 0.07x | 594 B | 6.5 KiB | 0.09x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 100 | 13.4 | 21.6 | 0.62x | 3450 | 6260 | 0.55x | 23.9 KiB | 66.2 KiB | 0.36x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 100 | 10.7 | 64.4 | 0.17x | 3100 | 8003 | 0.39x | 21.9 KiB | 105.1 KiB | 0.21x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 100 | 0.15 | 9.97 | 0.02x | 62 | 3575 | 0.02x | 340 B | 71.4 KiB | 0.00x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 100 | 0.08 | 0.08 | 1.00x | 43 | 43 | 1.00x | 239 B | 488 B | 0.49x | 0 B | 0 B | n/a |
| valid?/items-valid | 1000 | 12.1 | 108.6 | 0.11x | 12275 | 43627 | 0.28x | 78.4 KiB | 516.2 KiB | 0.15x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 1000 | 11.5 | 112.3 | 0.10x | 12272 | 43637 | 0.28x | 78.4 KiB | 516.6 KiB | 0.15x | 0 B | 0 B | n/a |
| valid?/items-true | 1000 | 0.08 | 81.6 | 0.00x | 43 | 29522 | 0.00x | 217 B | 328.7 KiB | 0.00x | 0 B | 0 B | n/a |
| valid?/contains-first | 1000 | 0.14 | 147.7 | 0.00x | 64 | 42845 | 0.00x | 336 B | 828.3 KiB | 0.00x | 0 B | 0 B | n/a |
| valid?/contains-none | 1000 | 10.2 | 147.3 | 0.07x | 10271 | 42867 | 0.24x | 39.4 KiB | 828.8 KiB | 0.05x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 1000 | 0.20 | 148.3 | 0.00x | 88 | 42896 | 0.00x | 545 B | 828.9 KiB | 0.00x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 1000 | 50.9 | 63.5 | 0.80x | 6363 | 10973 | 0.58x | 301.0 KiB | 351.8 KiB | 0.86x | 0 B | 0 B | n/a |
| valid?/object-properties | 1000 | 117.6 | 192.7 | 0.61x | 29851 | 56584 | 0.53x | 217.0 KiB | 615.1 KiB | 0.35x | 0 B | 0 B | n/a |
| valid?/object-sparse | 1000 | 0.23 | 13.5 | 0.02x | 89 | 12121 | 0.01x | 890 B | 50.9 KiB | 0.02x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 1000 | 122.5 | 207.7 | 0.59x | 26316 | 57113 | 0.46x | 216.7 KiB | 635.1 KiB | 0.34x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 1000 | 118.9 | 2908.1 | 0.04x | 25806 | 104279 | 0.25x | 217.4 KiB | 1.0 MiB | 0.21x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 1000 | 0.15 | 147.0 | 0.00x | 62 | 29991 | 0.00x | 519 B | 711.8 KiB | 0.00x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 1000 | 0.08 | 0.07 | 1.05x | 43 | 43 | 1.00x | 585 B | 629 B | 0.93x | 0 B | 0 B | n/a |

## Full public validation

| Scenario | N | ex_json_schema µs | JSV µs | Time | ex_json_schema reductions | JSV reductions | Compute | ex_json_schema allocation | JSV allocation | Allocation | ex_json_schema result | JSV result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| validate/basic/items-valid | 10 | 0.25 | 1.19 | 0.21x | 200 | 506 | 0.40x | 1.1 KiB | 5.7 KiB | 0.19x | 200 B | 184 B | 1.09x |
| validate/basic/items-invalid-last | 10 | 2.46 | 1.29 | 1.91x | 844 | 536 | 1.57x | 6.9 KiB | 6.4 KiB | 1.08x | 640 B | 728 B | 0.88x |
| validate/basic/items-true | 10 | 0.09 | 0.81 | 0.11x | 50 | 357 | 0.14x | 217 B | 3.9 KiB | 0.05x | 200 B | 184 B | 1.09x |
| validate/basic/contains-first | 10 | 0.14 | 1.42 | 0.10x | 88 | 502 | 0.18x | 337 B | 8.5 KiB | 0.04x | 200 B | 184 B | 1.09x |
| validate/basic/contains-none | 10 | 1.29 | 1.49 | 0.87x | 500 | 511 | 0.98x | 3.2 KiB | 9.2 KiB | 0.35x | 440 B | 536 B | 0.82x |
| validate/basic/nested-contains-first | 10 | 0.22 | 1.61 | 0.14x | 116 | 580 | 0.20x | 542 B | 9.1 KiB | 0.06x | 200 B | 200 B | 1.00x |
| validate/basic/unique-scalars | 10 | 0.31 | 0.31 | 1.03x | 136 | 144 | 0.94x | 1.7 KiB | 2.4 KiB | 0.73x | 200 B | 184 B | 1.09x |
| validate/basic/object-properties | 10 | 1.68 | 2.41 | 0.70x | 351 | 630 | 0.56x | 2.5 KiB | 6.8 KiB | 0.37x | 200 B | 536 B | 0.37x |
| validate/basic/object-sparse | 10 | 0.19 | 0.39 | 0.50x | 149 | 237 | 0.63x | 580 B | 1.7 KiB | 0.33x | 200 B | 104 B | 1.92x |
| validate/basic/object-api-assertions | 10 | 4.11 | 3.85 | 1.07x | 577 | 864 | 0.67x | 4.4 KiB | 9.6 KiB | 0.46x | 200 B | 704 B | 0.28x |
| validate/basic/object-unevaluated | 10 | 1.65 | 3.85 | 0.43x | 285 | 786 | 0.36x | 2.5 KiB | 10.5 KiB | 0.24x | 200 B | 536 B | 0.37x |
| validate/basic/anyOf-first | 10 | 0.14 | 1.04 | 0.13x | 69 | 408 | 0.17x | 339 B | 7.5 KiB | 0.04x | 200 B | 24 B | 8.33x |
| validate/basic/unused-definitions | 10 | 0.16 | 0.08 | 1.92x | 50 | 63 | 0.79x | 220 B | 467 B | 0.47x | 200 B | 24 B | 8.33x |
| validate/basic/items-valid | 100 | 1.22 | 10.9 | 0.11x | 1300 | 4493 | 0.29x | 8.1 KiB | 52.0 KiB | 0.16x | 200 B | 1.6 KiB | 0.12x |
| validate/basic/items-invalid-last | 100 | 5.96 | 11.0 | 0.54x | 3557 | 4517 | 0.79x | 28.0 KiB | 52.7 KiB | 0.53x | 640 B | 2.1 KiB | 0.30x |
| validate/basic/items-true | 100 | 0.09 | 7.31 | 0.01x | 83 | 3078 | 0.03x | 218 B | 33.4 KiB | 0.01x | 200 B | 1.6 KiB | 0.12x |
| validate/basic/contains-first | 100 | 0.14 | 13.9 | 0.01x | 105 | 4430 | 0.02x | 338 B | 83.0 KiB | 0.00x | 200 B | 1.6 KiB | 0.12x |
| validate/basic/contains-none | 100 | 3.35 | 14.1 | 0.24x | 2318 | 4469 | 0.52x | 10.3 KiB | 83.6 KiB | 0.12x | 440 B | 1.9 KiB | 0.22x |
| validate/basic/nested-contains-first | 100 | 0.21 | 14.1 | 0.02x | 95 | 4497 | 0.02x | 545 B | 83.6 KiB | 0.01x | 200 B | 1.6 KiB | 0.12x |
| validate/basic/unique-scalars | 100 | 4.73 | 5.75 | 0.82x | 661 | 1105 | 0.60x | 24.9 KiB | 30.4 KiB | 0.82x | 200 B | 1.6 KiB | 0.12x |
| validate/basic/object-properties | 100 | 10.9 | 21.2 | 0.51x | 3202 | 5894 | 0.54x | 22.0 KiB | 62.4 KiB | 0.35x | 200 B | 6.0 KiB | 0.03x |
| validate/basic/object-sparse | 100 | 0.23 | 1.62 | 0.14x | 96 | 1318 | 0.07x | 610 B | 6.5 KiB | 0.09x | 200 B | 104 B | 1.92x |
| validate/basic/object-api-assertions | 100 | 13.3 | 21.5 | 0.62x | 3461 | 6259 | 0.55x | 23.0 KiB | 66.3 KiB | 0.35x | 200 B | 6.2 KiB | 0.03x |
| validate/basic/object-unevaluated | 100 | 10.9 | 65.7 | 0.17x | 3106 | 8002 | 0.39x | 22.0 KiB | 105.4 KiB | 0.21x | 200 B | 6.0 KiB | 0.03x |
| validate/basic/anyOf-first | 100 | 0.17 | 10.2 | 0.02x | 69 | 3574 | 0.02x | 356 B | 71.2 KiB | 0.00x | 200 B | 24 B | 8.33x |
| validate/basic/unused-definitions | 100 | 0.10 | 0.08 | 1.19x | 50 | 42 | 1.19x | 255 B | 488 B | 0.52x | 200 B | 24 B | 8.33x |
| validate/basic/items-valid | 1000 | 11.6 | 111.1 | 0.10x | 12282 | 43626 | 0.28x | 78.5 KiB | 515.8 KiB | 0.15x | 200 B | 15.6 KiB | 0.01x |
| validate/basic/items-invalid-last | 1000 | 39.5 | 114.4 | 0.34x | 30242 | 43636 | 0.69x | 239.0 KiB | 516.4 KiB | 0.46x | 640 B | 16.2 KiB | 0.04x |
| validate/basic/items-true | 1000 | 0.09 | 79.7 | 0.00x | 50 | 29521 | 0.00x | 233 B | 328.7 KiB | 0.00x | 200 B | 15.6 KiB | 0.01x |
| validate/basic/contains-first | 1000 | 0.14 | 146.1 | 0.00x | 71 | 42844 | 0.00x | 353 B | 828.1 KiB | 0.00x | 200 B | 15.6 KiB | 0.01x |
| validate/basic/contains-none | 1000 | 21.0 | 146.7 | 0.14x | 20501 | 42866 | 0.48x | 80.6 KiB | 828.8 KiB | 0.10x | 440 B | 16.0 KiB | 0.03x |
| validate/basic/nested-contains-first | 1000 | 0.22 | 145.1 | 0.00x | 95 | 42926 | 0.00x | 561 B | 829.0 KiB | 0.00x | 200 B | 15.7 KiB | 0.01x |
| validate/basic/unique-scalars | 1000 | 51.1 | 66.9 | 0.76x | 6204 | 10972 | 0.57x | 301.2 KiB | 351.7 KiB | 0.86x | 200 B | 15.6 KiB | 0.01x |
| validate/basic/object-properties | 1000 | 116.8 | 194.3 | 0.60x | 29869 | 56583 | 0.53x | 217.1 KiB | 614.8 KiB | 0.35x | 200 B | 60.1 KiB | 0.00x |
| validate/basic/object-sparse | 1000 | 0.24 | 13.2 | 0.02x | 96 | 12120 | 0.01x | 906 B | 51.0 KiB | 0.02x | 200 B | 104 B | 1.92x |
| validate/basic/object-api-assertions | 1000 | 121.2 | 211.4 | 0.57x | 26338 | 57112 | 0.46x | 217.8 KiB | 635.1 KiB | 0.34x | 200 B | 60.4 KiB | 0.00x |
| validate/basic/object-unevaluated | 1000 | 118.1 | 2879.4 | 0.04x | 25807 | 104272 | 0.25x | 217.0 KiB | 1.0 MiB | 0.21x | 200 B | 60.1 KiB | 0.00x |
| validate/basic/anyOf-first | 1000 | 0.16 | 145.7 | 0.00x | 69 | 29988 | 0.00x | 534 B | 711.5 KiB | 0.00x | 200 B | 24 B | 8.33x |
| validate/basic/unused-definitions | 1000 | 0.09 | 0.07 | 1.22x | 50 | 42 | 1.19x | 601 B | 629 B | 0.96x | 200 B | 24 B | 8.33x |

## Compilation

| Scenario | N | ex_json_schema µs | JSV µs | Time | ex_json_schema reductions | JSV reductions | Compute | ex_json_schema allocation | JSV allocation | Allocation | ex_json_schema result | JSV result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| compile/object-properties | 10 | 38.5 | 13.0 | 2.96x | 5040 | 4909 | 1.03x | 71.1 KiB | 48.4 KiB | 1.47x | 4.9 KiB | 3.6 KiB | 1.34x |
| compile/object-properties | 100 | 195.6 | 77.9 | 2.51x | 33756 | 40951 | 0.82x | 407.9 KiB | 379.1 KiB | 1.08x | 25.6 KiB | 31.4 KiB | 0.81x |
| compile/object-properties | 1000 | 2002.1 | 1065.9 | 1.88x | 318677 | 417761 | 0.76x | 3.8 MiB | 3.6 MiB | 1.04x | 230.6 KiB | 308.5 KiB | 0.75x |

## Compiled validator footprint

| Scenario | N | ex_json_schema retained | JSV retained | Retained | ex_json_schema flat | JSV flat | Flat |
| --- | --- | --- | --- | --- | --- | --- | --- |
| items-valid | 10 | 3.0 KiB | 976 B | 3.19x | 3.6 KiB | 1.0 KiB | 3.53x |
| items-invalid-last | 10 | 3.0 KiB | 976 B | 3.19x | 3.6 KiB | 1.0 KiB | 3.53x |
| items-true | 10 | 2.8 KiB | 824 B | 3.46x | 3.3 KiB | 840 B | 3.97x |
| contains-first | 10 | 3.0 KiB | 960 B | 3.23x | 3.5 KiB | 1016 B | 3.55x |
| contains-none | 10 | 3.0 KiB | 960 B | 3.23x | 3.5 KiB | 1016 B | 3.55x |
| nested-contains-first | 10 | 3.5 KiB | 1.3 KiB | 2.66x | 4.2 KiB | 1.4 KiB | 2.89x |
| unique-scalars | 10 | 2.6 KiB | 672 B | 4.04x | 3.1 KiB | 672 B | 4.65x |
| object-properties | 10 | 4.9 KiB | 3.6 KiB | 1.34x | 7.8 KiB | 5.2 KiB | 1.48x |
| object-sparse | 10 | 4.9 KiB | 3.6 KiB | 1.34x | 7.8 KiB | 5.2 KiB | 1.48x |
| object-api-assertions | 10 | 7.4 KiB | 5.8 KiB | 1.27x | 11.4 KiB | 7.9 KiB | 1.44x |
| object-unevaluated | 10 | 5.2 KiB | 3.9 KiB | 1.33x | 8.2 KiB | 5.5 KiB | 1.49x |
| anyOf-first | 10 | 4.6 KiB | 3.1 KiB | 1.48x | 6.1 KiB | 3.8 KiB | 1.59x |
| unused-definitions | 10 | 5.6 KiB | 2.0 KiB | 2.86x | 8.3 KiB | 2.5 KiB | 3.29x |
| items-valid | 100 | 3.0 KiB | 976 B | 3.19x | 3.6 KiB | 1.0 KiB | 3.53x |
| items-invalid-last | 100 | 3.0 KiB | 976 B | 3.19x | 3.6 KiB | 1.0 KiB | 3.53x |
| items-true | 100 | 2.8 KiB | 824 B | 3.46x | 3.3 KiB | 840 B | 3.97x |
| contains-first | 100 | 3.0 KiB | 960 B | 3.23x | 3.5 KiB | 1016 B | 3.55x |
| contains-none | 100 | 3.0 KiB | 960 B | 3.23x | 3.5 KiB | 1016 B | 3.55x |
| nested-contains-first | 100 | 3.5 KiB | 1.3 KiB | 2.66x | 4.2 KiB | 1.4 KiB | 2.89x |
| unique-scalars | 100 | 2.6 KiB | 672 B | 4.04x | 3.1 KiB | 672 B | 4.65x |
| object-properties | 100 | 25.6 KiB | 31.4 KiB | 0.81x | 51.0 KiB | 47.8 KiB | 1.07x |
| object-sparse | 100 | 25.6 KiB | 31.4 KiB | 0.81x | 51.0 KiB | 47.8 KiB | 1.07x |
| object-api-assertions | 100 | 28.2 KiB | 33.6 KiB | 0.84x | 54.7 KiB | 50.5 KiB | 1.08x |
| object-unevaluated | 100 | 25.9 KiB | 31.7 KiB | 0.82x | 51.4 KiB | 48.0 KiB | 1.07x |
| anyOf-first | 100 | 19.9 KiB | 25.6 KiB | 0.78x | 31.9 KiB | 33.4 KiB | 0.96x |
| unused-definitions | 100 | 34.2 KiB | 15.9 KiB | 2.15x | 58.0 KiB | 22.1 KiB | 2.62x |
| items-valid | 1000 | 3.0 KiB | 976 B | 3.19x | 3.6 KiB | 1.0 KiB | 3.53x |
| items-invalid-last | 1000 | 3.0 KiB | 976 B | 3.19x | 3.6 KiB | 1.0 KiB | 3.53x |
| items-true | 1000 | 2.8 KiB | 824 B | 3.46x | 3.3 KiB | 840 B | 3.97x |
| contains-first | 1000 | 3.0 KiB | 960 B | 3.23x | 3.5 KiB | 1016 B | 3.55x |
| contains-none | 1000 | 3.0 KiB | 960 B | 3.23x | 3.5 KiB | 1016 B | 3.55x |
| nested-contains-first | 1000 | 3.5 KiB | 1.3 KiB | 2.66x | 4.2 KiB | 1.4 KiB | 2.89x |
| unique-scalars | 1000 | 2.6 KiB | 672 B | 4.04x | 3.1 KiB | 672 B | 4.65x |
| object-properties | 1000 | 230.6 KiB | 308.5 KiB | 0.75x | 481.0 KiB | 472.5 KiB | 1.02x |
| object-sparse | 1000 | 230.6 KiB | 308.5 KiB | 0.75x | 481.0 KiB | 472.5 KiB | 1.02x |
| object-api-assertions | 1000 | 233.2 KiB | 310.8 KiB | 0.75x | 484.7 KiB | 475.3 KiB | 1.02x |
| object-unevaluated | 1000 | 230.8 KiB | 308.7 KiB | 0.75x | 481.4 KiB | 472.7 KiB | 1.02x |
| anyOf-first | 1000 | 172.8 KiB | 250.6 KiB | 0.69x | 290.3 KiB | 328.7 KiB | 0.88x |
| unused-definitions | 1000 | 315.5 KiB | 154.5 KiB | 2.04x | 550.2 KiB | 216.9 KiB | 2.54x |

Ratios are ex_json_schema divided by JSV; values below `1.00x` favor
ex_json_schema. Validation schemas are compiled outside measured operations.
JSV 0.26.2 does not expose `valid?`; the boolean-only rows classify the
result of `JSV.validate(cast: false)`. They compare the fastest public way
each library can answer validity, not equivalent internal work.

Full-validation rows compare
`ExJsonSchema.validate(output: :basic)` with `JSV.validate(cast: false)`.
Both execute their public diagnostic validation paths, but their contracts
differ: ex_json_schema returns standardized JSON Schema output, while JSV
returns validated data or a `JSV.ValidationError`. Result sizes in these
rows are therefore not directly comparable. Both validators report a
failing `contains` keyword as an aggregate match-count error.

Compilation compares `ExJsonSchema.compile!(validate_schema: false)` with
`JSV.build!`.

Time is median wall time per operation. Reductions measure one operation in
an isolated process. Allocation is estimated from words reclaimed by BEAM
garbage collections over repeated calls. Result and retained-schema sizes
count shared subterms once; flat schema size counts shared subterms each
time they are referenced and approximates the cost of copying a schema
without preserving sharing.
