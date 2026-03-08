# Catalog Issues

Use this page when the sidecar UI or catalog commands do not behave as expected.

## First checks

```bash
dart run anas_localization:anas_cli catalog status
dart run anas_localization:anas_cli catalog serve
```

## Things to verify

- `anas_catalog.yaml` points to the correct `lang_dir`
- the locale files exist in the format declared by the catalog config
- the state file is writable
- UI and API ports are not already in use

## Common symptoms

- empty table: confirm the configured `lang_dir` contains files
- status not updating: check whether values were partially added and still require review
- API issues: confirm the sidecar is running and the configured ports match the browser requests

## Next

- [Setup and Serve](../catalog/setup-and-serve.md)
- [Bulk Operations and API](../catalog/bulk-and-api.md)
