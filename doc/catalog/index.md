# Catalog UI

Use this section when you want to manage locale files through the standalone catalog sidecar instead of editing translation files by hand.

## What this section helps you do

- start the UI and JSON API against your existing locale files
- add, edit, review, and delete translation rows
- bulk-create keys from JSON input
- understand how catalog state is stored and how statuses are computed

## Fastest path

```bash
dart run anas_localization:anas_cli catalog init
```

```bash
dart run anas_localization:anas_cli catalog serve
```

![Catalog table UI](screenshots/catalog-table.png)

## When to use the catalog

Use the catalog when:

- translators or reviewers need a browser table instead of raw JSON files
- you want review status tracking per locale cell
- you want a sidecar API for custom tooling around translation review

The catalog sidecar is separate from your Flutter app runtime. It starts:

- a UI server on `ui_port`
- an API server on `api_port`

## Read next

- [Setup and Serve](setup-and-serve.md)
- [Edit and Review Flow](edit-and-review-flow.md)
- [Bulk Operations and API](bulk-and-api.md)
- [Architecture](architecture.md)
