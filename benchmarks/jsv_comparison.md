# ex_json_schema vs JSV benchmark

Generated at 2026-11-03T16:04:06Z.

- ex_json_schema: 1.0.0
- JSV: 0.26.2
- Runtime: Elixir 1.19.4, OTP 28, 14 schedulers
- Samples: 5; target time per sample: 100 ms
- Sizes: 10, 100, 1000
- Dialect: JSON Schema Draft 2020-12

## Boolean-only validity

| Scenario | N | ex_json_schema µs | JSV µs | Time | ex_json_schema reductions | JSV reductions | Compute | ex_json_schema allocation | JSV allocation | Allocation | ex_json_schema result | JSV result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| valid?/items-valid | 10 | 0.20 | 1.13 | 0.18x | 187 | 505 | 0.37x | 993 B | 5.7 KiB | 0.17x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 10 | 0.20 | 1.35 | 0.15x | 184 | 537 | 0.34x | 993 B | 6.4 KiB | 0.15x | 0 B | 0 B | n/a |
| valid?/items-true | 10 | 0.06 | 0.82 | 0.08x | 39 | 358 | 0.11x | 129 B | 3.9 KiB | 0.03x | 0 B | 0 B | n/a |
| valid?/contains-first | 10 | 0.10 | 1.37 | 0.07x | 76 | 503 | 0.15x | 201 B | 8.5 KiB | 0.02x | 0 B | 0 B | n/a |
| valid?/contains-none | 10 | 0.19 | 1.45 | 0.13x | 165 | 514 | 0.32x | 561 B | 9.2 KiB | 0.06x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 10 | 0.15 | 1.49 | 0.10x | 78 | 580 | 0.13x | 362 B | 9.1 KiB | 0.04x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 10 | 0.30 | 0.33 | 0.90x | 125 | 145 | 0.86x | 1.6 KiB | 2.3 KiB | 0.71x | 0 B | 0 B | n/a |
| valid?/object-properties | 10 | 1.48 | 2.45 | 0.60x | 253 | 631 | 0.40x | 2.0 KiB | 6.8 KiB | 0.29x | 0 B | 0 B | n/a |
| valid?/object-sparse | 10 | 0.15 | 0.42 | 0.36x | 82 | 238 | 0.34x | 448 B | 1.7 KiB | 0.25x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 10 | 4.35 | 3.94 | 1.10x | 627 | 865 | 0.72x | 4.1 KiB | 9.6 KiB | 0.43x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 10 | 1.45 | 3.85 | 0.38x | 244 | 786 | 0.31x | 2.0 KiB | 10.5 KiB | 0.19x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 10 | 6.47 | 1.07 | 6.06x | 558 | 409 | 1.36x | 11.2 KiB | 7.5 KiB | 1.50x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 10 | 0.06 | 0.10 | 0.62x | 39 | 64 | 0.61x | 141 B | 467 B | 0.30x | 0 B | 0 B | n/a |
| valid?/items-valid | 100 | 1.20 | 10.5 | 0.11x | 1288 | 4494 | 0.29x | 8.0 KiB | 52.1 KiB | 0.15x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 100 | 1.24 | 11.9 | 0.10x | 1285 | 4516 | 0.28x | 8.0 KiB | 52.7 KiB | 0.15x | 0 B | 0 B | n/a |
| valid?/items-true | 100 | 0.06 | 7.04 | 0.01x | 74 | 3077 | 0.02x | 130 B | 33.4 KiB | 0.00x | 0 B | 0 B | n/a |
| valid?/contains-first | 100 | 0.10 | 13.3 | 0.01x | 57 | 4422 | 0.01x | 203 B | 83.0 KiB | 0.00x | 0 B | 0 B | n/a |
| valid?/contains-none | 100 | 1.06 | 14.4 | 0.07x | 1083 | 4468 | 0.24x | 4.1 KiB | 83.6 KiB | 0.05x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 100 | 0.15 | 13.8 | 0.01x | 78 | 4498 | 0.02x | 363 B | 83.6 KiB | 0.00x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 100 | 4.76 | 5.53 | 0.86x | 652 | 1107 | 0.59x | 24.7 KiB | 30.4 KiB | 0.81x | 0 B | 0 B | n/a |
| valid?/object-properties | 100 | 9.04 | 18.5 | 0.49x | 2365 | 5895 | 0.40x | 17.2 KiB | 62.4 KiB | 0.28x | 0 B | 0 B | n/a |
| valid?/object-sparse | 100 | 0.19 | 1.66 | 0.11x | 82 | 1319 | 0.06x | 526 B | 6.5 KiB | 0.08x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 100 | 13.3 | 22.9 | 0.58x | 2596 | 6260 | 0.41x | 19.4 KiB | 66.2 KiB | 0.29x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 100 | 9.10 | 63.2 | 0.14x | 2266 | 8003 | 0.28x | 17.2 KiB | 105.1 KiB | 0.16x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 100 | 6.52 | 9.89 | 0.66x | 1095 | 3575 | 0.31x | 11.0 KiB | 71.4 KiB | 0.15x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 100 | 0.07 | 0.08 | 0.82x | 39 | 43 | 0.91x | 273 B | 488 B | 0.56x | 0 B | 0 B | n/a |
| valid?/items-valid | 1000 | 10.8 | 114.2 | 0.09x | 12270 | 43627 | 0.28x | 78.3 KiB | 516.2 KiB | 0.15x | 0 B | 0 B | n/a |
| valid?/items-invalid-last | 1000 | 10.9 | 109.9 | 0.10x | 12267 | 43637 | 0.28x | 78.3 KiB | 516.6 KiB | 0.15x | 0 B | 0 B | n/a |
| valid?/items-true | 1000 | 0.07 | 76.4 | 0.00x | 39 | 29522 | 0.00x | 145 B | 328.7 KiB | 0.00x | 0 B | 0 B | n/a |
| valid?/contains-first | 1000 | 0.10 | 142.8 | 0.00x | 57 | 42845 | 0.00x | 217 B | 828.3 KiB | 0.00x | 0 B | 0 B | n/a |
| valid?/contains-none | 1000 | 9.87 | 139.5 | 0.07x | 10264 | 42867 | 0.24x | 39.2 KiB | 828.8 KiB | 0.05x | 0 B | 0 B | n/a |
| valid?/nested-contains-first | 1000 | 0.15 | 146.6 | 0.00x | 78 | 42896 | 0.00x | 377 B | 829.0 KiB | 0.00x | 0 B | 0 B | n/a |
| valid?/unique-scalars | 1000 | 57.0 | 71.1 | 0.80x | 6309 | 10973 | 0.57x | 300.4 KiB | 351.8 KiB | 0.85x | 0 B | 0 B | n/a |
| valid?/object-properties | 1000 | 96.1 | 198.8 | 0.48x | 24705 | 56584 | 0.44x | 168.1 KiB | 616.0 KiB | 0.27x | 0 B | 0 B | n/a |
| valid?/object-sparse | 1000 | 0.24 | 13.6 | 0.02x | 82 | 12121 | 0.01x | 1.3 KiB | 50.9 KiB | 0.02x | 0 B | 0 B | n/a |
| valid?/object-api-assertions | 1000 | 100.8 | 210.5 | 0.48x | 25303 | 57113 | 0.44x | 171.8 KiB | 635.0 KiB | 0.27x | 0 B | 0 B | n/a |
| valid?/object-unevaluated | 1000 | 100.2 | 2862.8 | 0.03x | 23901 | 104279 | 0.23x | 164.9 KiB | 1.0 MiB | 0.16x | 0 B | 0 B | n/a |
| valid?/anyOf-first | 1000 | 7.47 | 142.9 | 0.05x | 440 | 29991 | 0.01x | 11.6 KiB | 711.5 KiB | 0.02x | 0 B | 0 B | n/a |
| valid?/unused-definitions | 1000 | 0.06 | 0.08 | 0.81x | 39 | 43 | 0.91x | 1.6 KiB | 629 B | 2.52x | 0 B | 0 B | n/a |

