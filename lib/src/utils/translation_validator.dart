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

enum ValidationProfile {
  strict,
  balanced,
  lenient,
}

class ValidationRuleToggles {
  const ValidationRuleToggles({
    this.checkMissingKeys = true,
    this.checkExtraKeys = true,
    this.checkPlaceholders = true,
    this.checkPluralForms = true,
    this.checkGenderForms = true,
  });

  final bool checkMissingKeys;
  final bool checkExtraKeys;
  final bool checkPlaceholders;
  final bool checkPluralForms;
  final bool checkGenderForms;

  ValidationRuleToggles copyWith({
    bool? checkMissingKeys,
    bool? checkExtraKeys,
    bool? checkPlaceholders,
    bool? checkPluralForms,
    bool? checkGenderForms,
  }) {
    return ValidationRuleToggles(
      checkMissingKeys: checkMissingKeys ?? this.checkMissingKeys,
      checkExtraKeys: checkExtraKeys ?? this.checkExtraKeys,
      checkPlaceholders: checkPlaceholders ?? this.checkPlaceholders,
      checkPluralForms: checkPluralForms ?? this.checkPluralForms,
      checkGenderForms: checkGenderForms ?? this.checkGenderForms,
    );
  }
}

class ValidationOptions {
  const ValidationOptions({
    required this.profile,
    required this.ruleToggles,
    required this.treatExtraKeysAsWarnings,
    required this.failOnWarnings,
  });

  factory ValidationOptions.forProfile(
    ValidationProfile profile, {
    ValidationRuleToggles? overrideRules,
    bool? treatExtraKeysAsWarnings,
    bool? failOnWarnings,
  }) {
    final defaults = switch (profile) {
      ValidationProfile.strict => const ValidationOptions(
          profile: ValidationProfile.strict,
          ruleToggles: ValidationRuleToggles(),
          treatExtraKeysAsWarnings: false,
          failOnWarnings: true,
        ),
      ValidationProfile.balanced => const ValidationOptions(
          profile: ValidationProfile.balanced,
          ruleToggles: ValidationRuleToggles(),
          treatExtraKeysAsWarnings: true,
          failOnWarnings: false,
        ),
      ValidationProfile.lenient => const ValidationOptions(
          profile: ValidationProfile.lenient,
          ruleToggles: ValidationRuleToggles(
            checkMissingKeys: true,
            checkExtraKeys: true,
            checkPlaceholders: false,
            checkPluralForms: false,
            checkGenderForms: false,
          ),
          treatExtraKeysAsWarnings: true,
          failOnWarnings: false,
        ),
    };

    final toggles = overrideRules == null
        ? defaults.ruleToggles
        : defaults.ruleToggles.copyWith(
            checkMissingKeys: overrideRules.checkMissingKeys,
            checkExtraKeys: overrideRules.checkExtraKeys,
            checkPlaceholders: overrideRules.checkPlaceholders,
            checkPluralForms: overrideRules.checkPluralForms,
            checkGenderForms: overrideRules.checkGenderForms,
          );

    return ValidationOptions(
      profile: profile,
      ruleToggles: toggles,
      treatExtraKeysAsWarnings: treatExtraKeysAsWarnings ?? defaults.treatExtraKeysAsWarnings,
      failOnWarnings: failOnWarnings ?? defaults.failOnWarnings,
    );
  }

  factory ValidationOptions.compatibility({
    required bool treatExtraKeysAsWarnings,
  }) {
    return ValidationOptions.forProfile(
      ValidationProfile.balanced,
      treatExtraKeysAsWarnings: treatExtraKeysAsWarnings,
    );
  }

