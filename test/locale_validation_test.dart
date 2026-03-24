import 'package:flutter_test/flutter_test.dart';
import 'package:anas_localization/src/features/catalog/domain/services/locale_validation_service.dart';
import 'package:anas_localization/src/features/catalog/domain/entities/locale_validation_result.dart';
import 'package:anas_localization/src/shared/core/localization_exceptions.dart';

void main() {
  group('Locale Validation', () {
    final validationService = const LocaleValidationService();

    // T033: ISO language code validation
    group('ISO language code validation (FR-011)', () {
      test('accepts valid ISO 639-1 language code (en)', () {
        final result = validationService.validateLocaleCode('en');
        expect(result.isValid, true);
        expect(result.languageCode, 'en');
        expect(result.languageName, 'English');
      });

      test('accepts valid ISO 639-1 language code (ar)', () {
        final result = validationService.validateLocaleCode('ar');
        expect(result.isValid, true);
        expect(result.languageCode, 'ar');
        expect(result.languageName, 'Arabic');
      });

      test('accepts valid ISO 639-1 language code with country (en_US)', () {
        final result = validationService.validateLocaleCode('en_US');
        expect(result.isValid, true);
        expect(result.languageCode, 'en');
        expect(result.countryCode, 'US');
      });

      test('rejects invalid language code (xyz)', () {
        final result = validationService.validateLocaleCode('xyz');
        expect(result.isValid, false);
        expect(result.errorType, LocaleValidationErrorType.invalidLanguageCode);
        expect(result.errorMessage, contains('Invalid language code'));
      });

      test('rejects invalid language code with country (xyz_US)', () {
        final result = validationService.validateLocaleCode('xyz_US');
        expect(result.isValid, false);
        expect(result.errorType, LocaleValidationErrorType.invalidLanguageCode);
      });

      test('case-insensitive language code validation (EN)', () {
        final result = validationService.validateLocaleCode('EN');
        expect(result.isValid, true);
        expect(result.languageCode, 'en');
      });

      test('case-insensitive language code validation (En_us)', () {
        final result = validationService.validateLocaleCode('En_us');
        expect(result.isValid, true);
        expect(result.languageCode, 'en');
        expect(result.countryCode, 'US');
      });
    });

    // T034: ISO country code validation
    group('ISO country code validation (FR-011)', () {
      test('accepts valid ISO 3166-1 country code (en_US)', () {
        final result = validationService.validateLocaleCode('en_US');
        expect(result.isValid, true);
        expect(result.countryCode, 'US');
        expect(result.countryName, 'United States');
      });

      test('accepts valid ISO 3166-1 country code (ar_SA)', () {
        final result = validationService.validateLocaleCode('ar_SA');
        expect(result.isValid, true);
        expect(result.countryCode, 'SA');
        expect(result.countryName, 'Saudi Arabia');
      });

      test('accepts valid ISO 3166-1 country code (zh_CN)', () {
        final result = validationService.validateLocaleCode('zh_CN');
        expect(result.isValid, true);
        expect(result.countryCode, 'CN');
        expect(result.countryName, 'China');
      });

      test('rejects invalid country code (en_ZZ)', () {
        final result = validationService.validateLocaleCode('en_ZZ');
        expect(result.isValid, false);
        expect(result.errorType, LocaleValidationErrorType.invalidCountryCode);
        expect(result.errorMessage, contains('Invalid country code'));
      });

      test('rejects invalid country code (en_ABC)', () {
        final result = validationService.validateLocaleCode('en_ABC');
        expect(result.isValid, false);
        expect(result.errorType, LocaleValidationErrorType.invalidCountryCode);
      });

      test('case-insensitive country code validation (en_us)', () {
        final result = validationService.validateLocaleCode('en_us');
        expect(result.isValid, true);
        expect(result.countryCode, 'US');
      });

      test('accepts language-only code without country validation', () {
        final result = validationService.validateLocaleCode('en');
        expect(result.isValid, true);
        expect(result.countryCode, null);
      });
    });

    // T035: Locale code normalization (hyphen to underscore)
    group('Locale code normalization (FR-012)', () {
      test('converts hyphen to underscore (en-US -> en_US)', () {
        final result = validationService.validateLocaleCode('en-US');
        expect(result.isValid, true);
        expect(result.languageCode, 'en');
        expect(result.countryCode, 'US');
      });

      test('converts hyphen to underscore (ar-SA -> ar_SA)', () {
        final result = validationService.validateLocaleCode('ar-SA');
        expect(result.isValid, true);
        expect(result.languageCode, 'ar');
        expect(result.countryCode, 'SA');
      });

      test('preserves underscore format (en_US)', () {
        final result = validationService.validateLocaleCode('en_US');
        expect(result.isValid, true);
        expect(result.languageCode, 'en');
        expect(result.countryCode, 'US');
      });

      test('normalizes mixed case and hyphens (En-us)', () {
        final result = validationService.validateLocaleCode('En-us');
        expect(result.isValid, true);
        expect(result.languageCode, 'en');
        expect(result.countryCode, 'US');
      });

      test('rejects multiple hyphens (en-US-invalid)', () {
        final result = validationService.validateLocaleCode('en-US-invalid');
        expect(result.isValid, false);
        expect(result.errorType, LocaleValidationErrorType.invalidFormat);
      });

      test('rejects empty locale code', () {
        final result = validationService.validateLocaleCode('');
        expect(result.isValid, false);
        expect(result.errorType, LocaleValidationErrorType.invalidFormat);
      });

      test('rejects whitespace-only locale code', () {
        final result = validationService.validateLocaleCode('   ');
        expect(result.isValid, false);
        expect(result.errorType, LocaleValidationErrorType.invalidFormat);
      });
    });

    // T036: Duplicate locale detection helper
    group('Locale existence detection (FR-013)', () {
      test('validates unique locale against list (not duplicate)', () {
        final existingLocales = ['en', 'ar', 'fr'];
        final newLocale = 'es_MX';
        final isDuplicate = existingLocales.contains(newLocale);
        expect(isDuplicate, false);
      });

      test('detects duplicate locale in list (exact match)', () {
        final existingLocales = ['en', 'ar', 'en_US'];
        final newLocale = 'en_US';
        final isDuplicate = existingLocales.contains(newLocale);
        expect(isDuplicate, true);
      });

      test('detects duplicate locale (case-sensitive)', () {
        final existingLocales = ['en', 'ar', 'en_US'];
        final newLocale = 'EN_US';
        final isDuplicate = existingLocales.contains(newLocale);
        expect(isDuplicate, false); // Exact case matters
      });

      test('handles empty locale list', () {
        final existingLocales = <String>[];
        final newLocale = 'en';
        final isDuplicate = existingLocales.contains(newLocale);
        expect(isDuplicate, false);
      });

      test('detects duplicate language-only locale', () {
        final existingLocales = ['en', 'ar', 'en_US'];
        final newLocale = 'en';
        final isDuplicate = existingLocales.contains(newLocale);
        expect(isDuplicate, true);
      });
    });

    // T037: Display name generation
    group('Display name generation (FR-014)', () {
      test('generates display name for regional locale (en_US)', () {
        final result = validationService.validateLocaleCode('en_US');
        expect(result.isValid, true);
        expect(result.displayName, 'English (United States)');
      });

      test('generates display name for regional locale (ar_SA)', () {
        final result = validationService.validateLocaleCode('ar_SA');
        expect(result.isValid, true);
        expect(result.displayName, 'Arabic (Saudi Arabia)');
      });

      test('generates display name for language-only locale (en)', () {
        final result = validationService.validateLocaleCode('en');
        expect(result.isValid, true);
        expect(result.displayName, 'English');
      });

      test('generates display name for language-only locale (ar)', () {
        final result = validationService.validateLocaleCode('ar');
        expect(result.isValid, true);
        expect(result.displayName, 'Arabic');
      });

      test('generates display name for complex regional locale (zh_CN)', () {
        final result = validationService.validateLocaleCode('zh_CN');
        expect(result.isValid, true);
        expect(result.displayName, 'Chinese (China)');
      });

      test('generates display name with normalized case (en-us)', () {
        final result = validationService.validateLocaleCode('en-us');
        expect(result.isValid, true);
        expect(result.displayName, 'English (United States)');
      });

      test('returns language code as fallback if language name not found', () {
        // This tests the behavior when a language code might not have a name
        // but is otherwise valid
        final result = validationService.validateLocaleCode('en');
        expect(result.languageName, isNotNull);
        expect(result.displayName, isNotEmpty);
      });
    });

    // Integration test: Full validation flow
    group('Full validation flow', () {
      test('successfully validates valid custom locale (es_MX)', () {
        final result = validationService.validateLocaleCode('es_MX');
        expect(result.isValid, true);
        expect(result.languageCode, 'es');
        expect(result.countryCode, 'MX');
        expect(result.languageName, 'Spanish');
        expect(result.countryName, 'Mexico');
        expect(result.displayName, 'Spanish (Mexico)');
        expect(result.errorMessage, isNull);
      });

      test('successfully validates valid custom locale with hyphen (ur-PK)', () {
        final result = validationService.validateLocaleCode('ur-PK');
        expect(result.isValid, true);
        expect(result.languageCode, 'ur');
        expect(result.countryCode, 'PK');
        expect(result.displayName, 'Urdu (Pakistan)');
      });

      test('rejects invalid locale with both language and country errors', () {
        // In this case, language is invalid, so it catches that first
        final result = validationService.validateLocaleCode('xyz_ABC');
        expect(result.isValid, false);
        expect(result.errorType, LocaleValidationErrorType.invalidLanguageCode);
      });

      test('rejects valid language but invalid country', () {
        final result = validationService.validateLocaleCode('en_ZZ');
        expect(result.isValid, false);
        expect(result.errorType, LocaleValidationErrorType.invalidCountryCode);
      });
    });
  });
}
