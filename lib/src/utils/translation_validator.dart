/// Translation validation and testing utilities
library;

import 'dart:convert';
import 'dart:io';

/// Validation results for translation files
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Validates translation files for consistency and completeness
class TranslationValidator {
  /// Validate all translation files in a directory
  static Future<ValidationResult> validateTranslations(String langDirectory) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      final dir = Directory(langDirectory);
      if (!dir.existsSync()) {
        errors.add('Language directory not found: $langDirectory');
        return ValidationResult(isValid: false, errors: errors, warnings: warnings);
      }

      final jsonFiles = dir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      if (jsonFiles.isEmpty) {
        errors.add('No JSON translation files found in $langDirectory');
        return ValidationResult(isValid: false, errors: errors, warnings: warnings);
      }

      final translations = <String, Map<String, dynamic>>{};

      // Load all translation files
      for (final file in jsonFiles) {
        final locale = file.uri.pathSegments.last.replaceAll('.json', '');
        try {
          final content = await file.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;
          translations[locale] = data;
        } catch (e) {
          errors.add('Failed to parse $locale.json: $e');
        }
      }

      if (translations.isEmpty) {
        errors.add('No valid translation files loaded');
        return ValidationResult(isValid: false, errors: errors, warnings: warnings);
      }

      // Validate key consistency
      final baseLocale = translations.keys.contains('en') ? 'en' : translations.keys.first;
      final baseKeys = _getAllKeys(translations[baseLocale]!);

      for (final entry in translations.entries) {
        if (entry.key == baseLocale) continue;

        final currentKeys = _getAllKeys(entry.value);
        final missing = baseKeys.difference(currentKeys);
        final extra = currentKeys.difference(baseKeys);

        if (missing.isNotEmpty) {
          errors.add('${entry.key}.json missing keys: ${missing.join(', ')}');
        }

        if (extra.isNotEmpty) {
          warnings.add('${entry.key}.json has extra keys: ${extra.join(', ')}');
        }
      }

      // Validate placeholder consistency
      for (final key in baseKeys) {
        final basePlaceholders = _getPlaceholders(translations[baseLocale]!, key);

        for (final entry in translations.entries) {
          if (entry.key == baseLocale) continue;

          final currentPlaceholders = _getPlaceholders(entry.value, key);
          if (basePlaceholders.toSet() != currentPlaceholders.toSet()) {
            errors.add('Placeholder mismatch in ${entry.key}.json for key "$key": expected ${basePlaceholders.join(', ')}, found ${currentPlaceholders.join(', ')}');
          }
        }
      }

    } catch (e) {
      errors.add('Validation failed: $e');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Get all keys from a translation map (including nested keys)
  static Set<String> _getAllKeys(Map<String, dynamic> map, [String prefix = '']) {
    final keys = <String>{};

    for (final entry in map.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      keys.add(key);

      if (entry.value is Map<String, dynamic>) {
        keys.addAll(_getAllKeys(entry.value as Map<String, dynamic>, key));
      }
    }

    return keys;
  }

  /// Extract placeholders from a translation value
  static List<String> _getPlaceholders(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String) {
      return _extractPlaceholdersFromString(value);
    } else if (value is Map) {
      final placeholders = <String>{};
      for (final v in value.values) {
        if (v is String) {
          placeholders.addAll(_extractPlaceholdersFromString(v));
        }
      }
      return placeholders.toList();
    }
    return [];
  }

  /// Extract placeholders from a string
  static List<String> _extractPlaceholdersFromString(String text) {
    final regex = RegExp(r'\{([a-zA-Z0-9_]+)[!?]?\}');
    return regex.allMatches(text)
        .map((match) => match.group(1)!)
        .toList();
  }
}

/// Test utilities for localization
class LocalizationTestHelper {
  /// Create a test dictionary with fake data
  static Map<String, dynamic> createTestTranslations() {
    return {
      'app_name': 'Test App',
      'welcome': 'Welcome',
      'welcome_user': 'Welcome, {name}!',
      'car': {
        'one': 'Car',
        'other': '{count} Cars',
      },
    };
  }

  /// Verify that all translation keys have corresponding test data
  static bool verifyTestCoverage(Map<String, dynamic> translations, Set<String> requiredKeys) {
    final availableKeys = TranslationValidator._getAllKeys(translations);
    final missing = requiredKeys.difference(availableKeys);
    return missing.isEmpty;
  }
}
