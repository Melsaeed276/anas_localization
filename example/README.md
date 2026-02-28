# localization_example

This app demonstrates package capabilities at two practical complexity levels.

## Run

```bash
flutter pub get
flutter run
```

## Medium Example Structure

Focus:
- feature-module style key organization
- generated typed dictionary access
- locale fallback chain behavior

Suggested structure:

```text
lib/
  main.dart
  generated/dictionary.dart
  pages/
    features_page.dart
  widgets/
    language_selector.dart
assets/lang/
  en.json
  ar.json
  tr.json
```

Visual output:

![Medium Example](../docs/screenshots/medium-example.svg)

## Advanced Example Structure

Focus:
- pluggable loader strategy (local + remote pattern)
- strict CLI validation in workflow
- module namespaced generation for large localization files

Suggested workflow:

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings
dart run anas_localization:localization_gen --modules --module-depth=2
flutter run
```

Visual output:

![Advanced Example](../docs/screenshots/advanced-example.svg)
