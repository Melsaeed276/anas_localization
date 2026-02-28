# Benchmark Harness

This folder provides reproducible performance checks for:

- Cold load latency (JSON decode + dictionary creation)
- Hot switch latency (locale dictionary switching)
- Memory RSS growth

Datasets are generated at **1k / 5k / 10k keys**.

## Run

```bash
dart run benchmark/localization_benchmark.dart
```

## Save a baseline/report

```bash
dart run benchmark/localization_benchmark.dart --output benchmark/baseline.json
```

## Compare with baseline

```bash
dart run benchmark/localization_benchmark.dart \
  --compare benchmark/baseline.json \
  --max-regression=0.50
```

The compare command exits non-zero when any metric regresses above the allowed ratio.

CI integration is available via `.github/workflows/benchmark.yml`:
- Pull requests generate and upload a benchmark report artifact.
- Manual workflow dispatch also runs baseline comparison.
