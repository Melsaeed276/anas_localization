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
  const UnsupportedLocaleException(String localeCode) : super('Unsupported locale: $localeCode');
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

/// Enumeration of locale validation error types.
enum LocaleValidationErrorType {
  invalidFormat,
  invalidLanguageCode,
  invalidCountryCode,
  duplicateLocale,
}

/// Exception thrown when an invalid locale code is provided.
class InvalidLocaleCodeException extends LocalizationException {
  InvalidLocaleCodeException(
    this.localeCode, {
    required this.errorType,
    String? message,
  }) : super(message ?? _defaultMessage(localeCode, errorType));

  /// The invalid locale code.
  final String localeCode;

  /// The type of validation error.
  final LocaleValidationErrorType errorType;

  static String _defaultMessage(String code, LocaleValidationErrorType type) {
    switch (type) {
      case LocaleValidationErrorType.invalidFormat:
        return 'Invalid locale format "$code". Use format like "en", "en_US", or "zh_CN".';
      case LocaleValidationErrorType.invalidLanguageCode:
        return 'Invalid language code in "$code". Please use ISO 639-1 or 639-2 codes.';
      case LocaleValidationErrorType.invalidCountryCode:
        return 'Invalid country code in "$code". Please use ISO 3166-1 alpha-2 codes.';
      case LocaleValidationErrorType.duplicateLocale:
        return 'Locale "$code" already exists.';
    }
  }
}

/// Exception thrown when configuring a language group fallback would create a cycle.
class CircularFallbackException extends LocalizationException {
  CircularFallbackException(this.locale, this.attemptedFallback)
      : super('Circular fallback detected. Setting "$locale" to fall back to '
            '"$attemptedFallback" would create a cycle.');

  /// The locale being configured.
  final String locale;

  /// The attempted fallback that would create a cycle.
  final String attemptedFallback;
}
