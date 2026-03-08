# Bulk Operations and API

Use this page when you want to create many keys at once or integrate tooling directly with the catalog JSON API.

## Bulk-create keys from JSON

```bash
dart run anas_localization:anas_cli catalog add-key --values-file=tool/catalog_add_keys.json
```

Expected JSON shape:

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

Each entry is passed through the same add-key service path as the UI modal and single-key CLI command.

## API endpoint inventory

```text
GET /api/catalog/meta
GET /api/catalog/rows
GET /api/catalog/summary
POST /api/catalog/key
PATCH /api/catalog/cell
DELETE /api/catalog/cell
POST /api/catalog/review
DELETE /api/catalog/key
```

## Useful API calls

Load metadata:

```bash
curl http://127.0.0.1:4467/api/catalog/meta
```

Create a new key:

```bash
curl -X POST http://127.0.0.1:4467/api/catalog/key \
  -H "Content-Type: application/json" \
  -d '{"keyPath":"home.title","valuesByLocale":{"en":"Home","tr":"Ana Sayfa","ar":"الرئيسية"}}'
```

Mark a locale cell reviewed:

```bash
curl -X POST http://127.0.0.1:4467/api/catalog/review \
  -H "Content-Type: application/json" \
  -d '{"keyPath":"home.title","locale":"tr"}'
```

## Response expectations

- `meta` returns locales, source locale, fallback locale, resolved paths, and ports
- `rows` returns the table rows with `valuesByLocale` and `cellStates`
- `summary` returns total key count plus green, warning, and red counts
- mutation routes return either the updated row or a simple `{ "ok": true }` response

## Source of truth

The API does not own translation content by itself.

- translation files remain the content source of truth
- the catalog state file stores review metadata and source hashes
- the service layer keeps both in sync before it returns rows

## Next

- [Catalog Commands](../cli/catalog.md)
- [Architecture](architecture.md)
- [Config Reference](../reference/config-reference.md)
