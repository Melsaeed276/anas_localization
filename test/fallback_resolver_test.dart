import 'package:flutter_test/flutter_test.dart';
import 'package:anas_localization/src/features/localization/domain/services/fallback_resolver.dart';

void main() {
  group('FallbackResolver', () {
    group('resolveConfiguredChain', () {
      test('returns single locale if no fallback configured', () {
        final chain = resolveConfiguredChain({}, 'en');
        expect(chain, equals(['en']));
      });

      test('follows simple fallback chain', () {
        final fallbacks = {'ar_SA': 'ar'};
        final chain = resolveConfiguredChain(fallbacks, 'ar_SA');
        expect(chain, equals(['ar_SA', 'ar']));
      });

      test('follows multi-hop fallback chain', () {
        final fallbacks = {
          'ar_SA': 'ar_EG',
          'ar_EG': 'ar',
        };
        final chain = resolveConfiguredChain(fallbacks, 'ar_SA');
        expect(chain, equals(['ar_SA', 'ar_EG', 'ar']));
      });

      test('detects and stops at circular references', () {
        final fallbacks = {
          'en': 'es',
          'es': 'en', // Circular!
        };
        final chain = resolveConfiguredChain(fallbacks, 'en');
        expect(chain, equals(['en', 'es'])); // Stops before cycling back
      });

      test('handles self-reference gracefully', () {
        final fallbacks = {'en': 'en'}; // Self-reference
        final chain = resolveConfiguredChain(fallbacks, 'en');
        expect(chain, equals(['en'])); // Detects and stops
      });

      test('ignores fallback for unrelated locales', () {
        final fallbacks = {
          'ar_SA': 'ar',
          'en': 'es', // This should not affect ar_SA chain
        };
        final chain = resolveConfiguredChain(fallbacks, 'ar_SA');
        expect(chain, equals(['ar_SA', 'ar']));
      });
    });

    group('expandWithVariants', () {
      test('returns single locale if base language', () {
        final expanded = expandWithVariants('en');
        expect(expanded, equals(['en']));
      });

      test('expands regional variant with base language', () {
        final expanded = expandWithVariants('ar_SA');
        expect(expanded, equals(['ar_SA', 'ar']));
      });

      test('expands en_US with en', () {
        final expanded = expandWithVariants('en_US');
        expect(expanded, equals(['en_US', 'en']));
      });

      test('handles various regional formats', () {
        expect(expandWithVariants('zh_Hans'), equals(['zh_Hans', 'zh']));
        expect(expandWithVariants('pt_BR'), equals(['pt_BR', 'pt']));
      });
    });

    group('resolveWithDefaults', () {
      test('appends default if not in chain', () {
        final resolved = resolveWithDefaults(['ar_SA', 'ar'], 'en');
        expect(resolved, equals(['ar_SA', 'ar', 'en']));
      });

      test('does not duplicate default if already in chain', () {
        final resolved = resolveWithDefaults(['ar_SA', 'ar', 'en'], 'en');
        expect(resolved, equals(['ar_SA', 'ar', 'en']));
      });

      test('adds default to single-item chain', () {
        final resolved = resolveWithDefaults(['en'], 'es');
        expect(resolved, equals(['en', 'es']));
      });

      test('preserves order of configured chain', () {
        final chain = ['ar_SA', 'ar_EG', 'ar'];
        final resolved = resolveWithDefaults(chain, 'en');
        expect(resolved, equals(['ar_SA', 'ar_EG', 'ar', 'en']));
      });
    });

    group('resolveFallbackChainWithDefaults', () {
      test('combines configured chain with defaults', () {
        final fallbacks = {'ar_SA': 'ar'};
        final chain = resolveFallbackChainWithDefaults(
          fallbacks,
          'ar_SA',
          'en',
        );
        expect(chain, equals(['ar_SA', 'ar', 'en']));
      });

      test('handles multi-hop with defaults', () {
        final fallbacks = {
          'ar_SA': 'ar_EG',
          'ar_EG': 'ar',
        };
        final chain = resolveFallbackChainWithDefaults(
          fallbacks,
          'ar_SA',
          'en',
        );
        expect(chain, equals(['ar_SA', 'ar_EG', 'ar', 'en']));
      });

      test('handles no fallback with just default', () {
        final chain = resolveFallbackChainWithDefaults({}, 'en', 'es');
        expect(chain, equals(['en', 'es']));
      });

      test('does not duplicate default if in fallback chain', () {
        final fallbacks = {'ar_SA': 'en'};
        final chain = resolveFallbackChainWithDefaults(
          fallbacks,
          'ar_SA',
          'en',
        );
        expect(chain, equals(['ar_SA', 'en'])); // No duplicate 'en'
      });
    });

    group('Integration scenarios', () {
      test('Scenario 1: Arabic regional to base', () {
        // Setup: ar_SA → ar, default: en
        final fallbacks = {'ar_SA': 'ar'};
        final chain = resolveFallbackChainWithDefaults(
          fallbacks,
          'ar_SA',
          'en',
        );
        expect(chain, equals(['ar_SA', 'ar', 'en']));
      });

      test('Scenario 2: English variants', () {
        // Setup: No explicit fallback for en_GB, default: en
        final fallbacks = {'en_GB': 'en'};
        final chain = resolveFallbackChainWithDefaults(
          fallbacks,
          'en_GB',
          'en',
        );
        expect(chain, equals(['en_GB', 'en']));
      });

      test('Scenario 3: Complex regional chain', () {
        // Setup: ar_SA → ar_EG → ar → en
        final fallbacks = {
          'ar_SA': 'ar_EG',
          'ar_EG': 'ar',
        };
        final chain = resolveFallbackChainWithDefaults(
          fallbacks,
          'ar_SA',
          'en',
        );
        expect(chain, equals(['ar_SA', 'ar_EG', 'ar', 'en']));
      });
    });
  });
}
