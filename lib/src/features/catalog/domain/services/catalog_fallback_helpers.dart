import '../../../localization/domain/services/fallback_resolver.dart';

/// Returns true if adding [newFallback] to [locale]'s chain would create a cycle.
bool hasCircularFallback(
  Map<String, String> fallbacks,
  String locale,
  String newFallback,
) {
  if (locale == newFallback) return true;

  final visited = <String>{locale};
  var current = fallbacks[newFallback];

  while (current != null && current.isNotEmpty) {
    if (visited.contains(current)) return true;
    visited.add(current);
    current = fallbacks[current];
  }

  return false;
}

/// Resolves the full fallback chain for [locale] given the configured [fallbacks] map.
/// Returns locales in fallback order: [primary, fallback1, fallback2, …]
List<String> resolveFallbackChain(
  Map<String, String> fallbacks,
  String locale,
) =>
    resolveConfiguredChain(fallbacks, locale);

/// Extracts the language code from a locale string.
/// E.g. 'en_US' → 'en', 'ar_SA' → 'ar'.
String getLanguageCode(String locale) => locale.split('_')[0];

/// Returns true if [locale1] and [locale2] belong to the same language group.
bool sameLanguageGroup(String locale1, String locale2) {
  final lang1 = getLanguageCode(locale1);
  final lang2 = getLanguageCode(locale2);
  if (lang1 == lang2) return true;
  if (locale1 == lang2 || locale2 == lang1) return true;
  return false;
}
