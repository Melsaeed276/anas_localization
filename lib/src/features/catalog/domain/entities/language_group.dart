library;

import '/src/shared/utils/iso_locale_codes.dart';

/// Represents a logical grouping of locales sharing the same base language.
/// Computed dynamically from available locales, not persisted.
class LanguageGroup {
  const LanguageGroup({
    required this.baseLanguageCode,
    required this.locales,
    this.fallbackLocale,
  });

  /// The ISO 639-1/639-2 language code (e.g., "ar", "en").
  final String baseLanguageCode;

  /// All locales in this language group (e.g., ["ar", "ar_SA", "ar_EG"]).
  final List<String> locales;

  /// The designated fallback locale for this language group.
  /// Null if no fallback is configured.
  final String? fallbackLocale;

  /// Whether this group has 2+ locales (enabling fallback configuration).
  bool get canConfigureFallback => locales.length >= 2;

  /// Display name for the group (e.g., "Arabic (3 locales)").
  String get displayName {
    final langName = getLanguageName(baseLanguageCode) ?? baseLanguageCode;
    return '$langName (${locales.length} locales)';
  }

  /// Whether this group has a fallback configured.
  bool get hasFallback => fallbackLocale != null;

  @override
  String toString() => 'LanguageGroup(baseLanguageCode: $baseLanguageCode, locales: $locales)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageGroup &&
          runtimeType == other.runtimeType &&
          baseLanguageCode == other.baseLanguageCode &&
          locales == other.locales &&
          fallbackLocale == other.fallbackLocale;

  @override
  int get hashCode => baseLanguageCode.hashCode ^ locales.hashCode ^ fallbackLocale.hashCode;
}
