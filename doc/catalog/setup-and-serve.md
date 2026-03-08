# Setup and Serve

Use this page when you want a working catalog UI and API against the locale files that already live in your project.

## Prerequisites

- your translations already exist under a directory such as `assets/lang`
- the files use one supported format: `json`, `yaml`, `csv`, or `arb`

## 1. Create `anas_catalog.yaml`

```bash
dart run anas_localization:anas_cli catalog init
```

This writes a default `anas_catalog.yaml` if it does not exist yet.

## 2. Adjust the config if needed

```yaml
version: 1
lang_dir: assets/lang
format: json
fallback_locale: en
source_locale: null
state_file: .anas_localization/catalog_state.json
ui_port: 4466
api_port: 4467
open_browser: true
arb_file_prefix: app
```

Important behavior:

- `source_locale: null` means the catalog uses `fallback_locale` as the source locale
- `state_file` stores review metadata and source hashes, not the translations themselves
- `open_browser: true` opens the UI automatically after `catalog serve`

## 3. Check the current dataset

```bash
dart run anas_localization:anas_cli catalog status
```

If you use a non-default config file:

```bash
dart run anas_localization:anas_cli catalog status --config=build/catalog/anas_catalog.yaml
```

## 4. Start the sidecar

```bash
dart run anas_localization:anas_cli catalog serve
```

If you need a specific bind host:

```bash
dart run anas_localization:anas_cli catalog serve --host=127.0.0.1
```

![Catalog running against locale files](screenshots/catalog-table.png)

## What starts

- `CatalogApiServer` on `api_port`
- `CatalogUiServer` on `ui_port`
- an optional browser launch when `open_browser` is `true`

The UI server only serves the catalog page. The browser page then calls the API server for metadata, rows, summary, and mutations.

## Common notes

- `catalog serve` does not replace your Flutter app; it is a separate sidecar process
- the UI and API ports can be different from your Flutter dev server ports
- if the table is empty, check `lang_dir`, `format`, and `source_locale` first

## Next

- [Edit and Review Flow](edit-and-review-flow.md)
- [Architecture](architecture.md)
- [Config Reference](../reference/config-reference.md)
