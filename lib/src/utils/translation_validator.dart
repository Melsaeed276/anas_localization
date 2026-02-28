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
  /// Validate translation files against an explicit master file.
  ///
  /// This mode is useful for CI or tooling where one locale file is the
  /// source of truth and every other locale must follow it.
  static Future<ValidationResult> validateAgainstMaster({
    required String masterFilePath,
    required String langDirectoryPath,
    bool treatExtraKeysAsWarnings = false,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      final masterFile = File(masterFilePath);
      if (!masterFile.existsSync()) {
        errors.add('Master translation file not found: $masterFilePath');
        return ValidationResult(isValid: false, errors: errors, warnings: warnings);
      }

      final langDir = Directory(langDirectoryPath);
      if (!langDir.existsSync()) {
        errors.add('Language directory not found: $langDirectoryPath');
        return ValidationResult(isValid: false, errors: errors, warnings: warnings);
      }

      final masterMap = jsonDecode(await masterFile.readAsString()) as Map<String, dynamic>;
      final translations = <String, Map<String, dynamic>>{
        '__master__': masterMap,
      };

      final files = langDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json') && f.path != masterFile.path)
          .toList();

      if (files.isEmpty) {
        warnings.add('No additional locale files found in $langDirectoryPath');
        return ValidationResult(isValid: true, errors: errors, warnings: warnings);
      }

      for (final file in files) {
        final locale = file.uri.pathSegments.last.replaceAll('.json', '');
        try {
          final content = await file.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;
          translations[locale] = data;
        } catch (e) {
          errors.add('Failed to parse $locale.json: $e');
        }
      }

      final baseResult = _validateWithBase(
        translations,
        baseLocale: '__master__',
        treatExtraKeysAsWarnings: treatExtraKeysAsWarnings,
      );

      errors.addAll(baseResult.errors);
      warnings.addAll(baseResult.warnings);
    } catch (e) {
      errors.add('Validation failed: $e');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

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

      final baseLocale = translations.keys.contains('en') ? 'en' : translations.keys.first;
      final baseResult = _validateWithBase(
        translations,
        baseLocale: baseLocale,
        treatExtraKeysAsWarnings: true,
      );
      errors.addAll(baseResult.errors);
      warnings.addAll(baseResult.warnings);

    } catch (e) {
      errors.add('Validation failed: $e');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  static ValidationResult _validateWithBase(
    Map<String, Map<String, dynamic>> translations, {
    required String baseLocale,
    required bool treatExtraKeysAsWarnings,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    final baseMap = translations[baseLocale];
    if (baseMap == null) {
      errors.add('Base locale "$baseLocale" was not found.');
      return ValidationResult(isValid: false, errors: errors, warnings: warnings);
    }

    final baseKeys = _getAllKeys(baseMap);

    for (final entry in translations.entries) {
      if (entry.key == baseLocale) continue;

      final currentKeys = _getAllKeys(entry.value);
      final missing = baseKeys.difference(currentKeys);
      final extra = currentKeys.difference(baseKeys);

      if (missing.isNotEmpty) {
        errors.add('${entry.key}.json missing keys: ${missing.join(', ')}');
      }

      if (extra.isNotEmpty) {
        final message = '${entry.key}.json has extra keys: ${extra.join(', ')}';
        if (treatExtraKeysAsWarnings) {
          warnings.add(message);
        } else {
          errors.add(message);
        }
      }
    }

    for (final key in baseKeys) {
      final basePlaceholders = _getPlaceholders(baseMap, key);

      for (final entry in translations.entries) {
        if (entry.key == baseLocale) continue;

        final currentPlaceholders = _getPlaceholders(entry.value, key);
        if (!_setsEqual(basePlaceholders.toSet(), currentPlaceholders.toSet())) {
          errors.add(
            'Placeholder mismatch in ${entry.key}.json for key "$key": '
            'expected ${basePlaceholders.join(', ')}, found ${currentPlaceholders.join(', ')}',
          );
        }
      }
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
    final value = _getValueByPath(map, key);
    return _extractPlaceholdersFromValue(value).toList()..sort();
  }

  /// Extract placeholders from a string
  static List<String> _extractPlaceholdersFromString(String text) {
    final regex = RegExp(r'\{([a-zA-Z0-9_]+)[!?]?\}');
    return regex.allMatches(text)
        .map((match) => match.group(1)!)
        .toList();
  }

  static dynamic _getValueByPath(Map<String, dynamic> map, String path) {
    if (path.isEmpty) {
      return map;
    }

    final parts = path.split('.');
    dynamic current = map;
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  static Set<String> _extractPlaceholdersFromValue(dynamic value) {
    if (value is String) {
      return _extractPlaceholdersFromString(value).toSet();
    }

    if (value is Map) {
      final placeholders = <String>{};
      for (final nested in value.values) {
        placeholders.addAll(_extractPlaceholdersFromValue(nested));
      }
      return placeholders;
    }

    if (value is List) {
      final placeholders = <String>{};
      for (final nested in value) {
        placeholders.addAll(_extractPlaceholdersFromValue(nested));
      }
      return placeholders;
    }

    return const <String>{};
  }

  static bool _setsEqual(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final value in a) {
      if (!b.contains(value)) return false;
    }
    return true;
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
