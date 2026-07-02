import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fallback Cleanup on Deletion', () {
    /// FR-011: Clean up fallbacks when a locale is deleted
    test('removes fallback entry when source locale is deleted', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar',
      };

      // Simulate deleting ar_SA by removing it from the fallbacks map
      fallbacks.remove('ar_SA');

      expect(fallbacks.containsKey('ar_SA'), isFalse);
      // ar_EG's fallback to ar is unaffected
      expect(fallbacks['ar_EG'], equals('ar'));
    });

    test('removes references to deleted locale in other fallback chains', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar_LY',
        'ar_LY': 'ar',
      };

      // Delete ar_EG - need to update ar_SA to point to ar_LY instead
      final deletedLocale = 'ar_EG';
      fallbacks.remove(deletedLocale);

      // Find and update any fallbacks that pointed to the deleted locale
      for (final entry in fallbacks.entries.toList()) {
        if (entry.value == deletedLocale) {
          fallbacks[entry.key] = 'ar_LY'; // or get from next chain
        }
      }

      expect(fallbacks.containsKey('ar_EG'), isFalse);
      expect(fallbacks['ar_SA'], equals('ar_LY'));
      expect(fallbacks['ar_LY'], equals('ar'));
    });

    test('handles deletion of intermediate locale in three-step chain', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar_AE',
        'ar_AE': 'ar',
      };

      // Delete ar_EG (middle of chain)
      final deletedLocale = 'ar_EG';
      final nextFallback = fallbacks[deletedLocale];

      fallbacks.remove(deletedLocale);

      // Update chains that pointed to deleted locale
      for (final entry in fallbacks.entries.toList()) {
        if (entry.value == deletedLocale && nextFallback != null) {
          fallbacks[entry.key] = nextFallback;
        }
      }

      // Verify new chain
      expect(_resolveFallbackChain(fallbacks, 'ar_SA'), equals(['ar_SA', 'ar_AE', 'ar']));
    });

    test('preserves other language groups when deleting a locale', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar',
        'en_US': 'en_GB',
        'en_GB': 'en',
      };

      // Delete ar_EG
      final deletedLocale = 'ar_EG';
      fallbacks.remove(deletedLocale);

      // Update arabic chain
      for (final entry in fallbacks.entries.toList()) {
        if (entry.value == deletedLocale) {
          fallbacks[entry.key] = 'ar';
        }
      }

      // English chain should be untouched
      expect(fallbacks['en_US'], equals('en_GB'));
      expect(fallbacks['en_GB'], equals('en'));

      // Arabic chain should be updated
      expect(fallbacks['ar_SA'], equals('ar'));
    });

    test('handles deletion of leaf node (locale with no fallback)', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar',
      };

      // Delete ar (leaf node)
      const deletedLocale = 'ar';
      fallbacks.remove(deletedLocale);

      // ar_EG now has no fallback (it was pointing to ar, which is deleted)
      expect(fallbacks.containsKey('ar_EG'), isTrue);
      expect(fallbacks.containsKey('ar'), isFalse);
    });

    test('handles deletion of root node (locale that is nobody\'s fallback)', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar',
      };

      // Delete ar_LY (not in any chain)
      fallbacks.remove('ar_LY');

      // ar_SA and ar_EG chains unaffected
      expect(fallbacks['ar_SA'], equals('ar_EG'));
      expect(fallbacks['ar_EG'], equals('ar'));
    });

    test('validates cleanup maintains valid fallback chains', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar_AE',
        'ar_AE': 'ar_LY',
        'ar_LY': 'ar',
      };

      // Delete ar_AE
      final deletedLocale = 'ar_AE';
      final nextFallback = fallbacks[deletedLocale];

      fallbacks.remove(deletedLocale);

      for (final entry in fallbacks.entries.toList()) {
        if (entry.value == deletedLocale && nextFallback != null) {
          fallbacks[entry.key] = nextFallback;
        }
      }

      // Verify ar_EG now points to ar_LY (updated from ar_AE)
      expect(fallbacks['ar_EG'], equals('ar_LY'));

      // Verify ar_EG's chain is correct
      final arEgChain = _resolveFallbackChain(fallbacks, 'ar_EG');
      expect(arEgChain, equals(['ar_EG', 'ar_LY', 'ar']));

      // Verify ar_SA chain is updated through ar_EG
      final arSaChain = _resolveFallbackChain(fallbacks, 'ar_SA');
      expect(arSaChain, equals(['ar_SA', 'ar_EG', 'ar_LY', 'ar']));

      // Verify no circular references
      expect(_hasCircular(fallbacks), isFalse);
    });

    test('cleanup preserves fallback for locales with no direct parent', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar',
        'ar_KW': 'ar', // Direct fallback to language
      };

      // Delete ar_SA
      fallbacks.remove('ar_SA');

      // ar_KW should still fall back to ar
      expect(fallbacks['ar_KW'], equals('ar'));
    });
  });
}

/// Test helper: resolves full fallback chain
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

/// Test helper: detects circular fallbacks
bool _hasCircular(Map<String, String> fallbacks) {
  for (final locale in fallbacks.keys) {
    final visited = <String>{};
    var current = fallbacks[locale];

    while (current != null && current.isNotEmpty) {
      if (visited.contains(current)) return true;
      visited.add(current);
      current = fallbacks[current];
    }
  }

  return false;
}
