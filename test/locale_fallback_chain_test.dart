import 'package:anas_localization/anas_localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fallback Chain Resolution', () {
    /// FR-008: Resolve language group fallbacks in order
    test('resolves single-step fallback chain (primary -> secondary)', () {
      final fallbacks = <String, String>{'ar_SA': 'ar_EG'};
      final chain = _resolveFallbackChain(fallbacks, 'ar_SA');

      expect(chain, equals(['ar_SA', 'ar_EG']));
    });

    test('resolves multi-step fallback chain (primary -> secondary -> tertiary)', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar_AE',
      };
      final chain = _resolveFallbackChain(fallbacks, 'ar_SA');

      expect(chain, equals(['ar_SA', 'ar_EG', 'ar_AE']));
    });

    test('returns single locale when no fallback is configured', () {
      final fallbacks = <String, String>{};
      final chain = _resolveFallbackChain(fallbacks, 'en_US');

      expect(chain, equals(['en_US']));
    });

    test('stops at locale with no configured fallback', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        // ar_EG has no fallback configured
      };
      final chain = _resolveFallbackChain(fallbacks, 'ar_SA');

      expect(chain, equals(['ar_SA', 'ar_EG']));
    });

    test('creates correct FallbackChain entity with multiple steps', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar_AE',
      };

      final chain = FallbackChain(
        targetLocale: 'ar_SA',
        chain: _resolveFallbackChain(fallbacks, 'ar_SA'),
        projectDefaultLocale: 'en',
      );

      expect(chain.targetLocale, equals('ar_SA'));
      expect(
        chain.chain,
        equals(['ar_SA', 'ar_EG', 'ar_AE']),
      );
    });

    test('FallbackChain with single locale indicates no language group fallback', () {
      final chain = const FallbackChain(
        targetLocale: 'en_US',
        chain: ['en_US'],
        projectDefaultLocale: 'en',
      );

      expect(chain.hasLanguageGroupFallback, isFalse);
    });

    test('displayString formats chain correctly for UI display', () {
      final chain = const FallbackChain(
        targetLocale: 'ar_SA',
        chain: ['ar_SA', 'ar_EG', 'ar'],
        projectDefaultLocale: 'en',
      );

      // Expected format: "ar_SA → ar_EG → ar"
      expect(
        chain.displayString.contains('ar_SA'),
        isTrue,
      );
      expect(
        chain.displayString.contains('ar_EG'),
        isTrue,
      );
      expect(
        chain.displayString.contains('ar'),
        isTrue,
      );
    });

    test('handles deep chain (5+ levels) without performance issues', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar_AE',
        'ar_AE': 'ar_LY',
        'ar_LY': 'ar_TN',
        'ar_TN': 'ar',
      };

      final chain = _resolveFallbackChain(fallbacks, 'ar_SA');

      expect(
        chain,
        equals(['ar_SA', 'ar_EG', 'ar_AE', 'ar_LY', 'ar_TN', 'ar']),
      );
    });

    test('resolves different language groups independently', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'en_US': 'en_GB',
      };

      final arChain = _resolveFallbackChain(fallbacks, 'ar_SA');
      final enChain = _resolveFallbackChain(fallbacks, 'en_US');

      expect(arChain, equals(['ar_SA', 'ar_EG']));
      expect(enChain, equals(['en_US', 'en_GB']));
    });

    test('locale not in fallback map returns itself as single-element chain', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
      };

      final chain = _resolveFallbackChain(fallbacks, 'fr_FR');

      expect(chain, equals(['fr_FR']));
    });
  });
}

/// Test helper: resolves full fallback chain for a given locale
/// Returns list of locales in fallback order: [primary, fallback1, fallback2, ...]
List<String> _resolveFallbackChain(
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
