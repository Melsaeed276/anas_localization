# Anas Localization Example

A Flutter app demonstrating the `anas_localization` package capabilities with type-safe translations, RTL support, pluralization, and more.

## Features Demo

This example showcases:

- **Type-safe Dictionary access** - Generated code provides compile-time verified translations
- **Runtime key lookup** - Fallback to string keys when needed
- **Pluralization** - Smart plural forms for English, Arabic, Turkish
- **RTL Support** - Automatic right-to-left layout for Arabic
- **Parameter substitution** - Dynamic values in translations
- **Language switching** - Built-in widgets for locale changes

## Running the Example

```bash
# Navigate to example directory
cd example

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## Project Structure

```
example/
├── lib/
│   ├── main.dart              # App entry point with AnasLocalization
│   ├── pages/
│   │   └── features_page.dart # Feature demonstration page
│   ├── widgets/
│   │   └── language_selector.dart
│   └── generated/
│       └── dictionary.dart    # Generated type-safe translations
└── assets/
    └── lang/
        ├── en.json            # English translations
        ├── ar.json            # Arabic translations
        └── tr.json            # Turkish translations
```

## Quick Start in Your Own App

### 1. Add Dependency

```yaml
# pubspec.yaml
dependencies:
  anas_localization: ^0.1.0
```

### 2. Create Translation Files

```json
// assets/lang/en.json
{
  "app_name": "My App",
  "welcome_user": "Welcome, {name}!",
  "items_count": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

### 3. Generate Dictionary

```bash
dart run anas_localization:anas update --gen
```

### 4. Configure Your App

```dart
import 'package:anas_localization/anas_localization.dart';
import 'generated/dictionary.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnasLocalization(
      fallbackLocale: const Locale('en'),
      assetPath: 'assets/lang',
      assetLocales: const [Locale('en'), Locale('ar')],
      app: MaterialApp(
        locale: AnasLocalization.of(context).locale,
        // ...
      ),
    );
  }
}
```

### 5. Use Translations

```dart
final dictionary = getDictionary();

// Simple translation
Text(dictionary.appName);

// With parameters
Text(dictionary.welcomeUser(name: 'Ahmed'));

// Pluralization
Text(dictionary.itemsCount(count: 5));
```

## Documentation

- [Main Package README](../README.md)
- [Full Setup Guide](../doc/SETUP_AND_USAGE.md)
- [Migration from Other Packages](../doc/MIGRATION_GEN_L10N.md)

## License

Apache License 2.0 - See ../LICENSE for details.
