# Runtime Lookup Support - Implementation Summary

## Overview

This document confirms that `anas_localization` fully supports runtime key-based localization **without generating the Dictionary class**. This allows developers to use the package immediately for rapid prototyping and quick iteration.

## Implementation Status

✅ **FULLY SUPPORTED** - Runtime lookup is a first-class feature, not an afterthought.

## Key APIs

The base `Dictionary` class provides these runtime methods:

### 1. `getString(String key, {String? fallback})`
Get a translation by key with optional fallback.

```dart
final dict = AnasLocalization.of(context).dictionary;
final appName = dict.getString('app_name');
final title = dict.getString('settings.profile.title'); // Supports dot notation
```

### 2. `getStringWithParams(String key, Map<String, dynamic> params, {String? fallback})`
Get a translation with parameter substitution.

```dart
final welcome = dict.getStringWithParams(
  'welcome_message',
  {'username': 'Ahmed'},
);
// Supports {param}, {param?}, {param!} markers
```

### 3. `hasKey(String key)`
Check if a translation key exists.

```dart
if (dict.hasKey('settings.profile.title')) {
  // Key exists
}
```

### 4. Additional Utilities
- `locale` - Get current locale string
- `toMap()` - Convert dictionary to map
- `getPluralData(String key)` - Get plural form data

## Code Location

- **Implementation**: `lib/src/features/localization/domain/entities/dictionary.dart`
- **Test Coverage**: `test/dictionary_runtime_lookup_test.dart` (41 test cases)
- **Documentation**: `doc/RUNTIME_LOOKUP_WITHOUT_GENERATION.md`

## Test Coverage Summary

The implementation is thoroughly tested with **41 test cases** covering:

### Basic getString Tests (9 tests)
- ✅ Dotted nested key paths
- ✅ Flat key behavior
- ✅ Custom fallbacks
- ✅ Missing keys
- ✅ Empty string values
- ✅ Non-string values
- ✅ Deeply nested keys
- ✅ Partial path matches

### getStringWithParams Tests (12 tests)
- ✅ Single parameter replacement
- ✅ Optional marker (`{param?}`)
- ✅ Required marker (`{param!}`)
- ✅ Multiple parameters
- ✅ Mixed markers
- ✅ Dotted keys with parameters
- ✅ Nested dotted keys with parameters
- ✅ Missing parameters
- ✅ No parameters
- ✅ Non-string value conversion
- ✅ Fallback when key not found
- ✅ Returns key when no fallback

### hasKey Tests (7 tests)
- ✅ Existing flat keys
- ✅ Existing nested keys
- ✅ Deeply nested keys
- ✅ Empty string values
- ✅ Nonexistent keys
- ✅ Partial path matches
- ✅ Invalid nested paths

### Utility Tests (3 tests)
- ✅ Locale getter
- ✅ toMap() returns copy
- ✅ toMap() preserves structure

### Integration Tests (10 tests)
- ✅ Complete app workflow without generation
- ✅ Multi-locale workflow
- ✅ Plural resolution
- ✅ Regional variants (en_US, en_GB, en_CA, en_AU)
- ✅ Shared-base overlay lookups

## Performance Characteristics

- **Simple keys**: O(1) hash lookup
- **Nested keys**: O(n) where n = nesting depth
- **Parameter substitution**: O(m) where m = number of parameters
- **No reflection**: Direct map access, no dynamic code

## Comparison: Runtime vs Generated

| Feature | Runtime Lookup | Generated Dictionary |
|---------|----------------|----------------------|
| Setup | None | Run `anas update --gen` |
| Type safety | ❌ | ✅ |
| Auto-complete | ❌ | ✅ |
| Quick iteration | ✅ Very fast | ⚠️ Need to regenerate |
| Dynamic keys | ✅ | ❌ |
| Production ready | ⚠️ Risky | ✅ Recommended |

## Usage Examples

### Quick Start (No Generation)

```dart
import 'package:anas_localization/localization.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnasLocalization(
      fallbackLocale: const Locale('en'),
      assetPath: 'assets/lang',
      assetLocales: const [Locale('en'), Locale('ar')],
      // No dictionaryFactory needed!
      app: MaterialApp(
        home: HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dict = AnasLocalization.of(context).dictionary;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(dict.getString('app_name')),
      ),
      body: Column(
        children: [
          Text(dict.getStringWithParams(
            'welcome_message',
            {'username': 'Ahmed'},
          )),
          Text(dict.getString('settings.profile.title')),
        ],
      ),
    );
  }
}
```

## Migration Path

Both approaches work simultaneously. You can:

1. **Start with runtime lookup** for rapid prototyping
2. **Generate Dictionary later** when you want type safety
3. **Use both** - runtime for dynamic keys, generated for known keys
4. **Migrate incrementally** - no breaking changes

## Documentation

- **Main README**: Updated with dual access mode highlights
- **Detailed Guide**: `doc/RUNTIME_LOOKUP_WITHOUT_GENERATION.md`
- **API Reference**: Generated dartdoc for `Dictionary` class

## Related Files Changed

1. `test/dictionary_runtime_lookup_test.dart` - Added 32 new test cases
2. `doc/RUNTIME_LOOKUP_WITHOUT_GENERATION.md` - New comprehensive guide
3. `README.md` - Updated Features section and documentation links
4. `RUNTIME_LOOKUP_SUPPORT.md` - This summary document

## Conclusion

✅ **Runtime lookup is fully implemented and tested**
✅ **Documentation is complete**
✅ **All 41 tests pass**
✅ **No breaking changes to existing API**

The package now clearly supports both:
- Type-safe generated Dictionary (recommended for production)
- Runtime key lookup (fast iteration, no generation)

Developers can choose the approach that fits their workflow, and both can be used together in the same app.