## Full public validation

| Scenario | N | ex_json_schema µs | JSV µs | Time | ex_json_schema reductions | JSV reductions | Compute | ex_json_schema allocation | JSV allocation | Allocation | ex_json_schema result | JSV result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| validate/basic/items-valid | 10 | 0.79 | 1.16 | 0.68x | 386 | 506 | 0.76x | 2.8 KiB | 5.7 KiB | 0.49x | 184 B | 184 B | 1.00x |
| validate/basic/items-invalid-last | 10 | 2.30 | 1.23 | 1.86x | 686 | 536 | 1.28x | 5.5 KiB | 6.4 KiB | 0.86x | 640 B | 728 B | 0.88x |
| validate/basic/items-true | 10 | 0.52 | 0.77 | 0.67x | 191 | 357 | 0.54x | 1.3 KiB | 3.9 KiB | 0.34x | 184 B | 184 B | 1.00x |
| validate/basic/contains-first | 10 | 0.64 | 1.41 | 0.46x | 233 | 502 | 0.46x | 1.6 KiB | 8.5 KiB | 0.19x | 184 B | 184 B | 1.00x |
| validate/basic/contains-none | 10 | 1.03 | 1.42 | 0.73x | 377 | 511 | 0.74x | 2.6 KiB | 9.2 KiB | 0.28x | 440 B | 536 B | 0.82x |
| validate/basic/nested-contains-first | 10 | 0.64 | 1.54 | 0.42x | 265 | 580 | 0.46x | 1.7 KiB | 9.1 KiB | 0.19x | 184 B | 200 B | 0.92x |
| validate/basic/unique-scalars | 10 | 0.94 | 0.32 | 2.90x | 272 | 144 | 1.89x | 2.9 KiB | 2.4 KiB | 1.24x | 184 B | 184 B | 1.00x |
| validate/basic/object-properties | 10 | 2.13 | 2.42 | 0.88x | 549 | 630 | 0.87x | 3.8 KiB | 6.8 KiB | 0.57x | 184 B | 536 B | 0.34x |
| validate/basic/object-sparse | 10 | 0.69 | 0.40 | 1.73x | 231 | 237 | 0.97x | 1.8 KiB | 1.7 KiB | 1.05x | 184 B | 104 B | 1.77x |
| validate/basic/object-api-assertions | 10 | 5.46 | 3.80 | 1.43x | 864 | 864 | 1.00x | 6.8 KiB | 9.6 KiB | 0.71x | 184 B | 704 B | 0.26x |
| validate/basic/object-unevaluated | 10 | 2.21 | 3.87 | 0.57x | 520 | 786 | 0.66x | 3.5 KiB | 10.5 KiB | 0.34x | 184 B | 536 B | 0.34x |
| validate/basic/anyOf-first | 10 | 88.4 | 1.07 | 82.88x | 6960 | 408 | 17.06x | 128.2 KiB | 7.5 KiB | 17.20x | 184 B | 24 B | 7.67x |
| validate/basic/unused-definitions | 10 | 0.57 | 0.08 | 7.14x | 190 | 63 | 3.02x | 1.4 KiB | 467 B | 3.08x | 184 B | 24 B | 7.67x |
| validate/basic/items-valid | 100 | 2.75 | 16.6 | 0.17x | 1935 | 4493 | 0.43x | 14.8 KiB | 52.1 KiB | 0.28x | 184 B | 1.6 KiB | 0.11x |
| validate/basic/items-invalid-last | 100 | 4.66 | 10.9 | 0.43x | 2228 | 4517 | 0.49x | 17.5 KiB | 52.7 KiB | 0.33x | 640 B | 2.1 KiB | 0.30x |
| validate/basic/items-true | 100 | 0.57 | 7.27 | 0.08x | 209 | 3078 | 0.07x | 1.3 KiB | 33.4 KiB | 0.04x | 184 B | 1.6 KiB | 0.11x |
| validate/basic/contains-first | 100 | 0.68 | 19.4 | 0.04x | 214 | 4430 | 0.05x | 1.6 KiB | 83.0 KiB | 0.02x | 184 B | 1.6 KiB | 0.11x |
| validate/basic/contains-none | 100 | 1.81 | 13.8 | 0.13x | 1298 | 4469 | 0.29x | 6.1 KiB | 83.6 KiB | 0.07x | 440 B | 1.9 KiB | 0.22x |
| validate/basic/nested-contains-first | 100 | 0.66 | 13.5 | 0.05x | 281 | 4497 | 0.06x | 1.7 KiB | 83.6 KiB | 0.02x | 184 B | 1.6 KiB | 0.11x |
| validate/basic/unique-scalars | 100 | 5.17 | 5.48 | 0.94x | 793 | 1105 | 0.72x | 25.5 KiB | 30.4 KiB | 0.84x | 184 B | 1.6 KiB | 0.11x |
| validate/basic/object-properties | 100 | 11.0 | 19.9 | 0.55x | 2811 | 5894 | 0.48x | 24.2 KiB | 62.4 KiB | 0.39x | 184 B | 6.0 KiB | 0.03x |
| validate/basic/object-sparse | 100 | 0.72 | 1.67 | 0.43x | 1310 | 1318 | 0.99x | 1.9 KiB | 6.5 KiB | 0.29x | 184 B | 104 B | 1.77x |
| validate/basic/object-api-assertions | 100 | 13.2 | 21.6 | 0.61x | 3108 | 6259 | 0.50x | 26.6 KiB | 66.3 KiB | 0.40x | 184 B | 6.2 KiB | 0.03x |
| validate/basic/object-unevaluated | 100 | 9.56 | 61.1 | 0.16x | 2415 | 8002 | 0.30x | 21.1 KiB | 105.4 KiB | 0.20x | 184 B | 6.0 KiB | 0.03x |
| validate/basic/anyOf-first | 100 | 753.6 | 9.70 | 77.67x | 58847 | 3574 | 16.47x | 1.1 MiB | 71.2 KiB | 15.43x | 184 B | 24 B | 7.67x |
| validate/basic/unused-definitions | 100 | 0.58 | 0.08 | 7.33x | 190 | 42 | 4.52x | 1.5 KiB | 488 B | 3.22x | 184 B | 24 B | 7.67x |
| validate/basic/items-valid | 1000 | 26.0 | 107.7 | 0.24x | 17846 | 43626 | 0.41x | 134.3 KiB | 515.8 KiB | 0.26x | 184 B | 15.6 KiB | 0.01x |
| validate/basic/items-invalid-last | 1000 | 26.7 | 110.1 | 0.24x | 18138 | 43636 | 0.42x | 137.0 KiB | 516.4 KiB | 0.27x | 640 B | 16.2 KiB | 0.04x |
| validate/basic/items-true | 1000 | 0.60 | 75.4 | 0.01x | 174 | 29521 | 0.01x | 1.3 KiB | 328.7 KiB | 0.00x | 184 B | 15.6 KiB | 0.01x |
| validate/basic/contains-first | 1000 | 0.62 | 138.1 | 0.00x | 214 | 42844 | 0.00x | 1.6 KiB | 828.1 KiB | 0.00x | 184 B | 15.6 KiB | 0.01x |
| validate/basic/contains-none | 1000 | 10.6 | 145.0 | 0.07x | 10476 | 42866 | 0.24x | 41.3 KiB | 828.8 KiB | 0.05x | 440 B | 16.0 KiB | 0.03x |
| validate/basic/nested-contains-first | 1000 | 0.68 | 139.9 | 0.00x | 236 | 42926 | 0.01x | 1.7 KiB | 829.0 KiB | 0.00x | 184 B | 15.7 KiB | 0.01x |
| validate/basic/unique-scalars | 1000 | 52.9 | 67.9 | 0.78x | 6335 | 10972 | 0.58x | 302.1 KiB | 351.7 KiB | 0.86x | 184 B | 15.6 KiB | 0.01x |
| validate/basic/object-properties | 1000 | 104.0 | 193.5 | 0.54x | 27591 | 56583 | 0.49x | 227.3 KiB | 614.9 KiB | 0.37x | 184 B | 60.1 KiB | 0.00x |
| validate/basic/object-sparse | 1000 | 0.79 | 13.6 | 0.06x | 231 | 12120 | 0.02x | 2.6 KiB | 51.0 KiB | 0.05x | 184 B | 104 B | 1.77x |
| validate/basic/object-api-assertions | 1000 | 110.3 | 208.2 | 0.53x | 28207 | 57112 | 0.49x | 232.5 KiB | 635.0 KiB | 0.37x | 184 B | 60.4 KiB | 0.00x |
| validate/basic/object-unevaluated | 1000 | 100.3 | 2824.3 | 0.04x | 24373 | 104272 | 0.23x | 172.0 KiB | 1.0 MiB | 0.16x | 184 B | 60.1 KiB | 0.00x |
| validate/basic/anyOf-first | 1000 | 7940.3 | 144.0 | 55.15x | 550229 | 29988 | 18.35x | 10.6 MiB | 711.5 KiB | 15.25x | 184 B | 24 B | 7.67x |
| validate/basic/unused-definitions | 1000 | 0.55 | 0.07 | 7.52x | 190 | 42 | 4.52x | 2.8 KiB | 629 B | 4.59x | 184 B | 24 B | 7.67x |

