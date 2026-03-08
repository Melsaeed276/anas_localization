# Troubleshooting

Use this section when setup, generation, locale switching, or catalog behavior does not match expectations.

## Common problem areas

- missing assets or unsupported locale setup
- dictionary generation and import errors
- migration regressions
- locale switching behavior
- catalog state or API issues

## First checks

```bash
dart run anas_localization:anas_cli validate assets/lang
dart run anas_localization:localization_gen
flutter analyze
```

## Read next

- [Setup and Codegen Issues](setup-and-codegen.md)
- [Migration and Locale Issues](migration-and-locale.md)
- [Catalog Issues](catalog.md)
