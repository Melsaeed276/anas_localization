import 'package:anas_localization/anas_localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Catalog Locale Full Flow Integration Tests', () {
    setUp(() {
      LocalizationService().clear();
      LocalizationService.clearPreviewDictionaries();
      LocalizationService.setFallbackLocaleCode('en');
    });

    test(
      'T063: Custom locale ISO validation integrates correctly with fallback chain resolution',
      () async {
        // ========== STEP 1: Validate Custom Locale Code ==========
        // Verify that locale codes are validated according to ISO standards
        final validationService = const LocaleValidationService();

        // Valid language codes should pass
        expect(validationService.isValidLanguageCode('es'), isTrue);
        expect(validationService.isValidLanguageCode('ar'), isTrue);
        expect(validationService.isValidLanguageCode('pt'), isTrue);

        // Invalid language codes should fail
        expect(validationService.isValidLanguageCode('xyz'), isFalse);
        expect(validationService.isValidLanguageCode('00'), isFalse);

        // Valid country codes should pass
        expect(validationService.isValidCountryCode('US'), isTrue);
        expect(validationService.isValidCountryCode('MX'), isTrue);
        expect(validationService.isValidCountryCode('BR'), isTrue);

        // Invalid country codes should fail
        expect(validationService.isValidCountryCode('ZZ'), isFalse);
        expect(validationService.isValidCountryCode('00'), isFalse);

        // ========== STEP 2: Validate Complete Locale Codes ==========
        // Complete locale code validation should check both parts
        expect(
          validationService.validateLocaleCode('es_MX'),
          isA<LocaleValidationResult>().having((r) => r.isValid, 'isValid', isTrue),
        );

        expect(
          validationService.validateLocaleCode('xyz_ABC'),
          isA<LocaleValidationResult>().having((r) => r.isValid, 'isValid', isFalse),
        );

        // ========== STEP 3: Fallback Chain Resolution with Language Groups ==========
        // When language group fallbacks are configured,
        // the fallback chain should include the language group fallback

        // Create fallback configuration
        final languageGroupFallbacks = <String, String>{
          'es_AR': 'es_MX', // es_AR should fall back to es_MX
        };

        // Resolve fallback chain for es_AR
        LocalizationService.supportedLocales = ['en', 'es_MX', 'es_AR'];
        LocalizationService.setFallbackLocaleCode('en');
        final chain = LocalizationService.resolveLocaleFallbackChain(
          'es_AR',
          languageGroupFallbacks: languageGroupFallbacks,
        );

        // Expected chain: es_AR → es_MX → es (base language) → en (default)
        // Note: Base language locale is included in the chain
        expect(chain, equals(['es_AR', 'es_MX', 'es', 'en']));

        // ========== STEP 4: Multiple Language Groups ==========
        // Multiple independent language groups should maintain separate configurations
        final multiGroupFallbacks = <String, String>{
          'es_AR': 'es_MX', // Spanish group
          'en_GB': 'en_US', // English group
          'ar_SA': 'ar_EG', // Arabic group
        };

        LocalizationService.supportedLocales = ['en', 'en_US', 'en_GB', 'es_MX', 'es_AR', 'ar_EG', 'ar_SA'];

        // Chain for Spanish variant
        final esChain = LocalizationService.resolveLocaleFallbackChain(
          'es_AR',
          languageGroupFallbacks: multiGroupFallbacks,
        );
        expect(esChain, equals(['es_AR', 'es_MX', 'es', 'en']));

        // Chain for English variant
        final enChain = LocalizationService.resolveLocaleFallbackChain(
          'en_GB',
          languageGroupFallbacks: multiGroupFallbacks,
        );
        expect(enChain, equals(['en_GB', 'en_US', 'en']));

        // Chain for Arabic variant
        final arChain = LocalizationService.resolveLocaleFallbackChain(
          'ar_SA',
          languageGroupFallbacks: multiGroupFallbacks,
        );
        expect(arChain, equals(['ar_SA', 'ar_EG', 'ar', 'en']));

        // ========== STEP 5: Empty Fallback Configuration ==========
        // When no fallback is configured, chain should be: locale → base language → default
        final noFallbackChain = LocalizationService.resolveLocaleFallbackChain(
          'pt_BR',
          languageGroupFallbacks: {},
        );

        expect(noFallbackChain, equals(['pt_BR', 'pt', 'en']));

        // ========== STEP 6: Circular Fallback Prevention ==========
        // The hasCircularFallback helper should detect circular references
        expect(
          _hasCircularFallback(
            {
              'ar_SA': 'ar_EG',
              'ar_EG': 'ar_SA', // Circular: ar_SA -> ar_EG -> ar_SA
            },
            'ar_SA',
          ),
          isTrue,
        );

        expect(
          _hasCircularFallback(
            {
              'ar_SA': 'ar_EG',
              'ar_EG': 'ar', // Not circular: ar_SA -> ar_EG -> ar (no fallback for ar)
            },
            'ar_SA',
          ),
          isFalse,
        );

        // ========== STEP 7: Locale Code Normalization ==========
        // Hyphenated codes should be normalized to underscore format
        final normalizedCode = _normalizeLocaleCode('en-US');
        expect(normalizedCode, equals('en_US'));

        final alreadyNormalized = _normalizeLocaleCode('en_US');
        expect(alreadyNormalized, equals('en_US'));
      },
    );

    test(
      'Custom locale direction configuration is preserved in catalog state',
      () async {
        // Create catalog state with custom locale directions
        final state = CatalogState(
          version: 1,
          sourceLocale: 'en',
          format: 'arb',
          keys: {},
          customLocaleDirections: {
            'ur_PK': 'rtl', // Custom Urdu (Pakistan) is RTL
            'es_MX': 'ltr', // Custom Spanish (Mexico) is LTR
            'ar_EG': 'rtl', // Custom Arabic (Egypt) is RTL
          },
        );

        expect(state.customLocaleDirections['ur_PK'], equals('rtl'));
        expect(state.customLocaleDirections['es_MX'], equals('ltr'));
        expect(state.customLocaleDirections['ar_EG'], equals('rtl'));
      },
    );

    test(
      'Language group fallback configuration is persisted in catalog state',
      () async {
        // Create catalog state with language group fallbacks
        final state = CatalogState(
          version: 1,
          sourceLocale: 'en',
          format: 'arb',
          keys: {},
          languageGroupFallbacks: {
            'ar_SA': 'ar_EG', // Saudi Arabic falls back to Egyptian Arabic
            'ar_AE': 'ar_EG', // UAE Arabic falls back to Egyptian Arabic
            'en_GB': 'en_US', // British English falls back to US English
          },
        );

        expect(state.languageGroupFallbacks['ar_SA'], equals('ar_EG'));
        expect(state.languageGroupFallbacks['ar_AE'], equals('ar_EG'));
        expect(state.languageGroupFallbacks['en_GB'], equals('en_US'));
      },
    );

    test(
      'Fallback cleanup when designated fallback locale is removed',
      () async {
        // Start with configured fallbacks
        final fallbacks = <String, String>{
          'es_AR': 'es_MX',
          'es_CO': 'es_MX', // Both point to es_MX
        };

        // Simulate removing es_MX from the locale list
        // All references should be cleaned up
        final cleaned = _cleanupFallbacksForDeletedLocale(
          fallbacks,
          'es_MX',
        );

        expect(cleaned.containsKey('es_AR'), isFalse);
        expect(cleaned.containsKey('es_CO'), isFalse);
        expect(cleaned.isEmpty, isTrue);
      },
    );

    test(
      'Backward compatibility: catalog state without new fields defaults correctly',
      () async {
        // Create state without new fields - should use defaults
        final legacyState = CatalogState(
          version: 1,
          sourceLocale: 'en',
          format: 'arb',
          keys: {},
          // languageGroupFallbacks omitted
          // customLocaleDirections omitted
        );

        expect(legacyState.languageGroupFallbacks, isEmpty);
        expect(legacyState.customLocaleDirections, isEmpty);
      },
    );

    test(
      'Same language group constraint is enforced for fallback configuration',
      () async {
        // Can only set fallback between locales of same language
        expect(
          _isSameLanguageGroup('es_MX', 'es_AR'),
          isTrue, // Both are Spanish
        );

        expect(
          _isSameLanguageGroup('es_MX', 'en_US'),
          isFalse, // Different languages
        );

        expect(
          _isSameLanguageGroup('ar_EG', 'ar_SA'),
          isTrue, // Both are Arabic
        );
      },
    );

    test(
      'Regional locale cannot be set as fallback for base language',
      () async {
        // Cannot set ar_EG (regional) as fallback for ar (base language)
        expect(
          _isRegionalLocale('ar_EG'),
          isTrue,
        );

        expect(
          _isRegionalLocale('ar'),
          isFalse,
        );

        // So this configuration would be invalid
        expect(
          _canSetAsLanguageGroupFallback('ar_EG', 'ar'),
          isFalse, // ar_EG (regional) cannot be fallback for ar (base)
        );

        // But this would be valid
        expect(
          _canSetAsLanguageGroupFallback('ar', 'ar_EG'),
          isTrue, // ar (base) can be fallback for ar_EG (regional)
        );
      },
    );
  });
}

