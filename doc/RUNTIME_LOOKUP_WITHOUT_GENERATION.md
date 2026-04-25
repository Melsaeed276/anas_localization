# Runtime Lookup Without Code Generation

This guide shows how to use `anas_localization` for quick iteration and prototyping **without** generating the Dictionary class.

## Overview

The package supports **two access modes**:

1. **Type-safe generated Dictionary** (recommended for production)
2. **Runtime key lookup** (fast iteration, no code generation required)

This document covers **Runtime key lookup** for scenarios where you want to skip code generation.

## When to Use Runtime Lookup

✅ **Good for:**
- Rapid prototyping and experimentation
- Quick demos or proof-of-concepts
- Testing translation files before committing to generated code
- Dynamic key construction at runtime
- Learning the package without CLI setup

❌ **Not recommended for:**
- Production applications (use generated Dictionary for type safety)
- Large codebases (auto-complete and compile-time checks are valuable)
- Team projects (typed APIs prevent typos and improve maintainability)

## Setup

### 1. Create Translation Files

Create your JSON translation files as usual:

```json
// assets/lang/en.json
{
  "app_name": "My App",
  "welcome_message": "Welcome, {username}!",
  "item_count": "{count} items in cart",
  "settings": {
    "title": "Settings",
    "profile": {
      "title": "Profile Settings"
    }
  }
}
```

```json
// assets/lang/ar.json
{
  "app_name": "تطبيقي",
  "welcome_message": "مرحباً، {username}!",
  "item_count": "{count} عناصر في السلة",
  "settings": {
    "title": "الإعدادات",
    "profile": {
      "title": "إعدادات الملف الشخصي"
    }
  }
}
```

### 2. Configure AnasLocalization

**Skip the dictionary generation step** and configure `AnasLocalization` without a `dictionaryFactory`:

```dart
import 'package:anas_localization/localization.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnasLocalization(
      fallbackLocale: const Locale('en'),
      assetPath: 'assets/lang',
      assetLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      // No dictionaryFactory needed!
      app: MaterialApp(
        locale: AnasLocalization.of(context).locale,
        home: HomePage(),
      ),
    );
  }
}
```

## Runtime Lookup APIs

The base `Dictionary` class provides these runtime methods:

### getString(String key, {String? fallback})

Get a translation by key with optional fallback.

```dart
final dict = AnasLocalization.of(context).dictionary;

// Simple key lookup
final appName = dict.getString('app_name');
print(appName); // "My App"

// Nested key with dot notation
final title = dict.getString('settings.profile.title');
print(title); // "Profile Settings"

// With fallback
final missing = dict.getString('nonexistent', fallback: 'Not found');
print(missing); // "Not found"

// Without fallback returns the key itself
final alsoMissing = dict.getString('another_missing');
print(alsoMissing); // "another_missing"
```

### getStringWithParams(String key, Map<String, dynamic> params, {String? fallback})

Get a translation with parameter substitution.

```dart
final dict = AnasLocalization.of(context).dictionary;

// Single parameter
final welcome = dict.getStringWithParams(
  'welcome_message',
  {'username': 'Ahmed'},
);
print(welcome); // "Welcome, Ahmed!"

// Multiple parameters
final itemCount = dict.getStringWithParams(
  'item_count',
  {'count': '5'},
);
print(itemCount); // "5 items in cart"

// Nested keys with parameters
final description = dict.getStringWithParams(
  'settings.profile.description',
  {'appName': 'My App'},
);
```

**Supported parameter markers:**

- `{name}` - Regular parameter
- `{name?}` - Optional parameter marker
- `{name!}` - Required parameter marker

All markers work the same with `getStringWithParams`.

### hasKey(String key)

Check if a translation key exists.

```dart
final dict = AnasLocalization.of(context).dictionary;

if (dict.hasKey('settings.profile.title')) {
  print('Key exists');
}

if (!dict.hasKey('missing.key')) {
  print('Key does not exist');
}
```

### Other Utility Methods

```dart
// Get current locale
final locale = dict.locale; // "en", "ar", etc.

// Convert to map
final Map<String, dynamic> map = dict.toMap();

// Get plural data (for advanced use cases)
final pluralData = dict.getPluralData('items');
```

## Complete Example

Here's a complete example of a Flutter app using only runtime lookup:

