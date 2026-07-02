import 'package:anas_localization/src/features/catalog/use_cases/catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fallback Helper Functions', () {
    /// T020: Test hasCircularFallback() helper
    test('hasCircularFallback detects direct self-reference', () {
      final fallbacks = <String, String>{};
      expect(hasCircularFallback(fallbacks, 'ar_SA', 'ar_SA'), isTrue);
    });

    test('hasCircularFallback detects two-step cycle', () {
      final fallbacks = <String, String>{'ar_SA': 'ar_EG'};
      expect(hasCircularFallback(fallbacks, 'ar_EG', 'ar_SA'), isTrue);
    });

    test('hasCircularFallback allows valid chain', () {
      final fallbacks = <String, String>{'ar_SA': 'ar_EG'};
      expect(hasCircularFallback(fallbacks, 'ar_EG', 'ar'), isFalse);
    });

    /// T020: Test resolveFallbackChain() helper
    test('resolveFallbackChain returns single locale when no fallback', () {
      final fallbacks = <String, String>{};
      expect(resolveFallbackChain(fallbacks, 'ar_SA'), equals(['ar_SA']));
    });

    test('resolveFallbackChain resolves multi-step chain', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar_AE',
        'ar_AE': 'ar',
      };
      expect(
        resolveFallbackChain(fallbacks, 'ar_SA'),
        equals(['ar_SA', 'ar_EG', 'ar_AE', 'ar']),
      );
    });

    /// T021: Test getLanguageCode() helper
    test('getLanguageCode extracts language from regional locale', () {
      expect(getLanguageCode('en_US'), equals('en'));
      expect(getLanguageCode('ar_SA'), equals('ar'));
      expect(getLanguageCode('zh_CN'), equals('zh'));
    });

    test('getLanguageCode returns language-only code as-is', () {
      expect(getLanguageCode('en'), equals('en'));
      expect(getLanguageCode('ar'), equals('ar'));
    });

    /// T021a: Test sameLanguageGroup() helper
    test('sameLanguageGroup recognizes same regional locales', () {
      expect(sameLanguageGroup('en_US', 'en_GB'), isTrue);
      expect(sameLanguageGroup('ar_SA', 'ar_EG'), isTrue);
    });

    test('sameLanguageGroup recognizes regional and language-only', () {
      expect(sameLanguageGroup('en_US', 'en'), isTrue);
      expect(sameLanguageGroup('ar_SA', 'ar'), isTrue);
      expect(sameLanguageGroup('en', 'en_US'), isTrue);
    });

    test('sameLanguageGroup rejects different language groups', () {
      expect(sameLanguageGroup('en_US', 'ar_SA'), isFalse);
      expect(sameLanguageGroup('fr_FR', 'de_DE'), isFalse);
    });

    test('sameLanguageGroup rejects different language-only codes', () {
      expect(sameLanguageGroup('en', 'ar'), isFalse);
      expect(sameLanguageGroup('fr', 'de'), isFalse);
    });
  });
}
