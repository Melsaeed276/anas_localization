# Setup and Codegen Issues

Use this page when the app does not load translations or dictionary generation fails.

## Common checks

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=balanced
dart run anas_localization:localization_gen
```

## Things to verify

- `assets/lang` is registered in `pubspec.yaml`
- locale files contain valid JSON
- your generated dictionary file is imported where `getDictionary()` is used
- `dictionaryFactory` is provided when your app depends on the generated type

## If generation still fails

- inspect the first invalid key in the validator output
- regenerate after fixing placeholders or malformed structures
- check that your locale file names match the supported locale list

## Next

- [Config Reference](../reference/config-reference.md)
- [Validate](../cli/validate.md)
