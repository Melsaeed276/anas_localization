# Config Reference

Use this page when you want the important configuration surfaces in one place.

## `AnasLocalization`

```dart
AnasLocalization(
  app: const MyApp(),
  fallbackLocale: const Locale('en'),
  assetPath: 'assets/lang',
  assetLocales: const [Locale('en'), Locale('ar')],
  animationSetup: true,
  setupDuration: const Duration(milliseconds: 2000),
  previewDictionaries: const {
    'en': {'app_name': 'Preview App'},
  },
)
```

## `anas_catalog.yaml`

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

Catalog fields:

| Field | Meaning |
| --- | --- |
| `lang_dir` | Directory that contains the locale files the catalog edits. |
| `format` | Locale file format: `json`, `yaml`, `csv`, or `arb`. |
| `fallback_locale` | Fallback locale used by the package and also as the source locale when `source_locale` is `null`. |
| `source_locale` | Locale treated as the source column for review-state transitions. |
| `state_file` | JSON sidecar file that stores review metadata and source hashes. |
| `ui_port` | Port used by the browser table UI. |
| `api_port` | Port used by the catalog JSON API. |
| `open_browser` | Whether `catalog serve` opens the UI automatically. |
| `arb_file_prefix` | Prefix used when the catalog works against ARB files. |

## Notes

- `dictionaryFactory` is required when you want the app to use your generated dictionary type
- `previewDictionaries` is useful for tests, previews, and fast demos
- `state_file` does not replace locale files; it only stores catalog workflow state

## Next

- [Concepts](concepts.md)
- [Catalog Architecture](../catalog/architecture.md)
- [File Structure](file-structure.md)
