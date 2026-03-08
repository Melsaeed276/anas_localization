# Migration Strategy

Use this page before editing code so you can pick a safer migration order.

## Recommended order

1. normalize translation assets into the target app layout
2. validate the new locale files
3. generate the dictionary
4. switch app bootstrap
5. replace translation reads screen by screen
6. verify locale switching and tests

## Core validation commands

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=balanced
flutter analyze
flutter test
```

## Good migration boundaries

- keep the old asset source untouched until the new flow is stable
- move one feature area at a time
- verify generated dictionary output before replacing lookups everywhere

## Next

- [From easy_localization](from-easy-localization.md)
- [From gen_l10n](from-gen-l10n.md)
- [Validate a Migration](validate-a-migration.md)
