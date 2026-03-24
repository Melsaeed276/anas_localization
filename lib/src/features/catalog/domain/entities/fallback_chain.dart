library;

/// Represents the complete resolution path for a locale's translations.
class FallbackChain {
  const FallbackChain({
    required this.targetLocale,
    required this.chain,
    required this.projectDefaultLocale,
  });

  /// The locale for which this chain was computed.
  final String targetLocale;

  /// Ordered list of locales to try when resolving translations.
  /// First element is the target locale itself.
  final List<String> chain;

  /// The project's default fallback locale (always last in chain).
  final String projectDefaultLocale;

  /// Human-readable representation (e.g., "ar_SA → ar_EG → en").
  String get displayString => chain.join(' → ');

  /// Whether this chain includes a language group fallback.
  /// A language group fallback is present if the target locale has a regional variant
  /// (e.g., ar_SA) and the first fallback is not the language-only code (e.g., ar).
  bool get hasLanguageGroupFallback {
    if (chain.isEmpty) return false;
    // If the target locale is regional (contains underscore) and there's a fallback
    // that is not the language-only code, then we have a language group fallback
    if (!targetLocale.contains('_')) return false; // Not a regional locale
    if (chain.length < 2) return false; // No fallback configured

    final languageCode = _getLanguageCode(targetLocale);
    // Language group fallback exists if first fallback is not the language-only code
    return chain[1] != languageCode;
  }

  /// Extracts just the language code from a locale string (e.g., "en" from "en_US").
  static String _getLanguageCode(String locale) {
    final parts = locale.split('_');
    return parts[0];
  }

  @override
  String toString() => 'FallbackChain(targetLocale: $targetLocale, displayString: $displayString)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FallbackChain &&
          runtimeType == other.runtimeType &&
          targetLocale == other.targetLocale &&
          chain == other.chain &&
          projectDefaultLocale == other.projectDefaultLocale;

  @override
  int get hashCode => targetLocale.hashCode ^ chain.hashCode ^ projectDefaultLocale.hashCode;
}