## Compilation

| Scenario | N | ex_json_schema µs | JSV µs | Time | ex_json_schema reductions | JSV reductions | Compute | ex_json_schema allocation | JSV allocation | Allocation | ex_json_schema result | JSV result | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| compile/object-properties | 10 | 109.0 | 13.4 | 8.15x | 9977 | 4909 | 2.03x | 192.6 KiB | 48.4 KiB | 3.98x | 12.2 KiB | 3.6 KiB | 3.34x |
| compile/object-properties | 100 | 948.0 | 82.1 | 11.54x | 85904 | 40951 | 2.10x | 1.7 MiB | 379.3 KiB | 4.51x | 44.0 KiB | 31.4 KiB | 1.40x |
| compile/object-properties | 1000 | 11307.2 | 1254.4 | 9.01x | 842606 | 417767 | 2.02x | 16.6 MiB | 3.6 MiB | 4.57x | 357.8 KiB | 308.5 KiB | 1.16x |

## Compiled validator footprint

| Scenario | N | ex_json_schema retained | JSV retained | Retained | ex_json_schema flat | JSV flat | Flat |
| --- | --- | --- | --- | --- | --- | --- | --- |
| items-valid | 10 | 9.5 KiB | 976 B | 9.93x | 10.9 KiB | 1.0 KiB | 10.80x |
| items-invalid-last | 10 | 9.5 KiB | 976 B | 9.93x | 10.9 KiB | 1.0 KiB | 10.80x |
| items-true | 10 | 9.2 KiB | 824 B | 11.44x | 10.6 KiB | 840 B | 12.90x |
| contains-first | 10 | 9.5 KiB | 960 B | 10.08x | 10.9 KiB | 1016 B | 10.94x |
| contains-none | 10 | 9.5 KiB | 960 B | 10.08x | 10.9 KiB | 1016 B | 10.94x |
| nested-contains-first | 10 | 10.0 KiB | 1.3 KiB | 7.58x | 12.0 KiB | 1.4 KiB | 8.27x |
| unique-scalars | 10 | 9.0 KiB | 672 B | 13.71x | 10.0 KiB | 672 B | 15.31x |
| object-properties | 10 | 12.2 KiB | 3.6 KiB | 3.34x | 22.2 KiB | 5.2 KiB | 4.24x |
| object-sparse | 10 | 12.2 KiB | 3.6 KiB | 3.34x | 22.2 KiB | 5.2 KiB | 4.24x |
| object-api-assertions | 10 | 14.9 KiB | 5.8 KiB | 2.56x | 27.3 KiB | 7.9 KiB | 3.45x |
| object-unevaluated | 10 | 12.5 KiB | 3.9 KiB | 3.23x | 23.0 KiB | 5.5 KiB | 4.19x |
| anyOf-first | 10 | 10.9 KiB | 3.1 KiB | 3.53x | 17.7 KiB | 3.8 KiB | 4.63x |
| unused-definitions | 10 | 15.6 KiB | 2.0 KiB | 7.93x | 30.5 KiB | 2.5 KiB | 12.06x |
| items-valid | 100 | 9.5 KiB | 976 B | 9.93x | 10.9 KiB | 1.0 KiB | 10.80x |
| items-invalid-last | 100 | 9.5 KiB | 976 B | 9.93x | 10.9 KiB | 1.0 KiB | 10.80x |
| items-true | 100 | 9.2 KiB | 824 B | 11.44x | 10.6 KiB | 840 B | 12.90x |
| contains-first | 100 | 9.5 KiB | 960 B | 10.08x | 10.9 KiB | 1016 B | 10.94x |
| contains-none | 100 | 9.5 KiB | 960 B | 10.08x | 10.9 KiB | 1016 B | 10.94x |
| nested-contains-first | 100 | 10.0 KiB | 1.3 KiB | 7.58x | 12.0 KiB | 1.4 KiB | 8.27x |
| unique-scalars | 100 | 9.0 KiB | 672 B | 13.71x | 10.0 KiB | 672 B | 15.31x |
| object-properties | 100 | 44.0 KiB | 31.4 KiB | 1.40x | 137.7 KiB | 47.8 KiB | 2.88x |
| object-sparse | 100 | 44.0 KiB | 31.4 KiB | 1.40x | 137.7 KiB | 47.8 KiB | 2.88x |
| object-api-assertions | 100 | 46.9 KiB | 33.6 KiB | 1.39x | 142.9 KiB | 50.5 KiB | 2.83x |
| object-unevaluated | 100 | 44.4 KiB | 31.7 KiB | 1.40x | 138.6 KiB | 48.0 KiB | 2.88x |
| anyOf-first | 100 | 30.1 KiB | 25.6 KiB | 1.18x | 93.2 KiB | 33.4 KiB | 2.79x |
| unused-definitions | 100 | 84.0 KiB | 15.9 KiB | 5.27x | 230.3 KiB | 22.1 KiB | 10.41x |
| items-valid | 1000 | 9.5 KiB | 976 B | 9.93x | 10.9 KiB | 1.0 KiB | 10.80x |
| items-invalid-last | 1000 | 9.5 KiB | 976 B | 9.93x | 10.9 KiB | 1.0 KiB | 10.80x |
| items-true | 1000 | 9.2 KiB | 824 B | 11.44x | 10.6 KiB | 840 B | 12.90x |
| contains-first | 1000 | 9.5 KiB | 960 B | 10.08x | 10.9 KiB | 1016 B | 10.94x |
| contains-none | 1000 | 9.5 KiB | 960 B | 10.08x | 10.9 KiB | 1016 B | 10.94x |
| nested-contains-first | 1000 | 10.0 KiB | 1.3 KiB | 7.58x | 12.0 KiB | 1.4 KiB | 8.27x |
| unique-scalars | 1000 | 9.0 KiB | 672 B | 13.71x | 10.0 KiB | 672 B | 15.31x |
| object-properties | 1000 | 357.8 KiB | 308.5 KiB | 1.16x | 1.3 MiB | 472.5 KiB | 2.73x |
| object-sparse | 1000 | 357.8 KiB | 308.5 KiB | 1.16x | 1.3 MiB | 472.5 KiB | 2.73x |
| object-api-assertions | 1000 | 360.8 KiB | 310.8 KiB | 1.16x | 1.3 MiB | 475.3 KiB | 2.72x |
| object-unevaluated | 1000 | 358.2 KiB | 308.7 KiB | 1.16x | 1.3 MiB | 472.7 KiB | 2.73x |
| anyOf-first | 1000 | 221.5 KiB | 250.6 KiB | 0.88x | 847.0 KiB | 328.7 KiB | 2.58x |
| unused-definitions | 1000 | 763.1 KiB | 154.5 KiB | 4.94x | 2.2 MiB | 216.9 KiB | 10.25x |

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
