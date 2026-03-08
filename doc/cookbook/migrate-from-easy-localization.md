# Migrate from `easy_localization`

This is the fastest path if your project currently uses `easy_localization`.

## Phase 1: convert translation assets

If your project uses the default folder layout:

```bash
anas convert --from easy_localization
```

If your translations live somewhere else:

```bash
anas convert --from easy_localization --source assets/translations --out assets/lang
```

Supported source formats:

- JSON
- YAML / YML
- CSV

The command normalizes output into `assets/lang/<locale>.json`.

## Phase 2: migrate Dart callsites

Dry run:

```bash
anas migrate --from easy_localization --dry-run
```

Apply changes:

```bash
anas migrate --from easy_localization --apply
```

Update tests too:

```bash
anas migrate --from easy_localization --test test --apply
```

## What gets rewritten

- `'key'.tr()`
- `tr('key')`
- `Text('key').tr()`
- plural lookups
- `context.setLocale(...)`

## Follow-up

After migration:

```bash
dart run anas_localization:localization_gen
anas validate assets/lang
flutter analyze
flutter test
```

## Detailed guide

For the longer guide, see [the repo migration doc](../MIGRATION_EASY_LOCALIZATION.md).
