import 'dart:ui' show Locale;

import 'package:anas_localization/src/features/remote_localization/data/repositories/remote_localization_repository_impl.dart';
import 'package:anas_localization/src/features/remote_localization/domain/contracts/remote_localization_connector.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_payload.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_result.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_version.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_update_descriptor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'remote_localization_test_helpers.dart';

void main() {
  group('repository global check', () {
    test('no-update global check skips downloads', () async {
      final connector = FakeConnector(
        onCheckForUpdates: (_) async => const RemoteCheckResponse(descriptors: []),
      );
      final cache = FakeCacheStore();
      final repo = RemoteLocalizationRepositoryImpl(
        connector: connector,
        cacheStore: cache,
      );

      final result = await repo.checkForUpdates();
      expect(result.status, RemoteLocalizationUpdateStatus.noUpdate);
    });

    test('global update check downloads and caches', () async {
      final newerVersion = RemoteLocalizationVersion(
        updatedAtUtc: DateTime.utc(2026, 7, 8),
      );
      final connector = FakeConnector(
        onCheckForUpdates: (_) async => RemoteCheckResponse(
          descriptors: [
            RemoteUpdateDescriptor(
              locale: 'en',
              version: newerVersion,
            ).normalize(),
          ],
        ),
        onDownloadPayload: (update) async => RemoteLocalizationPayload(
          locale: update.locale,
          version: update.version,
          translations: {'key': 'updated_value'},
        ),
      );
      final cache = FakeCacheStore();
      final repo = RemoteLocalizationRepositoryImpl(
        connector: connector,
        cacheStore: cache,
      );

      final result = await repo.checkForUpdates();
      expect(result.status, RemoteLocalizationUpdateStatus.updated);
      if (result is RemoteLocalizationUpdateSuccess) {
        expect(result.appliedLocales, ['en']);
      }

      final snapshot = await repo.readCache();
      expect(snapshot.payloadFor('en'), isNotNull);
    });

    test('per-locale check downloads and caches only requested locale', () async {
      final connector = FakeConnector(
        onCheckForLocaleUpdate: (locale, version) async => RemoteCheckResponse(
          descriptors: [
            RemoteUpdateDescriptor(
              locale: locale.toString(),
              version: RemoteLocalizationVersion(
                updatedAtUtc: DateTime.utc(2026, 7, 8),
              ),
            ).normalize(),
          ],
        ),
        onDownloadPayload: (update) async => RemoteLocalizationPayload(
          locale: update.locale,
          version: update.version,
          translations: {'key': 'per_locale_value'},
        ),
      );
      final cache = FakeCacheStore();
      final repo = RemoteLocalizationRepositoryImpl(
        connector: connector,
        cacheStore: cache,
      );

      final result = await repo.checkForLocaleUpdate(const Locale('en'));
      expect(result.status, RemoteLocalizationUpdateStatus.updated);
      if (result is RemoteLocalizationUpdateSuccess) {
        expect(result.appliedLocales, ['en']);
      }
    });

    test('unsupported global returns unsupported result', () async {
      final connector = FakeConnector(supportsGlobalCheck: false);
      final cache = FakeCacheStore();
      final repo = RemoteLocalizationRepositoryImpl(
        connector: connector,
        cacheStore: cache,
      );

      final result = await repo.checkForUpdates();
      expect(result.status, RemoteLocalizationUpdateStatus.unsupported);
    });

    test('unsupported per-locale returns unsupported result', () async {
      final connector = FakeConnector(supportsLocaleCheck: false);
      final cache = FakeCacheStore();
      final repo = RemoteLocalizationRepositoryImpl(
        connector: connector,
        cacheStore: cache,
      );

      final result = await repo.checkForLocaleUpdate(const Locale('en'));
      expect(result.status, RemoteLocalizationUpdateStatus.unsupported);
    });
  });
}
