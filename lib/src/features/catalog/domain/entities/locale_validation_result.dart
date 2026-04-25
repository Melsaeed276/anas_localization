library;

import '/src/shared/core/localization_exceptions.dart';

/// Result of validating a locale code against ISO standards.
class LocaleValidationResult {
  const LocaleValidationResult({
    required this.isValid,
    this.languageCode,
    this.countryCode,
    this.languageName,
    this.countryName,
    this.displayName,
    this.errorMessage,
    this.errorType,
  });

  /// Whether the locale code is valid.
  final bool isValid;

  /// Parsed and normalized language code (e.g., "en").
  final String? languageCode;

  /// Parsed and normalized country code (e.g., "US"). Null if not present.
  final String? countryCode;

  /// Human-readable language name (e.g., "English").
  final String? languageName;

  /// Human-readable country name (e.g., "United States"). Null if not present.
  final String? countryName;

  /// Full display name (e.g., "English (United States)" or "English").
  final String? displayName;

  /// Error message if validation failed.
  final String? errorMessage;

  /// Type of validation error.
  final LocaleValidationErrorType? errorType;

  @override
  String toString() => 'LocaleValidationResult(isValid: $isValid, displayName: $displayName)';
}
