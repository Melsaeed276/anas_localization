# Migrate from Flutter `gen_l10n`

Use this flow if the project currently uses Flutter's generated `AppLocalizations` APIs.

## Phase 1: convert ARB assets

From the project root:

```bash
anas convert --from gen_l10n
```

Or point to a specific `l10n.yaml`:

```bash
anas convert --from gen_l10n --source l10n.yaml --out assets/lang
```

Phase 1 requires a real `l10n.yaml`.

## Phase 2: migrate Dart callsites

Dry run:

```bash
anas migrate --from gen_l10n --dry-run
```

Apply changes:

```bash
anas migrate --from gen_l10n --apply
```

Update tests too:

```bash
anas migrate --from gen_l10n --test test --apply
```

## What gets rewritten

- `AppLocalizations.of(context)!.title`
- parameterized `AppLocalizations` method calls
- deterministic plural and placeholder-based lookups

## Follow-up

After migration:

```bash
dart run anas_localization:localization_gen
anas validate assets/lang
flutter analyze
flutter test
```

## Detailed guide

For the longer guide, see [the repo migration doc](../guides/migration-gen-l10n.md).
