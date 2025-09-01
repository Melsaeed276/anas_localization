## In Memory of Anas Al-Sharif [![StandWithPalestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/badges/StandWithPalestine.svg)](https://github.com/TheBSD/StandWithPalestine/blob/main/docs/README.md)



<img width="400" height="550" alt="image" src="https://github.com/user-attachments/assets/91350ed1-f1f2-4447-829c-de97288fe2d1" /> 
This package is dedicated to the memory of Anas Al-Sharif, a Palestinian journalist for Al Jazeera in Gaza. Anas was martyred while reporting in August 2025, courageously bringing truth to the world. This work serves as a Sadaqah Jariyah (ongoing charity) in his name, honoring his legacy and commitment to justice.


# Flutter/Dart Localization Package

This package provides a comprehensive solution for localization in Flutter and Dart applications. It supports runtime dictionary generation, JSON-based translations, pluralization, named and positional parameters, gender support (male/female only), Arabic gender-aware pluralization, and merging of package and app assets for seamless localization management.

## Features

- **Dictionary Factory Input**: Apps provide their generated Dictionary class directly to AnasLocalization
- **No State Management Required**: Built-in state management handles locale changes automatically
- **Merge app and package JSON localizations** with app override
- **Runtime fallback** to package localization if an app key is missing
- **Advanced Pluralization support** including Arabic gender-aware pluralization
- **Gender-specific messages** supporting male and female variants
- **Named parameters** with optional (`{name?}`) and required (`{name!}`) syntax
- **Placeholder markers** for flexible parameter handling
- **Arabic linguistic support** with proper count-based and gender-based pluralization
- **Keyword safety** - automatically converts Dart reserved words (e.g., `continue` → `continueText`)
- **Multi-language consistency validation** across all supported languages
- **Type-safe access** to translations through generated getters

## Getting started

Add the package to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  anas_localization: ^0.0.1
```

Run `flutter pub get` to install the package.

## Setup

1. **Create your JSON localization files** in your Flutter project:

```
assets/lang/en.json
assets/lang/ar.json
assets/lang/tr.json
```

2. **Generate the Dictionary class**:

```bash
dart run anas_localization:localization_gen
```

3. **Configure your app** with the generated Dictionary:

```dart
import 'package:anas_localization/localization.dart';
import 'generated/dictionary.dart' as app_dictionary;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnasLocalization(
      fallbackLocale: const Locale('en'),
      assetLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('tr'),
      ],
      dictionaryFactory: (Map<String, dynamic> map, {required String locale}) {
        return app_dictionary.Dictionary.fromMap(map, locale: locale);
      },
      app: MaterialApp(
        // your app configuration
      ),
    );
  }
}
```

## Usage

### Basic Translation Access

```dart
final dict = AnasLocalization.of(context).dictionary as YourAppDictionary;

// Simple string access
Text(dict.appName)
Text(dict.welcome)

// With parameters
Text(dict.welcomeUser(name: 'Ahmed'))
```

### Placeholder Markers

Support for optional and required parameter markers:

```json
{
  "greeting": "Hello, {name!}!",
  "farewell": "Goodbye, {name?}.",
  "money": "{name?} has {amount} {currency}"
}
```

- `{name!}` - Required parameter (generates `required String name`)
- `{name?}` - Optional parameter (generates `String? name`)  
- `{name}` - Default required parameter

```dart
dict.greeting(name: 'Alice')  // Required parameter
dict.farewell(name: 'Bob')    // Optional parameter  
dict.money(name: 'John', amount: '500', currency: 'USD')
```

### Simple Pluralization

```json
{
  "car": {
    "one": "Car",
    "more": "{count} Cars"
  }
}
```

```dart
dict.car(count: 1)  // "Car"
dict.car(count: 5)  // "5 Cars"
```

### Arabic Gender-Aware Pluralization

Full support for Arabic linguistic rules with gender variations:

```json
{
  "car": {
    "one": {
      "male": "سيارة واحدة",
      "female": "سيارة واحدة"
    },
    "two": {
      "male": "سيارتان", 
      "female": "سيارتان"
    },
    "few": {
      "male": "{count} سيارات",
      "female": "{count} سيارات"
    },
    "many": {
      "male": "{count} سيارة",
      "female": "{count} سيارة"
    }
  }
}
```

```dart
// Arabic pluralization with gender support
dict.car(count: 1, gender: 'male')    // "سيارة واحدة"
dict.car(count: 2, gender: 'female')  // "سيارتان" 
dict.car(count: 5, gender: 'male')    // "5 سيارات"

