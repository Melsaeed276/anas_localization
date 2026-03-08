## In Memory of Anas Al-Sharif [![StandWithPalestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/badges/StandWithPalestine.svg)](https://github.com/TheBSD/StandWithPalestine/blob/main/docs/README.md)

<img width="400" height="550" alt="image" src="https://github.com/user-attachments/assets/91350ed1-f1f2-4447-829c-de97288fe2d1" />

This package is dedicated to the memory of Anas Al-Sharif, a Palestinian journalist for Al Jazeera in Gaza. Anas was martyred while reporting in August 2025, courageously bringing truth to the world. This work serves as a Sadaqah Jariyah in his name.

# anas_localization

A Flutter and Dart localization package focused on:

- generated dictionary APIs
- runtime locale switching
- JSON-first translation assets
- validation workflows for CI
- a standalone translation catalog sidecar

[![PR Quality Checks](https://github.com/Melsaeed276/anas_localization/actions/workflows/pr-tests.yml/badge.svg)](https://github.com/Melsaeed276/anas_localization/actions/workflows/pr-tests.yml)
[![Benchmark Harness](https://github.com/Melsaeed276/anas_localization/actions/workflows/benchmark.yml/badge.svg)](https://github.com/Melsaeed276/anas_localization/actions/workflows/benchmark.yml)
[![Release Gate](https://github.com/Melsaeed276/anas_localization/actions/workflows/release-gate.yml/badge.svg)](https://github.com/Melsaeed276/anas_localization/actions/workflows/release-gate.yml)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue.svg)](LICENSE)

## Why this package

Use `anas_localization` when you need:

- type-safe generated dictionary access
- deterministic locale fallback behavior
- runtime loaders for JSON, YAML, CSV, or HTTP
- validation profiles for translation quality gates
- a translation catalog UI outside the app runtime

## Install

```bash
flutter pub add anas_localization
```

## Usage

```dart
import 'package:anas_localization/anas_localization.dart';
import 'generated/dictionary.dart' as app_dictionary;

void main() {
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return AnasLocalization(
      fallbackLocale: const Locale('en'),
      assetLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      dictionaryFactory: (map, {required locale}) {
        return app_dictionary.Dictionary.fromMap(map, locale: locale);
      },
      app: const MyApp(),
    );
  }
}
```

## Common commands

Generate the dictionary:

```bash
dart run anas_localization:localization_gen
```

Validate locale files:

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings
```

Start the catalog sidecar:

```bash
dart run anas_localization:anas_cli catalog init
```

```bash
dart run anas_localization:anas_cli catalog serve
```

## Catalog UI

This branch includes a standalone catalog sidecar with:

- a browser table for translation editing and review
- per-cell review statuses driven by the source locale
- a separate JSON API for custom tooling

Read the catalog docs:

- [Catalog overview](https://melsaeed276.github.io/anas_localization/catalog/)
- [Catalog architecture](https://melsaeed276.github.io/anas_localization/catalog/architecture/)

## Documentation

Primary docs live in the cookbook/docs system:

- [Docs home](https://melsaeed276.github.io/anas_localization/)
- [Get Started](https://melsaeed276.github.io/anas_localization/get-started/)
- [Use in App](https://melsaeed276.github.io/anas_localization/use-in-app/)
- [Migrate](https://melsaeed276.github.io/anas_localization/migrate/)
- [Testing](https://melsaeed276.github.io/anas_localization/testing/)
- [Catalog](https://melsaeed276.github.io/anas_localization/catalog/)
- [CLI](https://melsaeed276.github.io/anas_localization/cli/)
- [Reference](https://melsaeed276.github.io/anas_localization/reference/)
- [Troubleshooting](https://melsaeed276.github.io/anas_localization/troubleshooting/)

## Example structure

```text
assets/lang/en.json
assets/lang/ar.json
lib/generated/dictionary.dart
```

## License

Apache-2.0. See [LICENSE](LICENSE).
