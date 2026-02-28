library;

/// Base class for localization-related failures.
class LocalizationException implements Exception {
  const LocalizationException(this.message);

  final String message;

  @override
  String toString() => 'LocalizationException: $message';
}

/// Thrown when a locale is requested that is not in the configured supported locales.
class UnsupportedLocaleException extends LocalizationException {
  const UnsupportedLocaleException(String localeCode)
      : super('Unsupported locale: $localeCode');
}

/// Thrown when no localization assets can be resolved for a locale.
class LocalizationAssetsNotFoundException extends LocalizationException {
  const LocalizationAssetsNotFoundException(String localeCode)
      : super('No localization assets found for "$localeCode".');
}

/// Thrown when locale-dependent state is requested before initialization.
class LocalizationNotInitializedException extends LocalizationException {
  const LocalizationNotInitializedException()
      : super('Locale not loaded. Call loadLocale() first.');
}
