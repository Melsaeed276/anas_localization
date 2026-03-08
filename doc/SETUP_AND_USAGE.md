# Setup and Usage Guide

This guide covers:

- How to set up localization in a Flutter app
- How to use translated strings in code
- How to use the Catalog UI/CLI workflow

## 1) Install the package

In your app `pubspec.yaml`:

```yaml
dependencies:
  anas_localization: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## 2) Create translation files

Create locale JSON files (default path is `assets/lang`):

```text
assets/lang/en.json
assets/lang/tr.json
assets/lang/ar.json
```

Example `assets/lang/en.json`:

```json
{
  "app_name": "My App",
  "home": {
    "title": "Home"
  }
}
```

Add assets in your app `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/lang/
```

## 3) Generate dictionary class

Run:

```bash
dart run anas_localization:localization_gen
```

Optional:

- Watch mode: `dart run anas_localization:localization_gen --watch`
- Module namespaces: `--modules`, `--modules-only`, `--module-depth=2`

## 4) Configure app localization

Use `AnasLocalization` at app root:

```dart
import 'package:anas_localization/localization.dart';
import 'generated/dictionary.dart' as app_dictionary;

return AnasLocalization(
  fallbackLocale: const Locale('en'),
  assetLocales: const [
    Locale('en'),
    Locale('tr'),
    Locale('ar'),
  ],
  dictionaryFactory: (Map<String, dynamic> map, {required String locale}) {
    return app_dictionary.Dictionary.fromMap(map, locale: locale);
  },
  app: MaterialApp(
    home: const HomePage(),
  ),
);
```

## 5) Use translations in widgets

```dart
final dict = AnasLocalization.of(context).dictionary as app_dictionary.Dictionary;

Text(dict.appName);
Text(dict.home.title);
```

## 6) Change locale at runtime

```dart
await AnasLocalization.of(context).setLocale(const Locale('tr'));
```

`AnasLocalization` handles locale updates and saved locale persistence.

## 7) Validate and maintain translation files

Examples:

```bash
dart run anas_localization:anas_cli validate assets/lang
dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings
dart run anas_localization:anas_cli add-key home.title "Home" assets/lang
dart run anas_localization:anas_cli remove-key home.title assets/lang
dart run anas_localization:anas_cli stats assets/lang
```

## 8) Use the Catalog workflow (UI + API + CLI)

The catalog is a standalone sidecar for translation management.

### Initialize config

```bash
dart run anas_localization:anas_cli catalog init
```

This creates `anas_catalog.yaml`.

### Start catalog UI and API

```bash
dart run anas_localization:anas_cli catalog serve
```

You get:

- UI server (`ui_port`, default `4466`)
- API server (`api_port`, default `4467`)

### Catalog statuses

- `green`: reviewed / in sync
- `warning`: needs review
- `red`: missing/deleted value needs action

### Create new string (key)

In UI: `+ New String`

In CLI:

```bash
dart run anas_localization:anas_cli catalog add-key --key=home.header.title --value-en="Home" --value-tr="Ana Sayfa"
```

Rules:

- Key is created in all supported locales.
- If all locale values are provided at creation time, cells become `green`.
- If not complete, cells stay `warning` with `new_key_needs_translation_review`.

### Review and delete in catalog

```bash
dart run anas_localization:anas_cli catalog review --key=home.header.title --locale=tr
dart run anas_localization:anas_cli catalog delete-key --key=home.header.title
```

### Run app and catalog together

```bash
dart run anas_localization:anas_cli dev --with-catalog -- flutter run
```

## 9) Extra catalog docs

See dedicated catalog reference:

- `doc/CATALOG_UI.md`
