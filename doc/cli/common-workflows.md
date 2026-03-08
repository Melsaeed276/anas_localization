# Common Workflows

Use this page when you want copyable command sequences for the most common maintenance tasks.

## Validate and regenerate

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings
dart run anas_localization:localization_gen
```

## Add a key and check stats

```bash
dart run anas_localization:anas_cli add-key "home.title" "Home" assets/lang
dart run anas_localization:anas_cli stats assets/lang
```

## Run catalog with the app

```bash
dart run anas_localization:anas_cli dev --with-catalog -- flutter run
```

## Next

- [Validate](validate.md)
- [Catalog Commands](catalog.md)
