import 'package:anas_localization/anas_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'remote_localization_test_helpers.dart';

class _StaticTranslationLoader extends TranslationLoader {
  const _StaticTranslationLoader(this.data);

  final Map<String, Map<String, dynamic>> data;

  @override
  String get id => 'static_test';

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

void main() {
  setUp(() {
    LocalizationService.clearRemoteConfig();
    LocalizationService.resetTranslationLoaders();
  });

  group('US1: No Remote Config', () {
    test('configure with no remote config keeps local-only behavior', () {
      LocalizationService.configure(
        appAssetPath: 'assets/lang',
        locales: ['en', 'ar'],
      );

      final config = LocalizationService.remoteConfig;
      expect(config, isNull);

      final service = LocalizationService.remoteService;
      expect(service, isNotNull);
    });

    test('remote service returns unsupported when no config set', () async {
      final service = LocalizationService.remoteService;
      final result = await service.checkForUpdates();

      expect(result.status, RemoteLocalizationUpdateStatus.unsupported);
    });
  });

  group('US1: Remote with checkOnStartup: false', () {
    test('configured remote with checkOnStartup false does not call connector during startup', () {
      final connector = FakeConnector();
      var connectorCalled = false;
      connector.onCheckForUpdates = (_) async {
        connectorCalled = true;
        return const RemoteCheckResponse(descriptors: []);
      };

      LocalizationService.configure(
        appAssetPath: 'assets/lang',
        locales: ['en'],
        remote: RemoteLocalizationConfig(
          connector: connector,
          checkOnStartup: false,
        ),
      );

      expect(connectorCalled, false);
      expect(LocalizationService.remoteConfig, isNotNull);
      expect(LocalizationService.remoteConfig!.checkOnStartup, false);
    });
  });

  group('US1: Remote with checkOnStartup: true', () {
    test('remote config is available', () {
      final connector = FakeConnector();
      LocalizationService.configure(
        appAssetPath: 'assets/lang',
        locales: ['en'],
        remote: RemoteLocalizationConfig(
          connector: connector,
          checkOnStartup: true,
        ),
      );

      expect(LocalizationService.remoteConfig, isNotNull);
      expect(LocalizationService.remoteConfig!.checkOnStartup, true);
    });
  });

  group('US3: Remote cache merge during locale loading', () {
    test('cached remote data merges after package and app assets respecting override: false', () async {
      final loader = const _StaticTranslationLoader({
        'packages/anas_localization/assets/lang/en': {
          'key1': 'pkg_val',
          'key2': 'pkg_val',
        },
        'assets/lang/en': {
          'key1': 'app_val',
          'key2': {'value': 'app_protected', '__override__': false},
        },
      });
      LocalizationService.registerTranslationLoader(loader, highestPriority: true);

      final cacheStore = FakeCacheStore();
      await cacheStore.write(
        payloadFor(
          'en',
          translations: {
            'key1': 'remote_val',
            'key2': 'remote_val',
          },
        ),
      );

      LocalizationService.configure(
        appAssetPath: 'assets/lang',
        locales: ['en'],
        remote: RemoteLocalizationConfig(
          connector: FakeConnector(),
          cacheStore: cacheStore,
        ),
      );

      final dict = await LocalizationService().loadDictionaryForLocale('en');

      expect(dict.getString('key1'), 'remote_val');
      expect(dict.getString('key2'), 'app_protected');
    });

    test('remote cache adds new keys not present in package or app data', () async {
      final loader = const _StaticTranslationLoader({
        'packages/anas_localization/assets/lang/en': {
          'existing_key': 'pkg_val',
        },
        'assets/lang/en': {
          'existing_key': 'app_val',
        },
      });
      LocalizationService.registerTranslationLoader(loader, highestPriority: true);

      final cacheStore = FakeCacheStore();
      await cacheStore.write(
        payloadFor(
          'en',
          translations: {
            'new_key': 'remote_new_val',
          },
        ),
      );

      LocalizationService.configure(
        appAssetPath: 'assets/lang',
        locales: ['en'],
        remote: RemoteLocalizationConfig(
          connector: FakeConnector(),
          cacheStore: cacheStore,
        ),
      );

      final dict = await LocalizationService().loadDictionaryForLocale('en');

      expect(dict.getString('existing_key'), 'app_val');
      expect(dict.getString('new_key'), 'remote_new_val');
    });
  });

  group('US3: Fallback with corrupt or missing remote cache', () {
    test('empty remote cache falls back to local-only locale loading', () async {
      final loader = const _StaticTranslationLoader({
        'packages/anas_localization/assets/lang/en': {
          'key': 'pkg_val',
        },
        'assets/lang/en': {
          'key': 'app_val',
        },
      });
      LocalizationService.registerTranslationLoader(loader, highestPriority: true);

      final cacheStore = FakeCacheStore();

      LocalizationService.configure(
        appAssetPath: 'assets/lang',
        locales: ['en'],
        remote: RemoteLocalizationConfig(
          connector: FakeConnector(),
          cacheStore: cacheStore,
        ),
      );

      final dict = await LocalizationService().loadDictionaryForLocale('en');

      expect(dict.getString('key'), 'app_val');
    });

    test('no remote config falls back to local-only locale loading', () async {
      final loader = const _StaticTranslationLoader({
        'packages/anas_localization/assets/lang/en': {
          'key': 'pkg_val',
        },
        'assets/lang/en': {
          'key': 'app_val',
        },
      });
      LocalizationService.registerTranslationLoader(loader, highestPriority: true);

      LocalizationService.configure(
        appAssetPath: 'assets/lang',
        locales: ['en'],
      );

      final dict = await LocalizationService().loadDictionaryForLocale('en');

      expect(dict.getString('key'), 'app_val');
    });
  });
}
