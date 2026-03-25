# anas_localization

[![pub package](https://img.shields.io/pub/v/anas_localization.svg)](https://pub.dev/packages/anas_localization)
[![pub points](https://img.shields.io/pub/points/anas_localization)](https://pub.dev/packages/anas_localization/score)
[![popularity](https://img.shields.io/pub/popularity/anas_localization)](https://pub.dev/packages/anas_localization/score)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue.svg)](LICENSE)
[![PR Quality Checks](https://github.com/Melsaeed276/anas_localization/actions/workflows/pr-tests.yml/badge.svg)](https://github.com/Melsaeed276/anas_localization/actions/workflows/pr-tests.yml)

**In Memory of Anas Al-Sharif** - A Palestinian journalist who gave his life reporting truth. This package serves as a Sadaqah Jariyah (ongoing charity) in his honor.

A comprehensive Flutter/Dart localization solution with type-safe translations, advanced pluralization, runtime flexibility, and powerful CLI tools.

## Platform Support

| Android | iOS | Web | macOS | Windows | Linux |
|---------|-----|-----|-------|---------|-------|
| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## Features

- **Type-safe generated Dictionary** with compile-time validation
- **Runtime key lookup** for fast iteration without code generation
- **Dual access modes** - use both typed and runtime access simultaneously
- **Zero-configuration setup** with automatic dictionary detection
- **Deterministic locale fallback chain** with script/region handling
- **Advanced pluralization** including Arabic gender-aware forms
- **Built-in RTL support** with automatic text direction
- **CLI tools** for validation, ARB/CSV/JSON import/export, and statistics
- **Catalog UI** - Swift String Catalog-style translation editor
- **Regional English support** - `en_US`, `en_GB`, `en_CA`, `en_AU` overlays
- **Date/time and number formatting** with locale-specific patterns
- **Rich text support** with markdown-like formatting
- **Migration guides** from `gen_l10n` and `easy_localization`

## Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  anas_localization: ^0.1.0
```

Run:

```bash
flutter pub get
```

### 1. Create Translation Files

Create JSON files in `assets/lang/`:

**assets/lang/en.json**
```json
{
  "app_name": "My App",
  "welcome_user": "Welcome, {name}!",
  "items_count": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

**assets/lang/ar.json**
```json
{
  "app_name": "تطبيقي",
  "welcome_user": "مرحباً، {name}!",
  "items_count": {
    "one": "{count} عنصر",
    "other": "{count} عناصر"
  }
}
```

Update `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/lang/
```

### 2. Generate Dictionary

Run the code generator:

```bash
dart run anas_localization:anas update --gen
```

Or use watch mode for live updates:

```bash
dart run anas_localization:anas update --gen --watch
```

This creates `lib/generated/dictionary.dart` with type-safe accessors.

### 3. Configure Your App

**lib/main.dart**
```dart
import 'package:flutter/material.dart';
import 'package:anas_localization/anas_localization.dart';
import 'generated/dictionary.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnasLocalization(
      fallbackLocale: Locale('en'),
      assetPath: 'assets/lang',
      assetLocales: [
        Locale('en'),
        Locale('ar'),
      ],
      app: MainApp(),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AnasLocalization.of(context).locale;
    
    return MaterialApp(
      locale: locale,
      builder: (context, child) => AnasDirectionalityWrapper(
        locale: locale,
        child: child!,
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        const DictionaryLocalizationsDelegate(),
      ],
      supportedLocales: context.supportedLocales,
      home: const HomePage(),
    );
  }
}
```

### 4. Use Translations

Access translations with type-safe getters:

```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final dictionary = getDictionary();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(dictionary.appName),
      ),
      body: Column(
        children: [
          // Simple translation
          Text(dictionary.appName),
          
          // With parameters
          Text(dictionary.welcomeUser(name: 'Ahmed')),
          
          // Pluralization
          Text(dictionary.itemsCount(count: 1)),  // "1 item"
          Text(dictionary.itemsCount(count: 5)),  // "5 items"
          
          // Language selector widget
          AnasLanguageSelector(
            supportedLocales: context.supportedLocales,
          ),
        ],
      ),
    );
  }
}
```

## Runtime Lookup (No Generation)

For fast iteration during development, you can skip code generation:

```dart
// Use getString for runtime key lookup
Text(dictionary.getString('app_name'))
Text(dictionary.getStringWithParams('welcome_user', {'name': 'Ahmed'}))
```

See [Runtime Lookup Guide](doc/RUNTIME_LOOKUP_WITHOUT_GENERATION.md) for details.

## Language Switching

Built-in language switching with smooth animations:

```dart
ElevatedButton(
  onPressed: () {
    AnasLocalization.of(context).setLocale(const Locale('ar'));
  },
  child: const Text('العربية'),
)

// Or use pre-built widgets
AnasLanguageDialog(
  supportedLocales: context.supportedLocales,
  showDescription: true,
)
```

## Advanced Features

### Arabic Gender-Aware Pluralization

```json
{
  "car": {
    "one": {"male": "سيارة واحدة", "female": "سيارة واحدة"},
    "two": {"male": "سيارتان", "female": "سيارتان"},
    "few": {"male": "{count} سيارات", "female": "{count} سيارات"},
    "many": {"male": "{count} سيارة", "female": "{count} سيارة"}
  }
}
```

```dart
dictionary.car(count: 5, gender: 'male')  // "5 سيارات"
```

### CLI Tools

```bash
# Validate translations
anas validate assets/lang --profile=strict

# Import/Export ARB files
anas export assets/lang arb lib/l10n
anas import l10n.yaml assets/lang

# Translation statistics
anas stats assets/lang

# Catalog UI for visual editing
anas catalog --init
anas catalog --serve
```

### Migration Support

Migrate from existing solutions:

```bash
# From gen_l10n
anas convert --from gen_l10n --source l10n.yaml --out assets/lang

# From easy_localization
anas convert --from easy_localization

# Validate migration
anas validate-migration --from gen_l10n
```

## Documentation

- **Getting Started**: [Installation & Setup](doc/get-started/install-and-first-run.md)
- **Full Setup Guide**: [doc/SETUP_AND_USAGE.md](doc/SETUP_AND_USAGE.md)
- **Runtime Lookup**: [doc/RUNTIME_LOOKUP_WITHOUT_GENERATION.md](doc/RUNTIME_LOOKUP_WITHOUT_GENERATION.md)
- **Catalog UI**: [doc/CATALOG_UI.md](doc/CATALOG_UI.md)
- **CLI Reference**: [doc/reference/cli-reference.md](doc/reference/cli-reference.md)
- **Migration Guides**:
  - [From gen_l10n](doc/MIGRATION_GEN_L10N.md)
  - [From easy_localization](doc/MIGRATION_EASY_LOCALIZATION.md)
- **Cookbook**: [https://melsaeed276.github.io/anas_localization/](https://melsaeed276.github.io/anas_localization/)

## Why anas_localization?

| Feature | Flutter `gen_l10n` | `easy_localization` | `slang` | `anas_localization` |
|---------|-------------------|---------------------|---------|---------------------|
| Type-safe accessors | ✅ | ⚠️ | ✅ | ✅ |
| Runtime flexibility | ⚠️ | ✅ | ✅ | ✅ |
| ARB import/export | ✅ | ⚠️ | ✅ | ✅ |
| CLI validation | ❌ | ⚠️ | ✅ | ✅ |
| Module namespaces | ❌ | ❌ | ✅ | ✅ |
| Migration tools | ❌ | ⚠️ | ⚠️ | ✅ |

**anas_localization** prioritizes migration tooling, runtime flexibility, and CI-friendly validation workflows. See [detailed comparison](doc/reference/why-anas-localization.md).

## Example

See the [example](example/) directory for a complete working app demonstrating all features.

```bash
cd example
flutter pub get
flutter run
```

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security

Report security issues privately. See [SECURITY.md](SECURITY.md) for details.

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details.

Arabic translation (unofficial): [LICENSE.ar.md](LICENSE.ar.md)

## Trademark

The name "anas_localization" honors Anas Al-Sharif's legacy. Modified versions should use different names. See [TRADEMARK.md](TRADEMARK.md).

---

[![Stand With Palestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/banner-no-action.svg)](https://thebsd.github.io/StandWithPalestine)

**Remember**: This work is a Sadaqah Jariyah for Anas Al-Sharif, whose courage in journalism continues to inspire.