```dart
import 'package:flutter/material.dart';
import 'package:anas_localization/localization.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnasLocalization(
      fallbackLocale: const Locale('en'),
      assetPath: 'assets/lang',
      assetLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('tr'),
      ],
      app: MaterialApp(
        title: 'Runtime Lookup Demo',
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get dictionary instance
    final dict = AnasLocalization.of(context).dictionary;

    return Scaffold(
      appBar: AppBar(
        title: Text(dict.getString('app_name')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simple string
            Text(
              dict.getStringWithParams(
                'welcome_message',
                {'username': 'Ahmed'},
              ),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),

            // Nested key
            Text(dict.getString('settings.title')),
            Text(dict.getString('settings.profile.title')),
            const SizedBox(height: 16),

            // With parameters
            Text(
              dict.getStringWithParams(
                'item_count',
                {'count': '5'},
              ),
            ),
            const SizedBox(height: 32),

            // Language switcher
            ElevatedButton(
              onPressed: () {
                final currentLocale = AnasLocalization.of(context).locale;
                final newLocale = currentLocale.languageCode == 'en'
                    ? const Locale('ar')
                    : const Locale('en');
                AnasLocalization.of(context).setLocale(newLocale);
              },
              child: Text(dict.getString('switch_language')),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Best Practices

### 1. Use Constants for Keys

Avoid typos by defining key constants:

```dart
class TranslationKeys {
  static const appName = 'app_name';
  static const welcomeMessage = 'welcome_message';
  static const settingsTitle = 'settings.title';
}

// Usage
final title = dict.getString(TranslationKeys.appName);
```

### 2. Create Helper Extensions

Make the API more ergonomic:

```dart
extension DictionaryHelpers on BuildContext {
  Dictionary get tr => AnasLocalization.of(this).dictionary;
}

// Usage
Text(context.tr.getString('app_name'))
```

### 3. Handle Missing Keys Gracefully

Always provide fallbacks in production:

```dart
final text = dict.getString(
  'some.key',
  fallback: 'Default text',
);
```

### 4. Validate Keys During Development

Add assertions to catch typos early:

```dart
assert(
  dict.hasKey('app_name'),
  'Missing translation key: app_name',
);
```

## Migration Path

When you're ready to add type safety, generate the Dictionary:

```bash
# Generate typed dictionary
anas update --gen

# Or with watch mode
anas update --gen --watch
```

Then update your code to use the generated accessors:

```dart
// Before (runtime lookup)
final text = dict.getString('app_name');

// After (generated)
final text = dict.appName;
```

Both approaches work simultaneously, so you can migrate incrementally.

## Comparison: Runtime vs Generated

| Feature | Runtime Lookup | Generated Dictionary |
|---------|----------------|----------------------|
| Setup | None | Run `anas update --gen` |
| Type safety | ❌ No | ✅ Yes |
| Auto-complete | ❌ No | ✅ Yes |
| Compile-time checks | ❌ No | ✅ Yes |
| Refactoring support | ❌ No | ✅ Yes |
| Quick iteration | ✅ Very fast | ⚠️ Need to regenerate |
| Dynamic keys | ✅ Yes | ❌ No |
| Learning curve | ✅ Simple | ⚠️ Moderate |
| Production ready | ⚠️ Risky | ✅ Recommended |

## Performance

Runtime lookup performance is excellent:

- **Simple keys**: O(1) hash lookup
- **Nested keys** (dot notation): O(n) where n = nesting depth
- **Parameter substitution**: O(m) where m = number of parameters
- **No reflection** or dynamic code

The performance difference between runtime and generated approaches is negligible for typical apps.

## Troubleshooting

### Key Not Found

```dart
// Problem: Returns key instead of translation
final text = dict.getString('missing_key'); // "missing_key"

// Solution 1: Check the key exists
if (dict.hasKey('missing_key')) {
  final text = dict.getString('missing_key');
}

// Solution 2: Use fallback
final text = dict.getString('missing_key', fallback: 'Default');
```

### Parameters Not Replaced

```dart
// Problem: {username} not replaced
final text = dict.getString('welcome_message'); // "Welcome, {username}!"

// Solution: Use getStringWithParams
final text = dict.getStringWithParams(
  'welcome_message',
  {'username': 'Ahmed'},
); // "Welcome, Ahmed!"
```

### Nested Key Not Resolved

```dart
// Problem: Nested key returns the key
final text = dict.getString('settings.profile.title'); // "settings.profile.title"

// Solution: Check JSON structure
// Make sure JSON has: {"settings": {"profile": {"title": "..."}}}
```

## See Also

- [Setup and Usage Guide](SETUP_AND_USAGE.md) - Full package setup
- [Catalog UI Guide](CATALOG_UI.md) - Visual translation editor
- [Migration from gen_l10n](MIGRATION_GEN_L10N.md) - Migrate from Flutter's official i18n
- [Migration from easy_localization](MIGRATION_EASY_LOCALIZATION.md) - Migrate from easy_localization
