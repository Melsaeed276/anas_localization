## In Memory of Anas Al-Sharif

| This package is dedicated to the memory of Anas Al-Sharif, a Palestinian journalist for Al Jazeera in Gaza. Anas was martyred while reporting in August 2025, courageously bringing truth to the world. This work serves as a Sadaqah Jariyah (ongoing charity) in his name, honoring his legacy and commitment to justice. | <img width="400" height="550" alt="image" src="https://github.com/user-attachments/assets/91350ed1-f1f2-4447-829c-de97288fe2d1" /> |
|---|---|


# Flutter/Dart Localization Package

This package provides a comprehensive solution for localization in Flutter and Dart applications. It supports runtime dictionary generation, JSON-based translations, pluralization, named and positional parameters, gender support (male/female only), and merging of package and app assets for seamless localization management.

## Features

- Merge app and package JSON localizations with app override.
- Runtime fallback to package localization if an app key is missing.
- Pluralization support using the `PluralForm` enum.
- Gender-specific messages supporting male and female variants.
- Named (`{name}`) and positional (`{}`) parameters with optional (`{name?}`) and required (`{name!}`) syntax.
- Support for multiple currency/localization variants inside a single key.
- Validation of variable consistency across all supported languages.

## Getting started

Add the package to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  localization_package: ^0.0.1
```

Run `flutter pub get` or `dart pub get` to install the package.

## Usage

1. Add your JSON localization files in your Flutter/Dart project assets, for example:

```
assets/lang/en.json
assets/lang/es.json
```

2. Run the localization generator:

```bash
dart run localization:localization_gen
```

3. Access your translations in code:

```dart
final dictionary = Localization.of(context);

print(dictionary.hello);
print(dictionary.itemsCount(count: 5));
```

## Advanced Usage

### Pluralization

```json
{
  "itemsCount": {
    "zero": "No items",
    "one": "One item",
    "other": "{count} items"
  }
}
```

```dart
dictionary.itemsCount(count: 3);
```

### Gender-specific messages

```json
{
  "welcome": {
    "male": "Welcome, sir!",
    "female": "Welcome, ma'am!"
  }
}
```

```dart
dictionary.welcome(gender: Gender.male);
```

### Currency and localization variants

```json
{
  "price": {
    "usd": "\${amount}",
    "eur": "€{amount}"
  }
}
```

```dart
dictionary.price(currency: 'usd', amount: 10);
```

### Named and positional parameters

```json
{
  "greeting": "Hello, {name!}!",
  "farewell": "Goodbye, {name?}."
}
```

```dart
dictionary.greeting(name: 'Alice'); // Required parameter
dictionary.farewell(); // Optional parameter
```

## Additional information

For issues, contributions, and more information, visit the GitHub repository:  
https://github.com/yourusername/localization_package

Supported locales include all those defined in your JSON assets. Note that gender support is limited to male and female only. Please ensure your JSON keys and variables are consistent across all languages to avoid runtime errors.
