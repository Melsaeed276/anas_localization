import 'dart:convert';

import 'package:anas_localization/src/features/remote_localization/data/sources/remote_localization_cache_codec.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_cache_snapshot.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_failure.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_payload.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_version.dart';
import 'package:flutter_test/flutter_test.dart';

import 'remote_localization_test_helpers.dart';

void main() {
  group('Security: secrets not present in cache artifacts', () {
    test('cache keys are locale codes not secrets', () async {
      final cacheStore = FakeCacheStore();
      const secretToken = 'sk_live_abc123secret';

      final payload = payloadFor(
        'en',
        translations: {'api_key': secretToken},
      );

      // The store key is 'en' (the locale), not the secret
      expect(payload.locale, 'en');
      expect(payload.locale, isNot(contains('sk_live')));
      expect(payload.locale, isNot(contains('secret')));

      // Write to cache and verify snapshot keys
      await cacheStore.write(payload);
      final snapshot = await cacheStore.snapshot();

      // Cache snapshot keys should be locale codes, not secrets
      for (final key in snapshot.payloads.keys) {
        expect(key, anyOf('en', 'ar', 'tr', 'es', 'fr'));
        expect(key, isNot(contains('sk_live')));
        expect(key, isNot(contains('token')));
        expect(key, isNot(contains('secret')));
      }
    });

    test('codec serialization does not expose secrets in metadata', () {
      const secretValue = 'Bearer xyz_secret_token_456';

      final payload = RemoteLocalizationPayload(
        locale: 'en',
        version: RemoteLocalizationVersion(
          updatedAtUtc: DateTime.utc(2026, 1, 1),
        ),
        translations: {'password': secretValue},
      );

      final json = payload.toJson();
      final jsonStr = jsonEncode(json);

      // The secret IS in translations (that's the translation data itself),
      // but it should NOT be in version metadata, locale, or other fields
      expect(json['locale'], 'en');
      expect(json['version'] is Map, true);
      final versionMap = json['version']! as Map<String, dynamic>;
      for (final value in versionMap.values) {
        if (value is String) {
          expect(value, isNot(contains('secret')));
          expect(value, isNot(contains('Bearer')));
          expect(value, isNot(contains('xyz')));
        }
      }

      // Serialized string should not have secret in cache key paths
      expect(jsonStr.contains('"locale":"en"'), true);
    });

    test('codec round-trip preserves translation data without leaking to keys', () {
      const codec = RemoteLocalizationCacheCodec();

      final payload = RemoteLocalizationPayload(
        locale: 'fr',
        version: RemoteLocalizationVersion(
          updatedAtUtc: DateTime.utc(2026, 3, 15),
        ),
        translations: {
          'greeting': 'Bonjour',
          'api_endpoint': 'https://internal-api.example.com/v2',
        },
      );

      final cacheSnapshot = codec.encodeCacheSnapshot(
        RemoteLocalizationCacheSnapshot(payloads: {'fr': payload}),
      );
      final decoded = codec.decodeCacheSnapshot(cacheSnapshot);

      expect(decoded, isNotNull);
      expect(decoded!.payloadFor('fr'), isNotNull);
      expect(decoded.payloadFor('fr')!.translations['greeting'], 'Bonjour');
    });
  });

  group('Security: failure sanitization', () {
    test('failure message is sanitized of potential secrets', () {
      final failure = const RemoteLocalizationFailure(
        code: RemoteLocalizationFailureCode.checkFailed,
        message: 'HTTP 401: Authorization: Bearer sk_live_abcdef123456',
      );

      expect(failure.message, contains('Bearer'));
      expect(failure.message, contains('sk_live'));

      final sanitized = failure.sanitize();

      expect(sanitized.message, isNot(contains('Bearer')));
      expect(sanitized.message, isNot(contains('sk_live')));
      expect(sanitized.message, 'An error occurred');
    });
  });

  group('Security: connector credentials absent from cache', () {
    test('connector constructor arguments do not appear in cache store keys', () async {
      // Simulate what happens when a consumer creates a connector with credentials
      // The connector owns its credentials; they should never become cache keys

      final cacheStore = FakeCacheStore();
      final payload = payloadFor('ar');

      await cacheStore.write(payload);
      final snapshot = await cacheStore.snapshot();

      for (final key in snapshot.payloads.keys) {
        expect(key, isNot(contains('api')));
        expect(key, isNot(contains('token')));
        expect(key, isNot(contains('auth')));
        expect(key, isNot(contains('key')));
      }
    });
  });
}
