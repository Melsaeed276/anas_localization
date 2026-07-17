import 'package:anas_localization/anas_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'remote_localization_test_helpers.dart';

class _StaticTranslationLoader extends TranslationLoader {
  const _StaticTranslationLoader(this.data);

  final Map<String, Map<String, dynamic>> data;

  @override
  String get id => 'static_test_apply';

  @override
  List<String> get fileExtensions => const ['json'];

  @override
  Future<TranslationMap?> load(String basePath) async {
    for (final entry in data.entries) {
      if (basePath.endsWith(entry.key)) {
        return Map<String, dynamic>.from(entry.value);
      }
    }
    return null;
  }
}

final _jan12026 = DateTime.utc(2026, 1, 1);

void main() {
  group('remote localization apply-on-update', () {
    tearDown(() {
      LocalizationService().clear();
      LocalizationService.clearRemoteConfig();
      LocalizationService.resetTranslationLoaders();
    });

    test('checkForUpdates applies remote translations to the live dictionary', () async {
      const localeCode = 'en';
      final cacheStore = FakeCacheStore();

      LocalizationService.registerTranslationLoader(
        const _StaticTranslationLoader({
          'assets/lang/en': {'baseKey': 'base'},
          'packages/anas_localization/assets/lang/en': {},
        }),
        highestPriority: true,
      );

      final connector = FakeConnector(
        onCheckForUpdates: (_) async => RemoteCheckResponse(
          descriptors: [
            RemoteUpdateDescriptor(
              locale: localeCode,
              version: RemoteLocalizationVersion(
                updatedAtUtc: _jan12026,
              ),
            ),
          ],
        ),
        onDownloadPayload: (update) async => RemoteLocalizationPayload(
          locale: update.locale,
          version: update.version,
          translations: {'remoteKey': 'remoteValue'},
        ),
      );

      LocalizationService.configure(
        appAssetPath: 'assets/lang',
        locales: [localeCode],
        fallbackLocaleCode: localeCode,
        remote: RemoteLocalizationConfig(
          connector: connector,
          cacheStore: cacheStore,
        ),
      );

      final coordinator = LocalizationService.remoteService;

      // Load the base dictionary first — remote key must NOT resolve yet.
      await LocalizationService().loadLocale(localeCode);
      expect(
        LocalizationService().currentDictionary.getString('remoteKey'),
        'remoteKey',
      );

      final result = await coordinator.checkForUpdates();
      expect(result.status, RemoteLocalizationUpdateStatus.updated);

      // After a successful check the remote string must be merged into the
      // live dictionary without a manual reload.
      expect(
        LocalizationService().currentDictionary.getString('remoteKey'),
        'remoteValue',
      );
      // Base (non-remote) keys remain intact.
      expect(
        LocalizationService().currentDictionary.getString('baseKey'),
        'base',
      );
    });

    test('applyRemoteUpdates re-merges cached translations for current locale', () async {
      const localeCode = 'en';
      final cache = FakeCacheStore();
      await cache.write(
        RemoteLocalizationPayload(
          locale: localeCode,
          version: RemoteLocalizationVersion(updatedAtUtc: _jan12026),
          translations: {'lateKey': 'lateValue'},
        ),
      );

      LocalizationService.registerTranslationLoader(
        const _StaticTranslationLoader({
          'assets/lang/en': {'k': 'v'},
          'packages/anas_localization/assets/lang/en': {},
        }),
        highestPriority: true,
      );

      LocalizationService.configure(
        appAssetPath: 'assets/lang',
        locales: [localeCode],
        fallbackLocaleCode: localeCode,
        remote: RemoteLocalizationConfig(
          connector: FakeConnector(),
          cacheStore: cache,
        ),
      );
      await LocalizationService().loadLocale(localeCode);

      await LocalizationService().applyRemoteUpdates();

      expect(
        LocalizationService().currentDictionary.getString('lateKey'),
        'lateValue',
      );
    });
  });
}
