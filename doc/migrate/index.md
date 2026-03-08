# Migrate

Use this section when you are moving an existing localization setup to `anas_localization`.

## What this section covers

- choosing a migration strategy
- moving from `easy_localization`
- moving from Flutter `gen_l10n`
- validating the migrated app with existing package tools

## Migration checklist

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=balanced
flutter analyze
flutter test
```

## Read next

- [Migration Strategy](migration-strategy.md)
- [From easy_localization](from-easy-localization.md)
- [From gen_l10n](from-gen-l10n.md)
