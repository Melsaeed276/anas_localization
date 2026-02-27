/// Auto-generated Dictionary class for type-safe localization access
///
/// This class provides type-safe access to localized strings through getters.
/// Example usage: `dictionary.appName` returns the localized app name.
class Dictionary {

  Dictionary.fromMap(Map<String, dynamic> map, {required String locale})
      : _translations = map,
        _locale = locale;
  final Map<String, dynamic> _translations;
  final String _locale;

  /// Convert dictionary back to map
  Map<String, dynamic> toMap() => Map<String, dynamic>.from(_translations);

  /// Get the current locale
  String get locale => _locale;

  /// Get a translation by key with fallback
  String getString(String key, {String? fallback}) {
    final value = _resolveValueByPath(key);
    if (value is String) return value;
    return fallback ?? key;
  }

  /// Get a translation with parameters
  String getStringWithParams(String key, Map<String, dynamic> params, {String? fallback}) {
    String template = getString(key, fallback: fallback);

    params.forEach((paramKey, value) {
      // Handle both regular placeholders and placeholders with optional/required markers
      template = template.replaceAll('{$paramKey}', value.toString());
      template = template.replaceAll('{$paramKey?}', value.toString());
      template = template.replaceAll('{$paramKey!}', value.toString());
    });

    return template;
  }

  /// Get plural form data for a key - used by generated Dictionary classes
  Map<String, dynamic>? getPluralData(String key) {
    final value = _resolveValueByPath(key);
    return value is Map<String, dynamic> ? value : null;
  }

  /// Check if a key exists in translations
  bool hasKey(String key) => _resolveValueByPath(key) != null;

  dynamic _resolveValueByPath(String key) {
    if (!key.contains('.')) {
      return _translations[key];
    }

    dynamic current = _translations;
    for (final segment in key.split('.')) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }

  // Dynamic getters will be generated here by the code generation tool
  // Example generated getters:
  // String get appName => getString('app_name');
  // String get ok => getString('ok');
  // String get cancel => getString('cancel');
}
