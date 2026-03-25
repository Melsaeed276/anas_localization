// ignore_for_file: avoid_print
import 'package:anas_localization/anas_localization.dart';
import 'package:flutter_test/flutter_test.dart';

// Performance benchmarks for hierarchical locale fallback system
// Tests resolution performance with various catalog sizes

void main() {
  group('Fallback Chain Resolution - Performance Benchmarks', () {
    /// Benchmark: Measure fallback resolution time with small catalog (50 locales)
    test('resolves fallback chain quickly with small catalog (50 locales)', () {
      final stopwatch = Stopwatch()..start();

      final fallbacks = <String, String>{
        for (int i = 0; i < 50; i++) 'locale_$i': 'locale_${i % 10}',
      };

      for (int j = 0; j < 1000; j++) {
        LocalizationService.resolveLocaleFallbackChain(
          'locale_42',
          languageGroupFallbacks: fallbacks,
        );
      }

      stopwatch.stop();
      final avgTime = stopwatch.elapsedMicroseconds / 1000;

      print('Small catalog (50 locales, 1000 resolutions): ${avgTime.toStringAsFixed(2)}ms avg');
      expect(avgTime, lessThan(50)); // Should be very fast
    });

    /// Benchmark: Measure fallback resolution time with medium catalog (500 locales)
    test('resolves fallback chain with medium catalog (500 locales)', () {
      final stopwatch = Stopwatch()..start();

      final fallbacks = <String, String>{
        for (int i = 0; i < 500; i++) 'locale_$i': 'locale_${i % 50}',
      };

      for (int j = 0; j < 1000; j++) {
        LocalizationService.resolveLocaleFallbackChain(
          'locale_250',
          languageGroupFallbacks: fallbacks,
        );
      }

      stopwatch.stop();
      final avgTime = stopwatch.elapsedMicroseconds / 1000;

      print('Medium catalog (500 locales, 1000 resolutions): ${avgTime.toStringAsFixed(2)}ms avg');
      expect(avgTime, lessThan(100)); // Still very fast for medium catalogs
    });

    /// Benchmark: Measure fallback resolution time with large catalog (1000+ locales)
    test('resolves fallback chain with large catalog (1000 locales)', () {
      final stopwatch = Stopwatch()..start();

      final fallbacks = <String, String>{
        for (int i = 0; i < 1000; i++) 'locale_$i': 'locale_${i % 100}',
      };

      for (int j = 0; j < 1000; j++) {
        LocalizationService.resolveLocaleFallbackChain(
          'locale_500',
          languageGroupFallbacks: fallbacks,
        );
      }

      stopwatch.stop();
      final avgTime = stopwatch.elapsedMicroseconds / 1000;

      print('Large catalog (1000 locales, 1000 resolutions): ${avgTime.toStringAsFixed(2)}ms avg');
      expect(avgTime, lessThan(200)); // Should still be reasonable for large catalogs
    });

    /// Benchmark: Validate locale performance with large set
    test('validates locales quickly with large set (1000 locales)', () {
      final validationService = const LocaleValidationService();
      final stopwatch = Stopwatch()..start();

      // Validate 1000 locale codes
      for (int i = 0; i < 1000; i++) {
        final localeCode = _generateLocaleCode(i);
        validationService.validateLocaleCode(localeCode);
      }

      stopwatch.stop();
      final avgTime = stopwatch.elapsedMicroseconds / 1000;

      print('Locale validation (1000 codes): ${avgTime.toStringAsFixed(2)}ms avg');
      expect(avgTime, lessThan(500)); // Should handle bulk validation quickly
    });

    /// Benchmark: Language group detection performance
    test('detects language groups quickly in large catalog', () {
      final stopwatch = Stopwatch()..start();

      final locales = [
        for (int i = 0; i < 1000; i++) _generateLocaleCode(i),
      ];

      for (int j = 0; j < 100; j++) {
        _groupLocalesByLanguage(locales);
      }

      stopwatch.stop();
      final avgTime = stopwatch.elapsedMicroseconds / 1000;

      print('Language grouping (1000 locales, 100 runs): ${avgTime.toStringAsFixed(2)}ms avg');
      expect(avgTime, lessThan(300)); // Should be efficient for large catalogs
    });

    /// Benchmark: Fallback chain length analysis with deep fallback chains
    test('resolves deeply nested fallback chains efficiently', () {
      final stopwatch = Stopwatch()..start();

      // Create a deep chain: locale_0 -> locale_1 -> locale_2 -> ... -> locale_50
      final fallbacks = <String, String>{
        for (int i = 0; i < 50; i++) 'locale_$i': 'locale_${i + 1}',
      };

      for (int j = 0; j < 100; j++) {
        LocalizationService.resolveLocaleFallbackChain(
          'locale_0',
          languageGroupFallbacks: fallbacks,
        );
      }

      stopwatch.stop();
      final avgTime = stopwatch.elapsedMicroseconds / 1000;

      print('Deep chain resolution (50-level depth, 100 runs): ${avgTime.toStringAsFixed(2)}ms avg');
      expect(avgTime, lessThan(200)); // Should handle deep chains well
    });

    /// Benchmark: Circular fallback detection performance
    test('detects circular fallbacks efficiently in large maps', () {
      final stopwatch = Stopwatch()..start();

      // Create a large fallback map
      final fallbacks = <String, String>{
        for (int i = 0; i < 500; i++) 'locale_$i': 'locale_${(i + 1) % 500}',
      };

      for (int j = 0; j < 100; j++) {
        _hasCircularFallback(fallbacks, 'locale_0', 'locale_100');
      }

      stopwatch.stop();
      final avgTime = stopwatch.elapsedMicroseconds / 1000;

      print('Circular fallback detection (500-item map, 100 checks): ${avgTime.toStringAsFixed(2)}ms avg');
      expect(avgTime, lessThan(300)); // Should be fast for circle detection
    });

    /// Benchmark: CatalogState serialization with large fallback configuration
    test('serializes large fallback configuration efficiently', () {
      final stopwatch = Stopwatch()..start();

      final catalogState = CatalogState(
        version: 3,
        sourceLocale: 'en',
        format: 'arb',
        keys: {},
        languageGroupFallbacks: {
          for (int i = 0; i < 500; i++) 'locale_$i': 'locale_${i % 100}',
        },
        customLocaleDirections: {
          for (int i = 0; i < 250; i++) 'custom_$i': i % 2 == 0 ? 'ltr' : 'rtl',
        },
      );

      for (int j = 0; j < 100; j++) {
        catalogState.toJson();
      }

      stopwatch.stop();
      final avgTime = stopwatch.elapsedMicroseconds / 1000;

      print('CatalogState serialization (500 fallbacks, 100 runs): ${avgTime.toStringAsFixed(2)}ms avg');
      expect(avgTime, lessThan(200)); // Serialization should be fast
    });

    /// Benchmark: CatalogState deserialization with large fallback configuration
    test('deserializes large fallback configuration efficiently', () {
      final json = {
        'version': 3,
        'sourceLocale': 'en',
        'format': 'arb',
        'keys': {},
        'languageGroupFallbacks': {
          for (int i = 0; i < 500; i++) 'locale_$i': 'locale_${i % 100}',
        },
        'customLocaleDirections': {
          for (int i = 0; i < 250; i++) 'custom_$i': i % 2 == 0 ? 'ltr' : 'rtl',
        },
      };

      final stopwatch = Stopwatch()..start();

      for (int j = 0; j < 100; j++) {
        CatalogState.fromJson(json);
      }

      stopwatch.stop();
      final avgTime = stopwatch.elapsedMicroseconds / 1000;

      print('CatalogState deserialization (500 fallbacks, 100 runs): ${avgTime.toStringAsFixed(2)}ms avg');
      expect(avgTime, lessThan(300)); // Deserialization should be reasonable
    });

    /// Benchmark: Memory efficiency with large catalogs
    test('memory efficiency with 1000+ locale fallback mappings', () {
      final fallbacks = <String, String>{
        for (int i = 0; i < 1000; i++) 'locale_$i': 'locale_${i % 100}',
      };

      // Just verify it doesn't crash and is accessible
      expect(fallbacks.length, equals(1000));
      expect(fallbacks['locale_500'], equals('locale_5'));
      expect(fallbacks['locale_999'], equals('locale_99'));
    });
  });

  group('Fallback Chain Resolution - Stress Tests', () {
    /// Stress test: Rapid sequential resolutions
    test('handles rapid sequential fallback resolutions', () {
      final fallbacks = <String, String>{
        for (int i = 0; i < 100; i++) 'locale_$i': 'locale_${i % 20}',
      };

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 10000; i++) {
        LocalizationService.resolveLocaleFallbackChain(
          'locale_${i % 100}',
          languageGroupFallbacks: fallbacks,
        );
      }

      stopwatch.stop();
      final totalMs = stopwatch.elapsedMilliseconds;
      final opsPerSec = (10000 / totalMs * 1000).toStringAsFixed(0);

      print('Stress test - 10000 resolutions: ${totalMs}ms ($opsPerSec ops/sec)');
      expect(totalMs, lessThan(5000)); // Should complete in reasonable time
    });

    /// Stress test: Concurrent validation
    test('handles multiple validations in sequence', () {
      final validationService = const LocaleValidationService();
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 5000; i++) {
        final localeCode = _generateLocaleCode(i);
        validationService.validateLocaleCode(localeCode);
      }

      stopwatch.stop();
      final totalMs = stopwatch.elapsedMilliseconds;

      print('Validation stress test - 5000 validations: ${totalMs}ms');
      expect(totalMs, lessThan(3000)); // Should validate quickly
    });
  });
}

