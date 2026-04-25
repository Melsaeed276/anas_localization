library;

import '/src/shared/utils/iso_locale_codes.dart';
import '/src/features/catalog/domain/entities/locale_validation_result.dart';
import '/src/shared/core/localization_exceptions.dart';
import '/src/shared/services/logging/logging_service.dart';

/// Represents a parsed locale code with language and country parts.
class _ParsedLocale {
  const _ParsedLocale({
    required this.languageCode,
    required this.countryCode,
  });

  final String languageCode;
  final String? countryCode;
}

/// Parses a locale code string into language and country components.
/// Supports formats: "en", "en_US", "en-US" (hyphens are converted to underscores)
/// Returns null if the format is invalid.
_ParsedLocale? _parseLocaleCode(String code) {
  final normalized = code.replaceAll('-', '_').toLowerCase();

  if (normalized.isEmpty) {
    return null;
  }

  final parts = normalized.split('_');

  // Language code only
  if (parts.length == 1) {
    final languageCode = parts[0].trim();
    if (languageCode.isEmpty || languageCode.length > 5) {
      return null;
    }
    return _ParsedLocale(
      languageCode: languageCode,
      countryCode: null,
    );
  }

  // Language code + country code
  if (parts.length == 2) {
    final languageCode = parts[0].trim();
    final countryCode = parts[1].trim();
    if (languageCode.isEmpty || languageCode.length > 5 || countryCode.isEmpty || countryCode.length > 3) {
      return null;
    }
    return _ParsedLocale(
      languageCode: languageCode,
      countryCode: countryCode.toUpperCase(),
    );
  }

  // Too many parts
  return null;
}

/// Service for validating locale codes against ISO standards.
class LocaleValidationService {
  const LocaleValidationService();

  /// Validates a locale code against ISO 639-1/639-2 and ISO 3166-1 standards.
  /// Returns a [LocaleValidationResult] with detailed validation info.
  LocaleValidationResult validateLocaleCode(String code) {
    // Trim and normalize
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      // T065: Log validation error - empty locale code
      logger.warning('Locale validation failed: empty code', 'LocaleValidationService');
      return const LocaleValidationResult(
        isValid: false,
        errorMessage: 'Locale code cannot be empty.',
        errorType: LocaleValidationErrorType.invalidFormat,
      );
    }

    // Parse the code
    final parsed = _parseLocaleCode(trimmed);
    if (parsed == null) {
      // T065: Log validation error - invalid format
      logger.warning(
        'Locale validation failed: invalid format "$trimmed"',
        'LocaleValidationService',
      );
      return LocaleValidationResult(
        isValid: false,
        errorMessage: 'Invalid locale format "$trimmed". Use format like "en", "en_US", or "zh_CN".',
        errorType: LocaleValidationErrorType.invalidFormat,
      );
    }

    final languageCode = parsed.languageCode;
    final countryCode = parsed.countryCode;

    // Validate language code
    if (!isValidLanguageCode(languageCode)) {
      // T065: Log validation error - invalid language code
      logger.warning(
        'Locale validation failed: invalid language code "$languageCode"',
        'LocaleValidationService',
      );
      return LocaleValidationResult(
        isValid: false,
        languageCode: languageCode,
        errorMessage: 'Invalid language code "$languageCode". Please use ISO 639-1 or 639-2 codes.',
        errorType: LocaleValidationErrorType.invalidLanguageCode,
      );
    }

    // Validate country code if present
    if (countryCode != null && !isValidCountryCode(countryCode)) {
      // T065: Log validation error - invalid country code
      logger.warning(
        'Locale validation failed: invalid country code "$countryCode" for language "$languageCode"',
        'LocaleValidationService',
      );
      return LocaleValidationResult(
        isValid: false,
        languageCode: languageCode,
        countryCode: countryCode,
        errorMessage: 'Invalid country code "$countryCode". Please use ISO 3166-1 alpha-2 codes.',
        errorType: LocaleValidationErrorType.invalidCountryCode,
      );
    }

    // Get language and country names
    final languageName = getLanguageName(languageCode);
    final countryName = countryCode != null ? getCountryName(countryCode) : null;

    // Build display name
    final displayName = countryName != null ? '$languageName ($countryName)' : (languageName ?? languageCode);

    // T065: Log successful validation
    logger.debug(
      'Locale validation succeeded: "$trimmed" → $displayName',
      'LocaleValidationService',
    );

    return LocaleValidationResult(
      isValid: true,
      languageCode: languageCode,
      countryCode: countryCode,
      languageName: languageName,
      countryName: countryName,
      displayName: displayName,
    );
  }

  /// Checks if a language code is valid.
  bool isValidLanguageCode(String code) {
    return kIsoLanguageCodes.containsKey(code.toLowerCase());
  }

  /// Checks if a country code is valid.
  bool isValidCountryCode(String code) {
    return kIsoCountryCodes.containsKey(code.toUpperCase());
  }

  /// Gets the language name for a code.
  String? getLanguageName(String code) {
    return kIsoLanguageCodes[code.toLowerCase()];
  }

  /// Gets the country name for a code.
  String? getCountryName(String code) {
    return kIsoCountryCodes[code.toUpperCase()];
  }
}
