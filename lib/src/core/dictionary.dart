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
    final value = _translations[key];
    if (value is String) return value;
    return fallback ?? key;
  }

  /// Get a translation with parameters
  String getStringWithParams(String key, Map<String, dynamic> params, {String? fallback}) {
    String template = getString(key, fallback: fallback);

    params.forEach((paramKey, value) {
      template = template.replaceAll('{$paramKey}', value.toString());
    });

    return template;
  }

  /// Check if a key exists in translations
  bool hasKey(String key) => _translations.containsKey(key);

  // Dynamic getters will be generated here by the code generation tool
  // Example generated getters:
  // String get appName => getString('app_name');
  // String get ok => getString('ok');
  // String get cancel => getString('cancel');
}