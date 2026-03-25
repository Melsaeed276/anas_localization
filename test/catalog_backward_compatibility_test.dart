import 'package:anas_localization/anas_localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Backward Compatibility Tests', () {
    test(
      'T066: Catalog state without languageGroupFallbacks field loads with empty defaults',
      () {
        // Simulate a legacy catalog_state.json without the new field
        final legacyJson = {
          'version': 1,
          'sourceLocale': 'en',
          'format': 'arb',
          'keys': {},
          // languageGroupFallbacks is omitted
          // customLocaleDirections is omitted
        };

        // Should deserialize without errors
        final state = CatalogState.fromJson(legacyJson);

        expect(state.version, equals(3)); // Version is auto-upgraded to 3
        expect(state.sourceLocale, equals('en'));
        expect(state.format, equals('arb'));
        expect(state.languageGroupFallbacks, isEmpty);
        expect(state.customLocaleDirections, isEmpty);
      },
    );

    test(
      'T066: Catalog state with empty languageGroupFallbacks field deserializes correctly',
      () {
        // Legacy file with explicit empty map
        final legacyJson = {
          'version': 1,
          'sourceLocale': 'en',
          'format': 'arb',
          'keys': {},
          'languageGroupFallbacks': {},
          'customLocaleDirections': {},
        };

        final state = CatalogState.fromJson(legacyJson);

        expect(state.languageGroupFallbacks, isEmpty);
        expect(state.customLocaleDirections, isEmpty);
      },
    );

    test(
      'T066: New catalog state with fallbacks serializes and deserializes correctly',
      () {
        // Create a state with the new fields populated
        final stateWithFallbacks = CatalogState(
          version: 1,
          sourceLocale: 'en',
          format: 'arb',
          keys: {},
          languageGroupFallbacks: {
            'ar_SA': 'ar_EG',
            'ar_AE': 'ar_EG',
          },
          customLocaleDirections: {
            'ur_PK': 'rtl',
            'es_MX': 'ltr',
          },
        );

        // Serialize to JSON
        final json = stateWithFallbacks.toJson();

        // Verify the new fields are included
        expect(json['languageGroupFallbacks'], isNotNull);
        expect(json['languageGroupFallbacks']['ar_SA'], equals('ar_EG'));
        expect(json['customLocaleDirections'], isNotNull);
        expect(json['customLocaleDirections']['ur_PK'], equals('rtl'));

        // Deserialize back
        final restored = CatalogState.fromJson(json);

        expect(restored.languageGroupFallbacks['ar_SA'], equals('ar_EG'));
        expect(restored.customLocaleDirections['ur_PK'], equals('rtl'));
      },
    );

    test(
      'T066: Migration from legacy state (no fields) to new state (with fields)',
      () {
        // Start with legacy state
        final legacyJson = {
          'version': 1,
          'sourceLocale': 'en',
          'format': 'arb',
          'keys': {
            'greeting': {
              'en': 'Hello',
              'ar': 'مرحبا',
            },
          },
        };

        // Load as legacy
        final legacyState = CatalogState.fromJson(legacyJson);
        expect(legacyState.languageGroupFallbacks, isEmpty);

        // Create new state with same keys but with fallbacks
        final migratedState = legacyState.copyWith(
          languageGroupFallbacks: <String, String>{'ar_SA': 'ar_EG'},
        );

        expect(migratedState.languageGroupFallbacks['ar_SA'], equals('ar_EG'));
        expect(migratedState.keys, equals(legacyState.keys)); // Keys preserved
      },
    );

    test(
      'T066: Partial field presence (only languageGroupFallbacks, no customLocaleDirections)',
      () {
        // A state that has only one of the new fields
        final partialJson = {
          'version': 1,
          'sourceLocale': 'en',
          'format': 'arb',
          'keys': {},
          'languageGroupFallbacks': {
            'es_AR': 'es_MX',
          },
          // customLocaleDirections omitted
        };

        final state = CatalogState.fromJson(partialJson);

        expect(state.languageGroupFallbacks, isNotEmpty);
        expect(state.languageGroupFallbacks['es_AR'], equals('es_MX'));
        expect(state.customLocaleDirections, isEmpty); // Defaults to empty
      },
    );

    test(
      'T066: Large legacy catalog state with many keys loads without error',
      () {
        // Create a realistically large legacy state
        final keys = <String, Map<String, dynamic>>{};
        for (int i = 0; i < 100; i++) {
          keys['key_$i'] = {
            'en': 'English value $i',
            'ar': 'قيمة عربية $i',
            'fr': 'Valeur française $i',
          };
        }

        final largeJson = {
          'version': 1,
          'sourceLocale': 'en',
          'format': 'arb',
          'keys': keys,
          // No new fields
        };

        // Should load without errors despite large size
        final state = CatalogState.fromJson(largeJson);
        expect(state.keys.length, equals(100));
        expect(state.languageGroupFallbacks, isEmpty);
      },
    );

    test(
      'T066: Version compatibility - different versions handle fields correctly',
      () {
        // Test that legacy versions are upgraded to current version (3)
        for (final version in [1, 2, 3]) {
          final json = {
            'version': version,
            'sourceLocale': 'en',
            'format': 'arb',
            'keys': {},
            // new fields omitted for version compatibility test
          };

          final state = CatalogState.fromJson(json);
          expect(state.version, equals(3)); // All versions auto-upgrade to 3
          expect(state.languageGroupFallbacks, isEmpty);
          expect(state.customLocaleDirections, isEmpty);
        }
      },
    );
  });
}
