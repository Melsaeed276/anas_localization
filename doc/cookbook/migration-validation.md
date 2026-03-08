# Migration Validation Flow

The package includes a demo migration validator that creates temporary apps, runs the migration pipeline, and checks whether the migrated apps still analyze and test successfully.

## Run both supported migrations

```bash
anas validate-migration
```

## Run one source package only

```bash
anas validate-migration --from easy_localization
anas validate-migration --from gen_l10n
```

## Write a report

```bash
anas validate-migration \
  --report build/migration_validation/report.json \
  --compare benchmark/migration_validation_baseline.json
```

## Refresh the timing baseline

```bash
anas validate-migration \
  --report benchmark/migration_validation_baseline.json \
  --compare benchmark/migration_validation_baseline.json \
  --update-baseline
```

## What it validates

For each supported source package, the validator:

1. generates a temporary demo Flutter app
2. runs `flutter pub get`
3. runs `anas convert --from ...`
4. runs `anas migrate --from ... --apply`
5. runs `dart run anas_localization:localization_gen`
6. runs `flutter analyze`
7. runs `flutter test`

It also records per-step timings and total time.

## CI behavior

- functional failures should fail CI
- timing regressions over the configured threshold are warnings only
- reports are saved as workflow artifacts
