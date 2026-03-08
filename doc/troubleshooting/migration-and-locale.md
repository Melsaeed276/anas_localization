# Migration and Locale Issues

Use this page when a migrated app compiles but translations or locale changes behave incorrectly.

## Re-check the migration

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings
flutter analyze
flutter test
```

## Things to verify

- your app uses the new locale folder as the runtime source of truth
- `supportedLocales` and `assetLocales` match the actual file set
- old translation calls are not mixed with new generated reads on the same screen
- locale changes use `AnasLocalization.of(context).setLocale(...)`

## Common symptoms

- stale UI after locale switch: check widget tree placement of `AnasLocalization`
- missing keys after migration: confirm the imported files wrote the expected nested JSON structure
- lookup mismatch: regenerate the dictionary after changing source keys

## Next

- [Validate a Migration](../migrate/validate-a-migration.md)
- [Read Translations](../use-in-app/read-translations.md)
