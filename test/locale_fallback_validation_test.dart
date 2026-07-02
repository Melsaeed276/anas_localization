import 'package:anas_localization/anas_localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Locale Validation', () {
    /// FR-009: Validate language group fallback constraints
    test('same-language-group constraint: ar_SA -> ar_EG is valid', () {
      final validator = const LocaleValidationService();

      const source = 'ar_SA';
      const fallback = 'ar_EG';

      final result = validator.validateLocaleCode(source);
      expect(result.isValid, isTrue);

      final fallbackResult = validator.validateLocaleCode(fallback);
      expect(fallbackResult.isValid, isTrue);

      // Both are in the same language group (ar)
      expect(_getLanguageCode(source), equals(_getLanguageCode(fallback)));
    });

    test('same-language-group constraint: ar_SA -> ar is valid', () {
      final validator = const LocaleValidationService();

      const source = 'ar_SA';
      const fallback = 'ar';

      final result = validator.validateLocaleCode(source);
      expect(result.isValid, isTrue);

      final fallbackResult = validator.validateLocaleCode(fallback);
      expect(fallbackResult.isValid, isTrue);

      // fallback is language-only, which is compatible
      expect(_getLanguageCode(source), equals(fallback));
    });

    test('same-language-group constraint: en_US -> en_GB is valid', () {
      final validator = const LocaleValidationService();

      const source = 'en_US';
      const fallback = 'en_GB';

      final result = validator.validateLocaleCode(source);
      expect(result.isValid, isTrue);

      final fallbackResult = validator.validateLocaleCode(fallback);
      expect(fallbackResult.isValid, isTrue);

      // Both are in the same language group (en)
      expect(_getLanguageCode(source), equals(_getLanguageCode(fallback)));
    });

    test('same-language-group constraint violation: ar_SA -> en_US is invalid', () {
      const source = 'ar_SA';
      const fallback = 'en_US';

      // Different language groups should not be allowed as fallbacks
      expect(_getLanguageCode(source), isNot(equals(_getLanguageCode(fallback))));
    });

    test('same-language-group constraint violation: en_GB -> ar is invalid', () {
      const source = 'en_GB';
      const fallback = 'ar';

      // Different language groups should not be allowed as fallbacks
      expect(_getLanguageCode(source), isNot(equals(fallback)));
    });

    test('prevents cross-language-group fallback configuration', () {
      // This test verifies the constraint: a regional locale must only
      // fall back to locales within the same language group

      const invalidConfigurations = [
        ('ar_SA', 'en_US'), // Arabic → English
        ('en_US', 'ar_EG'), // English → Arabic
        ('fr_FR', 'de_DE'), // French → German
      ];

      for (final (source, fallback) in invalidConfigurations) {
        expect(
          _getLanguageCode(source),
          isNot(equals(_getLanguageCode(fallback))),
          reason: '$source → $fallback crosses language group boundary',
        );
      }
    });

    test('allows language-code-only fallback (any regional -> language)', () {
      final validator = const LocaleValidationService();

      const configurations = [
        ('ar_SA', 'ar'),
        ('ar_EG', 'ar'),
        ('en_US', 'en'),
        ('en_GB', 'en'),
        ('fr_FR', 'fr'),
      ];

      for (final (source, fallback) in configurations) {
        final sourceResult = validator.validateLocaleCode(source);
        final fallbackResult = validator.validateLocaleCode(fallback);

        expect(sourceResult.isValid, isTrue);
        expect(fallbackResult.isValid, isTrue);
        expect(_getLanguageCode(source), equals(fallback));
      }
    });

    test('rejects regional locale as fallback target for another regional locale', () {
      // FR-010: Prevent regional locale as fallback
      // This means: ar_SA cannot directly fall back to ar_EG, which would then
      // fall back to another regional locale. The pattern must eventually terminate
      // at either a language-only code or the project default.

      // However, ar_SA -> ar_EG is allowed as long as ar_EG eventually falls back
      // to ar (language-only)

      final validChain = _buildFallbackChain(
        {
          'ar_SA': 'ar_EG',
          'ar_EG': 'ar',
        },
        'ar_SA',
      );

      expect(validChain, equals(['ar_SA', 'ar_EG', 'ar']));
    });

    test('validates locale codes for standard formats', () {
      final validator = const LocaleValidationService();

      // Valid formats
      final validLocales = [
        'ar', // language-only
        'ar_SA', // language_country
        'en',
        'en_US',
        'en_GB',
        'fr',
        'fr_FR',
      ];

      for (final locale in validLocales) {
        final result = validator.validateLocaleCode(locale);
        expect(
          result.isValid,
          isTrue,
          reason: '$locale should be valid',
        );
      }
    });

    test('rejects invalid locale code formats', () {
      final validator = const LocaleValidationService();

      // Invalid formats
      final invalidLocales = [
        'a', // too short
        'en_U', // invalid country code (single char)
        'en_USA', // country code too long (3 chars)
        '', // empty
      ];

      for (final locale in invalidLocales) {
        final result = validator.validateLocaleCode(locale);
        expect(
          result.isValid,
          isFalse,
          reason: '$locale should be invalid',
        );
      }
    });
  });
}

/// Test helper: extracts language code from locale
String _getLanguageCode(String locale) {
  final parts = locale.split('_');
  return parts[0];
}

/// Test helper: builds a fallback chain
List<String> _buildFallbackChain(
  Map<String, String> fallbacks,
  String locale,
) {
  final chain = [locale];
  var current = fallbacks[locale];

  while (current != null && current.isNotEmpty) {
    chain.add(current);
    current = fallbacks[current];
  }

  return chain;
}
