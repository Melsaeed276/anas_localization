/// Canonical message resolution with fallback order (plural→other, gender→other, variant→MSA, then key).
/// Used by both type-safe dictionary and raw-key access (Constitution I).
library;

import '../entities/dictionary.dart';
import '../entities/user_context.dart';
import '../../../../shared/utils/plural_rules.dart';

/// Resolves a message key using [dictionary], [context], and optional [overrides] and [params].
/// Implements canonical fallback: within same key try alternate form (plural→other, gender→other, variant→MSA), then base/key.
String resolveMessage(
  Dictionary dictionary,
  UserContext context, {
  required String key,
  UserContext? overrides,
  Map<String, dynamic>? params,
}) {
  final effective = overrides != null
      ? context.mergeOverrides(
          locale: overrides.locale.isEmpty ? null : overrides.locale,
          gender: overrides.gender,
          formality: overrides.formality,
          regionalVariant: overrides.regionalVariant,
        )
      : context;

  final count = params != null && params.containsKey('count')
      ? params['count'] is int
          ? params['count'] as int
          : int.tryParse(params['count'].toString()) ?? 0
      : null;

  final localeCode = effective.locale.split('_').first.toLowerCase();

  // 1) Plural: if count provided, get plural form and try that form then other (CLDR n%100)
  if (count != null) {
    final pluralForm = PluralRules.getPluralForm(count, localeCode);
    final pluralData = dictionary.getPluralData(key);
    if (pluralData != null) {
      String? value = _extractPluralFormString(pluralData[pluralForm], effective.gender);
      if (value == null && pluralForm != 'other') {
        value = _extractPluralFormString(pluralData['other'], effective.gender);
      }
      if (value != null && value.isNotEmpty) {
        return _substituteParams(value, params ?? const {});
      }
    }
  }

  // 2) Gender: try gender-specific key then fallback to other/neutral (key)
  final genderSuffix = effective.gender == ResolutionGender.female ? '_female' : '_male';
  final keyWithGender = '$key$genderSuffix';
  String? value = _getString(dictionary, keyWithGender);
  if (value != null) return _substituteParams(value, params ?? const {});
  value = _getString(dictionary, key);
  if (value != null) return _substituteParams(value, params ?? const {});

  // 3) Variant + formality: try combined then variant→MSA then formality→key (per asset-schema fallback)
  value = _getString(dictionary, '${key}_${effective.regionalVariant.name}_${effective.formality.name}');
  if (value != null) return _substituteParams(value, params ?? const {});
  value = _getString(dictionary, '${key}_${effective.regionalVariant.name}');
  if (value != null) return _substituteParams(value, params ?? const {});
  value = _getString(dictionary, '${key}_msa');
  if (value != null) return _substituteParams(value, params ?? const {});
  value = _getString(dictionary, '${key}_${effective.formality.name}');
  if (value != null) return _substituteParams(value, params ?? const {});

  // 4) Base key
  value = _getString(dictionary, key);
  if (value != null) return _substituteParams(value, params ?? const {});

  return key;
}

String _substituteParams(String template, Map<String, dynamic> params) {
  String result = template;
  for (final entry in params.entries) {
    final value = entry.value.toString();
    result = result.replaceAll('{${entry.key}}', value);
    result = result.replaceAll('{${entry.key}?}', value);
    result = result.replaceAll('{${entry.key}!}', value);
  }
  return result;
}

String? _getString(Dictionary dictionary, String key) {
  if (!dictionary.hasKey(key)) return null;
  final v = dictionary.getString(key, fallback: key);
  return v.isEmpty ? null : v;
}

/// Extracts a display string from a plural form value: either a string or a map with male/female.
String? _extractPluralFormString(dynamic formValue, ResolutionGender gender) {
  if (formValue == null) return null;
  if (formValue is String) return formValue.isEmpty ? null : formValue;
  if (formValue is Map<String, dynamic>) {
    final key = gender == ResolutionGender.female ? 'female' : 'male';
    final v = formValue[key];
    if (v is String && v.isNotEmpty) return v;
    final fallback = formValue['other'] ?? formValue['male'] ?? formValue['female'];
    return fallback is String && fallback.isNotEmpty ? fallback : null;
  }
  return null;
}

/// Extension so [Dictionary] can be resolved with [UserContext] via the same path as raw-key access (Constitution I).
extension DictionaryResolution on Dictionary {
  /// Resolves [key] using this dictionary and [context], with optional [params] (e.g. count) and [overrides].
  /// Uses the canonical resolution path (plural→gender→variant→formality→key) shared with raw-key access.
  String resolve(
    UserContext context,
    String key, {
    Map<String, dynamic>? params,
    UserContext? overrides,
  }) =>
      resolveMessage(this, context, key: key, params: params, overrides: overrides);
}
