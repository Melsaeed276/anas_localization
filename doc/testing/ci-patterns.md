# CI Patterns

Use this page when you want deterministic automation around localization quality.

## Recommended CI sequence

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings
dart run anas_localization:localization_gen --modules --module-depth=2
flutter analyze
flutter test
```

## Suggested gates

- fail on missing keys
- fail on placeholder schema violations
- run generation in CI so codegen regressions surface early
- keep `flutter test` after localization validation so failures are easier to diagnose

## Next

- [Validate](../cli/validate.md)
- [Setup and Codegen Issues](../troubleshooting/setup-and-codegen.md)