// ========== HELPER FUNCTIONS ==========

/// Detects circular fallback chains
bool _hasCircularFallback(
  Map<String, String> fallbacks,
  String startLocale,
) {
  final visited = <String>{};
  var current = startLocale;

  while (fallbacks.containsKey(current)) {
    if (visited.contains(current)) {
      return true; // Circular reference detected
    }
    visited.add(current);
    current = fallbacks[current]!;
  }

  return false;
}

/// Normalizes locale code from hyphen to underscore format
String _normalizeLocaleCode(String localeCode) {
  return localeCode.replaceAll('-', '_');
}

/// Cleans up fallback references to a deleted locale
Map<String, String> _cleanupFallbacksForDeletedLocale(
  Map<String, String> fallbacks,
  String deletedLocale,
) {
  final cleaned = Map<String, String>.from(fallbacks);
  cleaned.removeWhere((key, value) => value == deletedLocale);
  return cleaned;
}

/// Checks if two locales share the same base language code
bool _isSameLanguageGroup(String locale1, String locale2) {
  final lang1 = locale1.split('_')[0];
  final lang2 = locale2.split('_')[0];
  return lang1 == lang2;
}

/// Checks if a locale is a regional variant (has country code)
bool _isRegionalLocale(String locale) {
  return locale.contains('_');
}

/// Checks if a locale can be set as language group fallback
/// (not a regional variant)
bool _canSetAsLanguageGroupFallback(
  String fallbackLocale,
  String targetLocale,
) {
  // Target must be regional (has country code)
  if (!_isRegionalLocale(targetLocale)) {
    return false; // Can't set fallback for base language
  }

  // Both must be same language
  if (!_isSameLanguageGroup(fallbackLocale, targetLocale)) {
    return false;
  }

  // Fallback locale can be regional or base
  return true;
}
