# Catalog UI Guide

This package ships with a standalone localization catalog sidecar (web UI + API) to manage translations outside your main Flutter app runtime.

## What it provides

- String-catalog table view for all keys across locales
- Inline edit/delete/review actions per locale cell
- `+ New String` creation modal with dotted key support (`home.header.title`)
- Review statuses:
  - `green`: reviewed / in sync
  - `warning`: needs review (including new key review workflow)
  - `red`: missing or deleted value needs action

## Setup

```bash
dart run anas_localization:anas_cli catalog init
dart run anas_localization:anas_cli catalog serve
```

`catalog serve` starts:

- UI server on `ui_port`
- API server on `api_port`

Both are independent from your app run/build lifecycle.

## Config file

Generated config file: `anas_catalog.yaml`

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

## CLI commands

```bash
dart run anas_localization:anas_cli catalog status
dart run anas_localization:anas_cli catalog serve
dart run anas_localization:anas_cli catalog add-key --key=home.title --value-en="Home"
dart run anas_localization:anas_cli catalog review --key=home.title --locale=tr
dart run anas_localization:anas_cli catalog delete-key --key=home.title
dart run anas_localization:anas_cli dev --with-catalog -- flutter run
```

### Create New String workflow

Command:

```bash
dart run anas_localization:anas_cli catalog add-key --key=home.header.title --value-en="Home"
```

Rules:

- New key is created in all supported locales.
- If values are provided for all locales at creation time, cells become `green`.
- If values are partial, cells remain `warning` with reason `new_key_needs_translation_review`.

### Bulk create from JSON

```bash
dart run anas_localization:anas_cli catalog add-key --values-file=tool/catalog_add_keys.json
```

Supported JSON formats:

```json
[
  {
    "keyPath": "home.title",
    "valuesByLocale": {
      "en": "Home",
      "tr": "Ana Sayfa",
      "ar": "الرئيسية"
    }
  }
]
```

or:

```json
{
  "keys": [
    {
      "keyPath": "home.title",
      "valuesByLocale": {
        "en": "Home",
        "tr": "Ana Sayfa"
      }
    }
  ]
}
```

## API endpoints

- `GET /api/catalog/meta`
- `GET /api/catalog/rows`
- `GET /api/catalog/summary`
- `POST /api/catalog/key`
- `PATCH /api/catalog/cell`
- `DELETE /api/catalog/cell`
- `POST /api/catalog/review`
- `DELETE /api/catalog/key`