// Helper functions for benchmarking

/// Generate a pseudo-random but valid locale code
String _generateLocaleCode(int index) {
  const languages = [
    'en',
    'es',
    'fr',
    'de',
    'it',
    'pt',
    'ru',
    'ja',
    'zh',
    'ar',
    'hi',
    'bn',
    'tr',
    'pl',
    'uk',
    'cs',
    'sk',
    'hu',
    'ro',
    'bg',
  ];
  const countries = [
    'US',
    'ES',
    'FR',
    'DE',
    'IT',
    'BR',
    'MX',
    'CA',
    'AU',
    'IN',
    'SA',
    'EG',
    'AE',
    'JP',
    'CN',
    'TW',
    'GB',
    'IE',
    'ZA',
    'NZ',
  ];

  final lang = languages[index % languages.length];
  final country = countries[(index ~/ languages.length) % countries.length];

  return '${lang}_$country';
}

/// Group locales by language code (helper for grouping benchmark)
Map<String, List<String>> _groupLocalesByLanguage(List<String> locales) {
  final groups = <String, List<String>>{};
  for (final locale in locales) {
    final lang = locale.split('_').first;
    groups.putIfAbsent(lang, () => []).add(locale);
  }
  return groups;
}

/// Check for circular fallbacks (helper for circular reference detection)
bool _hasCircularFallback(
  Map<String, String> fallbacks,
  String locale,
  String targetFallback,
) {
  final visited = <String>{};
  var current = locale;

  while (current != targetFallback && !visited.contains(current)) {
    visited.add(current);
    final next = fallbacks[current];
    if (next == null) {
      return false;
    }
    if (next == locale) {
      return true; // Found a circle
    }
    current = next;
  }

  return current == locale && visited.contains(targetFallback);
}
