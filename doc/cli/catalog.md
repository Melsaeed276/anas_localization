# Catalog Commands

Use this page when you want the command-line surface for the catalog sidecar.

## Setup and serve

```bash
dart run anas_localization:anas_cli catalog init
```

```bash
dart run anas_localization:anas_cli catalog serve
```

## Manage keys

```bash
dart run anas_localization:anas_cli catalog add-key --key=home.title --value-en="Home"
```

```bash
dart run anas_localization:anas_cli catalog add-key --values-file=tool/catalog_add_keys.json
```

```bash
dart run anas_localization:anas_cli catalog review --key=home.title --locale=tr
```

```bash
dart run anas_localization:anas_cli catalog delete-key --key=home.title
```

## Status and sidecar development

```bash
dart run anas_localization:anas_cli catalog status
```

```bash
dart run anas_localization:anas_cli dev --with-catalog -- flutter run
```

## Next

- [Edit and Review Flow](../catalog/edit-and-review-flow.md)
- [Catalog Architecture](../catalog/architecture.md)
- [CLI Reference](../reference/cli-reference.md)
