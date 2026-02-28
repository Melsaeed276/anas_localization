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
    this.checkPlaceholderSchema = true,
    this.checkPluralForms = true,
    this.checkGenderForms = true,
  });

  final bool checkMissingKeys;
  final bool checkExtraKeys;
  final bool checkPlaceholders;
  final bool checkPlaceholderSchema;
  final bool checkPluralForms;
  final bool checkGenderForms;

  ValidationRuleToggles copyWith({
    bool? checkMissingKeys,
    bool? checkExtraKeys,
    bool? checkPlaceholders,
    bool? checkPlaceholderSchema,
    bool? checkPluralForms,
    bool? checkGenderForms,
  }) {
    return ValidationRuleToggles(
      checkMissingKeys: checkMissingKeys ?? this.checkMissingKeys,
      checkExtraKeys: checkExtraKeys ?? this.checkExtraKeys,
      checkPlaceholders: checkPlaceholders ?? this.checkPlaceholders,
      checkPlaceholderSchema: checkPlaceholderSchema ?? this.checkPlaceholderSchema,
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
            checkPlaceholderSchema: false,
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
            checkPlaceholderSchema: overrideRules.checkPlaceholderSchema,
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

class _PlaceholderSchema {
  const _PlaceholderSchema({
    this.type,
    this.required,
    this.format,
    this.allowedValues,
  });

  final String? type;
  final bool? required;
  final String? format;
  final Set<String>? allowedValues;

  _PlaceholderSchema mergeWith(_PlaceholderSchema override) {
    return _PlaceholderSchema(
      type: override.type ?? type,
      required: override.required ?? required,
      format: override.format ?? format,
      allowedValues: override.allowedValues ?? allowedValues,
    );
  }

  String? get normalizedType => type?.trim().toLowerCase();
  String? get normalizedFormat => format?.trim().toLowerCase();
  Set<String>? get normalizedAllowedValues => allowedValues?.map((value) => value.trim().toLowerCase()).toSet();
}

class _SchemaSidecar {
  const _SchemaSidecar({
    this.defaultSchemas = const <String, Map<String, _PlaceholderSchema>>{},
    this.localeSchemas = const <String, Map<String, Map<String, _PlaceholderSchema>>>{},
  });

  final Map<String, Map<String, _PlaceholderSchema>> defaultSchemas;
  final Map<String, Map<String, Map<String, _PlaceholderSchema>>> localeSchemas;
}

class _LocaleValidationData {
  const _LocaleValidationData({
    required this.locale,
    required this.translations,
    required this.placeholderSchemasByKey,
  });

  final String locale;
  final Map<String, dynamic> translations;
  final Map<String, Map<String, _PlaceholderSchema>> placeholderSchemasByKey;
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
    String? schemaFilePath,
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
      final schemaSidecar = await _loadSchemaSidecar(
        schemaFilePath: schemaFilePath,
        errors: errors,
      );
      if (errors.isNotEmpty) {
        return ValidationResult(isValid: false, errors: errors, warnings: warnings);
      }

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

      final masterLocaleData = await _loadLocaleValidationData(
        masterFile,
        forcedLocale: '__master__',
      );
      final translations = <String, Map<String, dynamic>>{
        '__master__': masterLocaleData.translations,
      };
      final schemasByLocale = <String, Map<String, Map<String, _PlaceholderSchema>>>{
        '__master__': masterLocaleData.placeholderSchemasByKey,
      };

      final files = langDir
          .listSync()
          .whereType<File>()
          .where((f) => _isTranslationFile(f.path) && f.path != masterFile.path)
          .toList();

      if (files.isEmpty) {
        warnings.add('No additional locale files found in $langDirectoryPath');
        return ValidationResult(isValid: _isValid(errors, warnings, options), errors: errors, warnings: warnings);
      }

      for (final file in files) {
        try {
          final localeData = await _loadLocaleValidationData(file);
          translations[localeData.locale] = localeData.translations;
          schemasByLocale[localeData.locale] = localeData.placeholderSchemasByKey;
        } catch (e) {
          final fileName = file.uri.pathSegments.last;
          errors.add('Failed to parse $fileName: $e');
        }
      }

      final baseResult = _validateWithBase(
        translations,
        baseLocale: '__master__',
        options: options,
        schemasByLocale: schemasByLocale,
        schemaSidecar: schemaSidecar,
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
    String? schemaFilePath,
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
      final schemaSidecar = await _loadSchemaSidecar(
        schemaFilePath: schemaFilePath,
        errors: errors,
      );
      if (errors.isNotEmpty) {
        return ValidationResult(isValid: false, errors: errors, warnings: warnings);
      }

      final dir = Directory(langDirectory);
      if (!dir.existsSync()) {
        errors.add('Language directory not found: $langDirectory');
        return ValidationResult(isValid: false, errors: errors, warnings: warnings);
      }

      final localeFiles = dir.listSync().whereType<File>().where((f) => _isTranslationFile(f.path)).toList();

      if (localeFiles.isEmpty) {
        errors.add('No translation files found in $langDirectory (expected .json or .arb)');
        return ValidationResult(isValid: false, errors: errors, warnings: warnings);
      }

      final translations = <String, Map<String, dynamic>>{};
      final schemasByLocale = <String, Map<String, Map<String, _PlaceholderSchema>>>{};
      for (final file in localeFiles) {
        try {
          final localeData = await _loadLocaleValidationData(file);
          translations[localeData.locale] = localeData.translations;
          schemasByLocale[localeData.locale] = localeData.placeholderSchemasByKey;
        } catch (e) {
          final fileName = file.uri.pathSegments.last;
          errors.add('Failed to parse $fileName: $e');
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
        schemasByLocale: schemasByLocale,
        schemaSidecar: schemaSidecar,
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
    required Map<String, Map<String, Map<String, _PlaceholderSchema>>> schemasByLocale,
    required _SchemaSidecar schemaSidecar,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    final baseMap = translations[baseLocale];
    if (baseMap == null) {
      errors.add('Base locale "$baseLocale" was not found.');
      return ValidationResult(isValid: false, errors: errors, warnings: warnings);
    }

    final baseKeys = _getAllKeys(baseMap);
    final baseSchemasByKey = schemasByLocale[baseLocale] ?? const {};

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
      final baseSchema = _mergeSchemaLayers([
        _extractPlaceholderSchemasFromValue(baseValue),
        baseSchemasByKey[key] ?? const {},
        schemaSidecar.defaultSchemas[key] ?? const {},
      ]);

      for (final entry in translations.entries) {
        if (entry.key == baseLocale) continue;
        final currentValue = _getValueByPath(entry.value, key);
        if (currentValue == null) continue;
        final currentSchemasByKey = schemasByLocale[entry.key] ?? const {};
        final currentSchema = _mergeSchemaLayers([
          _extractPlaceholderSchemasFromValue(currentValue),
          currentSchemasByKey[key] ?? const {},
          schemaSidecar.localeSchemas[entry.key]?[key] ?? const {},
        ]);

        if (options.ruleToggles.checkPlaceholders) {
          final basePlaceholders = baseSchema.keys.toSet();
          final currentPlaceholders = currentSchema.keys.toSet();
          if (!_setsEqual(basePlaceholders, currentPlaceholders)) {
            errors.add(
              'Placeholder mismatch in ${entry.key}.json for key "$key": '
              'expected ${basePlaceholders.toList()..sort()}, '
              'found ${currentPlaceholders.toList()..sort()}',
            );
          }
        }

        if (options.ruleToggles.checkPlaceholderSchema) {
          _validatePlaceholderSchema(
            locale: entry.key,
            keyPath: key,
            expectedSchema: baseSchema,
            currentSchema: currentSchema,
            options: options,
            errors: errors,
            warnings: warnings,
          );
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

  static void _validatePlaceholderSchema({
    required String locale,
    required String keyPath,
    required Map<String, _PlaceholderSchema> expectedSchema,
    required Map<String, _PlaceholderSchema> currentSchema,
    required ValidationOptions options,
    required List<String> errors,
    required List<String> warnings,
  }) {
    if (expectedSchema.isEmpty) {
      return;
    }

    for (final entry in expectedSchema.entries) {
      final placeholder = entry.key;
      final expected = entry.value;
      final actual = currentSchema[placeholder];
      if (actual == null) {
        continue;
      }

      if (expected.required != null && actual.required != null && expected.required != actual.required) {
        errors.add(
          'Placeholder schema mismatch in $locale for key "$keyPath" placeholder "{$placeholder}": '
          'expected required=${expected.required}, found required=${actual.required}. '
          'Fix: align marker usage ({$placeholder!} / {$placeholder?}) or schema metadata.',
        );
      }

      if (expected.normalizedType != null) {
        final actualType = actual.normalizedType;
        if (actualType == null) {
          _addSchemaMissingFieldDiagnostic(
            locale: locale,
            keyPath: keyPath,
            placeholder: placeholder,
            field: 'type',
            expectedValue: expected.type!,
            options: options,
            errors: errors,
            warnings: warnings,
          );
        } else if (actualType != expected.normalizedType) {
          errors.add(
            'Placeholder schema mismatch in $locale for key "$keyPath" placeholder "{$placeholder}": '
            'expected type "${expected.type}", found "${actual.type}". '
            'Fix: update @$keyPath.placeholders.$placeholder.type in locale metadata or schema sidecar.',
          );
        }
      }

      if (expected.normalizedFormat != null) {
        final actualFormat = actual.normalizedFormat;
        if (actualFormat == null) {
          _addSchemaMissingFieldDiagnostic(
            locale: locale,
            keyPath: keyPath,
            placeholder: placeholder,
            field: 'format',
            expectedValue: expected.format!,
            options: options,
            errors: errors,
            warnings: warnings,
          );
        } else if (actualFormat != expected.normalizedFormat) {
          errors.add(
            'Placeholder schema mismatch in $locale for key "$keyPath" placeholder "{$placeholder}": '
            'expected format "${expected.format}", found "${actual.format}". '
            'Fix: update @$keyPath.placeholders.$placeholder.format in locale metadata or schema sidecar.',
          );
        }
      }

      final expectedValues = expected.normalizedAllowedValues;
      if (expectedValues != null && expectedValues.isNotEmpty) {
        final actualValues = actual.normalizedAllowedValues;
        if (actualValues == null || actualValues.isEmpty) {
          _addSchemaMissingFieldDiagnostic(
            locale: locale,
            keyPath: keyPath,
            placeholder: placeholder,
            field: 'values',
            expectedValue: expected.allowedValues!.join(', '),
            options: options,
            errors: errors,
            warnings: warnings,
          );
          continue;
        }
        if (!_setsEqual(expectedValues, actualValues)) {
          errors.add(
            'Placeholder schema mismatch in $locale for key "$keyPath" placeholder "{$placeholder}": '
            'expected values ${expected.allowedValues!.toList()..sort()}, '
            'found ${actual.allowedValues!.toList()..sort()}. '
            'Fix: align select/enum values in metadata or schema sidecar.',
          );
        }
      }
    }
  }

  static void _addSchemaMissingFieldDiagnostic({
    required String locale,
    required String keyPath,
    required String placeholder,
    required String field,
    required String expectedValue,
    required ValidationOptions options,
    required List<String> errors,
    required List<String> warnings,
  }) {
    final message = 'Placeholder schema metadata missing in $locale for key "$keyPath" placeholder "{$placeholder}": '
        'expected $field "$expectedValue". '
        'Fix: add @$keyPath.placeholders.$placeholder.$field or provide it in schema sidecar.';

    if (options.profile == ValidationProfile.strict) {
      errors.add(message);
    } else {
      warnings.add(message);
    }
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

  static bool _isTranslationFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.json') || lower.endsWith('.arb');
  }

  static Future<_LocaleValidationData> _loadLocaleValidationData(
    File file, {
    String? forcedLocale,
  }) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      throw const FormatException('Translation file must decode to a JSON object.');
    }

    final rawMap = Map<String, dynamic>.from(decoded);
    final locale = forcedLocale ?? _resolveLocaleForFile(file, rawMap);
    final placeholderSchemasByKey = _extractPlaceholderSchemasFromMetadata(rawMap);

    final translations = <String, dynamic>{};
    for (final entry in rawMap.entries) {
      if (entry.key == '@@locale' || entry.key.startsWith('@')) {
        continue;
      }
      translations[entry.key] = entry.value;
    }

    return _LocaleValidationData(
      locale: locale,
      translations: translations,
      placeholderSchemasByKey: placeholderSchemasByKey,
    );
  }

  static String _resolveLocaleForFile(
    File file,
    Map<String, dynamic> content,
  ) {
    final localeFromField = content['@@locale']?.toString();
    if (localeFromField != null && localeFromField.trim().isNotEmpty) {
      return localeFromField.trim();
    }

    final fileName = file.uri.pathSegments.last;
    final lower = fileName.toLowerCase();
    final isArb = lower.endsWith('.arb');
    final extLength = isArb ? 4 : 5;
    final baseName = fileName.substring(0, fileName.length - extLength);
    if (isArb && baseName.contains('_')) {
      return baseName.split('_').last;
    }
    return baseName;
  }

  static Future<_SchemaSidecar> _loadSchemaSidecar({
    required String? schemaFilePath,
    required List<String> errors,
  }) async {
    if (schemaFilePath == null || schemaFilePath.trim().isEmpty) {
      return const _SchemaSidecar();
    }

    final file = File(schemaFilePath);
    if (!file.existsSync()) {
      errors.add('Schema file not found: $schemaFilePath');
      return const _SchemaSidecar();
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        errors.add('Schema file must decode to a JSON object: $schemaFilePath');
        return const _SchemaSidecar();
      }

      final map = Map<String, dynamic>.from(decoded);
      if (map.containsKey('default') || map.containsKey('locales')) {
        final defaults = _parseKeyPlaceholderSchemasMap(map['default'] ?? const {});
        final localeSchemas = <String, Map<String, Map<String, _PlaceholderSchema>>>{};
        final rawLocales = map['locales'];
        if (rawLocales is Map) {
          for (final localeEntry in rawLocales.entries) {
            if (localeEntry.key is! String) {
              continue;
            }
            localeSchemas[localeEntry.key.toString()] = _parseKeyPlaceholderSchemasMap(localeEntry.value);
          }
        }
        return _SchemaSidecar(
          defaultSchemas: defaults,
          localeSchemas: localeSchemas,
        );
      }

      return _SchemaSidecar(
        defaultSchemas: _parseKeyPlaceholderSchemasMap(map),
      );
    } catch (error) {
      errors.add('Failed to parse schema file "$schemaFilePath": $error');
      return const _SchemaSidecar();
    }
  }

  static Map<String, Map<String, _PlaceholderSchema>> _extractPlaceholderSchemasFromMetadata(
    Map<String, dynamic> rawMap,
  ) {
    final output = <String, Map<String, _PlaceholderSchema>>{};
    for (final entry in rawMap.entries) {
      final metadataKey = entry.key;
      if (!metadataKey.startsWith('@') || metadataKey == '@@locale') {
        continue;
      }
      final keyPath = metadataKey.substring(1);
      if (keyPath.isEmpty) {
        continue;
      }
      final metadataValue = entry.value;
      if (metadataValue is! Map) {
        continue;
      }
      final placeholderBlock = metadataValue['placeholders'];
      if (placeholderBlock is! Map) {
        continue;
      }

      final perKeySchemas = <String, _PlaceholderSchema>{};
      for (final placeholderEntry in placeholderBlock.entries) {
        final placeholderName = placeholderEntry.key.toString();
        final schema = _parsePlaceholderSchema(placeholderEntry.value);
        if (schema == null) {
          continue;
        }
        perKeySchemas[placeholderName] = schema;
      }
      if (perKeySchemas.isNotEmpty) {
        output[keyPath] = perKeySchemas;
      }
    }
    return output;
  }

  static Map<String, Map<String, _PlaceholderSchema>> _parseKeyPlaceholderSchemasMap(
    dynamic raw,
  ) {
    if (raw is! Map) {
      return const {};
    }
    final output = <String, Map<String, _PlaceholderSchema>>{};
    for (final entry in raw.entries) {
      final keyPath = entry.key.toString();
      final placeholderMap = entry.value;
      if (placeholderMap is! Map) {
        continue;
      }
      final schemas = <String, _PlaceholderSchema>{};
      for (final placeholderEntry in placeholderMap.entries) {
        final name = placeholderEntry.key.toString();
        final schema = _parsePlaceholderSchema(placeholderEntry.value);
        if (schema == null) {
          continue;
        }
        schemas[name] = schema;
      }
      if (schemas.isNotEmpty) {
        output[keyPath] = schemas;
      }
    }
    return output;
  }

  static _PlaceholderSchema? _parsePlaceholderSchema(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    final rawType = raw['type']?.toString().trim();
    final rawFormat = raw['format']?.toString().trim();
    final required = _parseRequiredFlag(raw);
    final values = _parseAllowedValues(raw);

    if ((rawType == null || rawType.isEmpty) &&
        (rawFormat == null || rawFormat.isEmpty) &&
        required == null &&
        (values == null || values.isEmpty)) {
      return null;
    }

    return _PlaceholderSchema(
      type: rawType == null || rawType.isEmpty ? null : rawType,
      required: required,
      format: rawFormat == null || rawFormat.isEmpty ? null : rawFormat,
      allowedValues: values,
    );
  }

  static bool? _parseRequiredFlag(Map raw) {
    final required = raw['required'];
    if (required is bool) {
      return required;
    }
    final optional = raw['optional'];
    if (optional is bool) {
      return !optional;
    }
    return null;
  }

  static Set<String>? _parseAllowedValues(Map raw) {
    final candidate = raw['values'] ?? raw['allowedValues'] ?? raw['selectValues'] ?? raw['enumValues'];
    if (candidate is! List) {
      return null;
    }

    final values = candidate.map((value) => value.toString()).where((value) => value.trim().isNotEmpty).toSet();
    return values.isEmpty ? null : values;
  }

  static Map<String, _PlaceholderSchema> _mergeSchemaLayers(
    List<Map<String, _PlaceholderSchema>> layers,
  ) {
    final merged = <String, _PlaceholderSchema>{};
    for (final layer in layers) {
      for (final entry in layer.entries) {
        final existing = merged[entry.key];
        merged[entry.key] = existing == null ? entry.value : existing.mergeWith(entry.value);
      }
    }
    return merged;
  }

  static Map<String, _PlaceholderSchema> _extractPlaceholderSchemasFromValue(dynamic value) {
    if (value is String) {
      return _extractPlaceholderSchemasFromString(value);
    }

    if (value is Map) {
      final placeholders = <String, _PlaceholderSchema>{};
      for (final nested in value.values) {
        final nestedSchemas = _extractPlaceholderSchemasFromValue(nested);
        placeholders.addAll(_mergeSchemaLayers([placeholders, nestedSchemas]));
      }
      return placeholders;
    }

    if (value is List) {
      final placeholders = <String, _PlaceholderSchema>{};
      for (final nested in value) {
        final nestedSchemas = _extractPlaceholderSchemasFromValue(nested);
        placeholders.addAll(_mergeSchemaLayers([placeholders, nestedSchemas]));
      }
      return placeholders;
    }

    return const <String, _PlaceholderSchema>{};
  }

  static Map<String, _PlaceholderSchema> _extractPlaceholderSchemasFromString(String text) {
    final regex = RegExp(r'\{([a-zA-Z0-9_]+)([!?])?\}');
    final output = <String, _PlaceholderSchema>{};
    for (final match in regex.allMatches(text)) {
      final placeholder = match.group(1);
      if (placeholder == null || placeholder.isEmpty) {
        continue;
      }
      final marker = match.group(2);
      final markerRequired = marker == '?' ? false : true;
      final existing = output[placeholder];
      if (existing == null) {
        output[placeholder] = _PlaceholderSchema(required: markerRequired);
        continue;
      }

      output[placeholder] = existing.mergeWith(
        _PlaceholderSchema(
          required: existing.required == null || existing.required == markerRequired ? markerRequired : null,
        ),
      );
    }
    return output;
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
