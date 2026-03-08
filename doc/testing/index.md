# Testing

Use this section when you want reliable localized widget tests and CI checks.

## What this section covers

- widget tests with localized content
- preview dictionaries for tests without asset bundles
- CI checks for generated dictionaries and locale validation

## Quick test workflow

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings
flutter test
```

## Read next

- [Localized Widget Tests](widget-tests.md)
- [CI Patterns](ci-patterns.md)
