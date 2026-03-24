/// Shared fallback resolution logic for configuration and runtime use.
///
/// **Issue #126**: Consolidates duplicate fallback chain resolution logic
/// that existed in CatalogService and LocalizationService.
///
/// This service provides:
/// 1. **resolveConfiguredChain**: Follows the configured fallback DAG (for configuration time)
/// 2. **expandWithVariants**: Expands a locale with variants (for runtime resolution)
/// 3. **resolveWithDefaults**: Appends default fallback (for runtime resolution)
///
/// Separates concerns:
/// - Configuration time: Uses configured fallback DAG
/// - Runtime: Configuration DAG + variant expansion + default fallback
library fallback_resolver;

/// Resolves the configured fallback chain by following the fallback DAG.
///
/// This is the **configured chain** - what the user explicitly set up.
/// Used at configuration time to show what fallbacks are set.
///
/// Example:
/// - If configured: ar_SA → ar
/// - Returns: [ar_SA, ar]
///
/// **Circular Detection**: If a cycle is detected, returns early.
/// **Single Source of Truth**: Configuration time view of the DAG.
///
/// **Related to**: CatalogService.getFallbackChain()
List<String> resolveConfiguredChain(
  Map<String, String> fallbacksMap,
  String locale,
) {
  final chain = [locale];
  var current = fallbacksMap[locale];

  // Follow configured fallbacks with circular detection
  while (current != null && current.isNotEmpty) {
    if (chain.contains(current)) {
      // Circular reference detected, stop here
      break;
    }
    chain.add(current);
    current = fallbacksMap[current];
  }

  return chain;
}

/// Expands a single locale with all its variants.
///
/// Handles variant expansion where ar_SA can match ar_SA.txt, ar_SA.json, etc.
/// Adds the base language if the locale is a regional variant.
///
/// Example:
/// - Input: ar_SA
/// - Returns: [ar_SA, ar] (adds base language ar)
/// - Input: en
/// - Returns: [en] (no base to add)
///
/// **Used by**: LocalizationService for runtime variant matching.
List<String> expandWithVariants(String locale) {
  final expanded = <String>[locale];

  // If regional variant (e.g., ar_SA), also try base language (ar)
  if (locale.contains('_')) {
    final baseLanguage = locale.split('_')[0];
    if (!expanded.contains(baseLanguage)) {
      expanded.add(baseLanguage);
    }
  }

  return expanded;
}

/// Resolves a fallback chain with default locale appending.
///
/// Takes a chain and ensures the default locale is included at the end
/// as the ultimate fallback. Prevents duplicates.
///
/// Example:
/// - Input: [ar_SA, ar], defaultLocale: en
/// - Returns: [ar_SA, ar, en]
///
/// **Used by**: LocalizationService for runtime resolution.
List<String> resolveWithDefaults(
  List<String> configuredChain,
  String defaultLocale,
) {
  final final_ = <String>[...configuredChain];

  // Ensure default is at the end (if not already present)
  if (!final_.contains(defaultLocale)) {
    final_.add(defaultLocale);
  }

  return final_;
}

/// Convenience method: Combines configured chain resolution + defaults.
///
/// This is the **complete configured chain** including default fallback.
/// Used by CatalogService for display purposes.
///
/// Example:
/// - If configured: ar_SA → ar, defaultLocale: en
/// - Returns: [ar_SA, ar, en]
List<String> resolveFallbackChainWithDefaults(
  Map<String, String> fallbacksMap,
  String locale,
  String defaultLocale,
) {
  final configured = resolveConfiguredChain(fallbacksMap, locale);
  return resolveWithDefaults(configured, defaultLocale);
}