// Works for other languages too (ignores gender parameter)
dict.car(count: 1)  // "Car" (English), "Araba" (Turkish)
dict.car(count: 5)  // "Cars" (English), "Arabalar" (Turkish)
```

### Arabic Pluralization Rules

The system automatically applies proper Arabic pluralization rules:

- `count == 0` → "zero" form
- `count == 1` → "one" form  
- `count == 2` → "two" form
- `count >= 3 && count <= 10` → "few" form
- `count >= 11` → "many" form
- Fallback → "other" form

Each form can have both "male" and "female" variants for complete Arabic linguistic support.

### Standard Pluralization (ICU Format)

```json
{
  "items": {
    "zero": "No items",
    "one": "One item", 
    "two": "Two items",
    "few": "A few items",
    "many": "Many items",
    "other": "{count} items"
  }
}
```

### Keyword Safety

The system automatically handles Dart reserved keywords:

```json
{
  "continue": "Continue"
}
```

Generates:
```dart
String get continueText => getString('continue');  // Safe identifier
```

## Advanced Usage

### Built-in State Management

The localization system includes built-in state management, so you don't need to use any external state management solutions like Provider, Bloc, or Riverpod for localization:

```dart
// No additional state management needed!
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnasLocalization(
      // Built-in state management handles everything automatically
      fallbackLocale: const Locale('en'),
      assetLocales: const [Locale('ar'), Locale('en'), Locale('tr')],
      dictionaryFactory: (map, {required locale}) => Dictionary.fromMap(map, locale: locale),
      app: MaterialApp(
        // The entire app automatically rebuilds when locale changes
        locale: AnasLocalization.of(context).locale,
        home: HomePage(),
      ),
    );
  }
}

// Change language from anywhere in your app
class LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Built-in state management handles the locale change
        AnasLocalization.of(context).setLocale(Locale('ar'));
        // Entire app automatically rebuilds with new language
      },
      child: Text('Switch to Arabic'),
    );
  }
}
```

**What's handled automatically:**
- ✅ Locale state management and persistence
- ✅ Dictionary loading and caching
- ✅ Widget tree rebuilding on locale changes
- ✅ Fallback locale handling
- ✅ Asset loading and error handling
- ✅ Memory management and cleanup

### Multi-language Consistency

The generator validates that all languages have consistent:
- Key structures (all languages must have the same keys)
- Parameter placeholders (same parameters across languages)  
- Type consistency (String vs Map structures must match)

### Package + App Asset Merging

- Package provides base translations
- Apps can override specific keys
- Runtime fallback to package translations for missing app keys

## File Structure

```
your_app/
├── assets/lang/
│   ├── en.json      # App-specific English translations
│   ├── ar.json      # App-specific Arabic translations  
│   └── tr.json      # App-specific Turkish translations
├── lib/generated/
│   └── dictionary.dart  # Generated Dictionary class
└── lib/main.dart
```

## Migration from Setup Function

**Old approach** (deprecated):
```dart
void main() {
  dictionary_file.setupDictionary(); // No longer needed
  runApp(MyApp());
}
```

**New approach** (recommended):
```dart
void main() {
  runApp(MyApp()); // Dictionary factory passed directly to AnasLocalization
}
```

## Additional Information

For issues, contributions, and more information, visit the GitHub repository:  
https://github.com/Melsaeed276/enis_localization/issues

**Language Support**: All locales defined in your JSON assets are supported, with special enhanced support for Arabic including gender-aware pluralization.

**Gender Support**: Currently supports male and female variants, with plans for expanded gender support.

**Validation**: Automatic validation ensures JSON keys and variables are consistent across all languages to prevent runtime errors.

# Remember
[![Stand With Palestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/banner-no-action.svg)](https://thebsd.github.io/StandWithPalestine)