  final ValidationProfile profile;
  final ValidationRuleToggles ruleToggles;
  final bool treatExtraKeysAsWarnings;
  final bool failOnWarnings;
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
    bool? treatExtraKeysAsWarnings,
    ValidationProfile profile = ValidationProfile.strict,
    ValidationRuleToggles? ruleToggles,
    bool? failOnWarnings,
  }) async {
    final options = ValidationOptions.forProfile(
      profile,
      overrideRules: ruleToggles,
      treatExtraKeysAsWarnings: treatExtraKeysAsWarnings,
      failOnWarnings: failOnWarnings,
    );

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
        return ValidationResult(isValid: _isValid(errors, warnings, options), errors: errors, warnings: warnings);
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
        options: options,
      );
      errors.addAll(baseResult.errors);
      warnings.addAll(baseResult.warnings);
    } catch (e) {
      errors.add('Validation failed: $e');
    }

    return ValidationResult(
      isValid: _isValid(errors, warnings, options),
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate all translation files in a directory.
  ///
  /// Defaults to [ValidationProfile.balanced].
  static Future<ValidationResult> validateTranslations(
    String langDirectory, {
    bool? treatExtraKeysAsWarnings,
    ValidationProfile profile = ValidationProfile.balanced,
    ValidationRuleToggles? ruleToggles,
    bool? failOnWarnings,
  }) async {
    final options = ValidationOptions.forProfile(
      profile,
      overrideRules: ruleToggles,
      treatExtraKeysAsWarnings: treatExtraKeysAsWarnings,
      failOnWarnings: failOnWarnings,
    );

    final errors = <String>[];
    final warnings = <String>[];

    try {
      final dir = Directory(langDirectory);
      if (!dir.existsSync()) {
        errors.add('Language directory not found: $langDirectory');
        return ValidationResult(isValid: false, errors: errors, warnings: warnings);
      }

      final jsonFiles = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();

      if (jsonFiles.isEmpty) {
        errors.add('No JSON translation files found in $langDirectory');
        return ValidationResult(isValid: false, errors: errors, warnings: warnings);
      }

      final translations = <String, Map<String, dynamic>>{};
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
        options: options,
      );
      errors.addAll(baseResult.errors);
      warnings.addAll(baseResult.warnings);
    } catch (e) {
      errors.add('Validation failed: $e');
    }

    return ValidationResult(
      isValid: _isValid(errors, warnings, options),
      errors: errors,
      warnings: warnings,
    );
  }

  static bool _isValid(
    List<String> errors,
    List<String> warnings,
    ValidationOptions options,
  ) {
    if (errors.isNotEmpty) return false;
    if (options.failOnWarnings && warnings.isNotEmpty) return false;
    return true;
  }

  static ValidationResult _validateWithBase(
    Map<String, Map<String, dynamic>> translations, {
    required String baseLocale,
    required ValidationOptions options,
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

      if (options.ruleToggles.checkMissingKeys && missing.isNotEmpty) {
        errors.add('${entry.key}.json missing keys: ${missing.join(', ')}');
      }

      if (options.ruleToggles.checkExtraKeys && extra.isNotEmpty) {
        final message = '${entry.key}.json has extra keys: ${extra.join(', ')}';
        if (options.treatExtraKeysAsWarnings) {
          warnings.add(message);
        } else {
          errors.add(message);
        }
      }
    }

    for (final key in baseKeys) {
      final baseValue = _getValueByPath(baseMap, key);

      for (final entry in translations.entries) {
        if (entry.key == baseLocale) continue;
        final currentValue = _getValueByPath(entry.value, key);
        if (currentValue == null) continue;

        if (options.ruleToggles.checkPlaceholders) {
          final basePlaceholders = _extractPlaceholdersFromValue(baseValue);
          final currentPlaceholders = _extractPlaceholdersFromValue(currentValue);
          if (!_setsEqual(basePlaceholders, currentPlaceholders)) {
            errors.add(
              'Placeholder mismatch in ${entry.key}.json for key "$key": '
              'expected ${basePlaceholders.toList()..sort()}, '
              'found ${currentPlaceholders.toList()..sort()}',
            );
          }
        }

        if (options.ruleToggles.checkPluralForms) {
          _validatePluralForms(
            baseValue: baseValue,
            currentValue: currentValue,
            locale: entry.key,
            keyPath: key,
            errors: errors,
          );
        }

        if (options.ruleToggles.checkGenderForms) {
          _validateGenderForms(
            baseValue: baseValue,
            currentValue: currentValue,
            locale: entry.key,
            keyPath: key,
            errors: errors,
          );
        }
      }
    }

    return ValidationResult(
      isValid: _isValid(errors, warnings, options),
      errors: errors,
      warnings: warnings,
    );
  }

  static void _validatePluralForms({
    required dynamic baseValue,
    required dynamic currentValue,
    required String locale,
    required String keyPath,
    required List<String> errors,
  }) {
    if (baseValue is! Map<String, dynamic> || currentValue is! Map<String, dynamic>) {
      return;
    }

    final basePluralForms = _extractPluralForms(baseValue);
    final currentPluralForms = _extractPluralForms(currentValue);
    if (basePluralForms.isEmpty || currentPluralForms.isEmpty) {
      return;
    }

    final missingForms = basePluralForms.difference(currentPluralForms);
    if (missingForms.isNotEmpty) {
      errors.add(
        'Plural forms mismatch in $locale.json for key "$keyPath": '
        'missing ${missingForms.toList()..sort()}',
      );
    }
  }

  static void _validateGenderForms({
    required dynamic baseValue,
    required dynamic currentValue,
    required String locale,
    required String keyPath,
    required List<String> errors,
  }) {
    final baseGenderForms = _extractGenderForms(baseValue);
    if (baseGenderForms.isEmpty) {
      return;
    }

    final currentGenderForms = _extractGenderForms(currentValue);
    final missingForms = baseGenderForms.difference(currentGenderForms);
    if (missingForms.isNotEmpty) {
      errors.add(
        'Gender forms mismatch in $locale.json for key "$keyPath": '
        'missing ${missingForms.toList()..sort()}',
      );
    }
  }

  static Set<String> _extractPluralForms(Map<String, dynamic> map) {
    const pluralForms = {'zero', 'one', 'two', 'few', 'many', 'other', 'more'};
    return map.keys.where(pluralForms.contains).toSet();
  }

  static Set<String> _extractGenderForms(dynamic value) {
    final forms = <String>{};
    _collectGenderForms(value, forms);
    return forms;
  }

  static void _collectGenderForms(dynamic value, Set<String> output) {
    if (value is Map<String, dynamic>) {
      const genderForms = {'male', 'female'};
      output.addAll(value.keys.where(genderForms.contains));
      for (final nested in value.values) {
        _collectGenderForms(nested, output);
      }
    }
    if (value is List) {
      for (final nested in value) {
        _collectGenderForms(nested, output);
      }
    }
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

  static List<String> _extractPlaceholdersFromString(String text) {
    final regex = RegExp(r'\{([a-zA-Z0-9_]+)[!?]?\}');
    return regex.allMatches(text).map((match) => match.group(1)!).toList();
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
