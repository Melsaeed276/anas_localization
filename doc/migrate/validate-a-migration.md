# Validate a Migration

Use this page after moving assets or replacing callsites so you can confirm the new setup still works.

## Minimum verification flow

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=balanced
dart run anas_localization:localization_gen
flutter analyze
flutter test
```

## Stronger CI-oriented check

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings
flutter analyze
flutter test
```

## What to verify manually

- the app loads the fallback locale
- a non-default locale renders correctly
- locale switching updates visible UI
- parameterized and plural strings still work as expected

## Next

- [CI Patterns](../testing/ci-patterns.md)
- [Migration and Locale Issues](../troubleshooting/migration-and-locale.md)
