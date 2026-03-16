import 'package:anas_localization/anas_localization.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test loader that returns predefined maps by path suffix (e.g. en, en_US).
class _MapTranslationLoader extends TranslationLoader {
  _MapTranslationLoader(this._data);

  final Map<String, Map<String, dynamic>> _data;

  @override
  String get id => 'test_map';

  @override
  List<String> get fileExtensions => const ['json'];

  @override
  Future<Map<String, dynamic>?> load(String basePath) async {
    for (final entry in _data.entries) {
      if (basePath.endsWith(entry.key) || basePath == entry.key) return entry.value;
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocalizationService().clear();
    LocalizationService.clearPreviewDictionaries();
    LocalizationService.resetTranslationLoaders();
    LocalizationService.setFallbackLocaleCode('en');
    LocalizationService.supportedLocales = ['en', 'tr', 'ar'];
  });

  group('LocalizationService', () {
    test('loads supported locale and returns correct dictionary', () async {
      await LocalizationService().loadLocale('en');
      final dict = LocalizationService().currentDictionary;
      expect(dict, isNotNull); // Use the dict variable
    });

    test('loads another supported locale', () async {
      await LocalizationService().loadLocale('tr');
      final dict = LocalizationService().currentDictionary;
      expect(dict, isNotNull); // Use the dict variable
    });

    test('throws UnsupportedLocaleException for unsupported locale', () async {
      expect(
        () => LocalizationService().loadLocale('fr'),
        throwsA(isA<UnsupportedLocaleException>()),
      );
    });

    test('currentDictionary returns empty dictionary before loading', () {
      final dict = LocalizationService().currentDictionary;
      expect(dict.getString('missing_key'), equals('missing_key'));
    });

    test('returns null for currentLocale before loading', () {
      expect(LocalizationService().currentLocale, isNull);
    });

    test('clear() resets locale and dictionary', () async {
      await LocalizationService().loadLocale('en');
      expect(LocalizationService().currentLocale, equals('en'));
      LocalizationService().clear();
      LocalizationService.clearPreviewDictionaries();
      expect(LocalizationService().currentLocale, isNull);
      expect(LocalizationService().currentDictionary.getString('missing_key'), equals('missing_key'));
    });

    test('gracefully falls back to English if loading a locale fails', () async {
      const fakeLocale = 'zz';
      final originalLocales = List<String>.from(LocalizationService.supportedLocales);
      LocalizationService.supportedLocales.add(fakeLocale);
      try {
        await LocalizationService().loadLocale(fakeLocale);
        expect(LocalizationService().currentLocale, equals('en'));
        final dict = LocalizationService().currentDictionary;
        expect(dict, isNotNull); // Use the dict variable
      } finally {
        // Always reset to original to avoid affecting other tests
        LocalizationService.supportedLocales = originalLocales;
      }
    });

    test('loadDictionaryForLocale falls back to English when locale assets are missing', () async {
      const fakeLocale = 'zz';
      final originalLocales = List<String>.from(LocalizationService.supportedLocales);
      LocalizationService.supportedLocales.add(fakeLocale);
      try {
        final dict = await LocalizationService().loadDictionaryForLocale(fakeLocale);
        expect(dict, isNotNull);
      } finally {
        LocalizationService.supportedLocales = originalLocales;
      }
    });

    test('allSupportedLocales returns list of supported locales', () {
      final locales = LocalizationService.allSupportedLocales;
      expect(locales, containsAll(['en', 'tr', 'ar']));
    });

    test('resolves script-aware fallback chain deterministically', () async {
      LocalizationService.configure(
        locales: ['zh_Hant', 'zh', 'en'],
        fallbackLocaleCode: 'en',
        previewDictionaries: const {
          'zh_Hant': {'hello': '你好（繁體）'},
          'zh': {'hello': '你好'},
          'en': {'hello': 'Hello'},
        },
      );

      await LocalizationService().loadLocale('zh_Hant_TW');

      expect(LocalizationService().currentLocale, equals('zh_Hant'));
      expect(LocalizationService().currentDictionary.getString('hello'), equals('你好（繁體）'));
      expect(
        LocalizationService().getLastLocaleResolutionPath(),
        equals(['zh_Hant_TW', 'zh_Hant', 'zh_TW', 'zh', 'en']),
      );
    });

    test('normalization keeps locale format stable', () {
      expect(LocalizationService.normalizeLocaleCode('EN-us'), equals('en_US'));
      expect(LocalizationService.normalizeLocaleCode('zh-hant-tw'), equals('zh_Hant_TW'));
    });

    test('falls back to same-language supported locale when exact match is unavailable', () async {
      LocalizationService.configure(
        locales: ['en_GB', 'en_US'],
        fallbackLocaleCode: 'en_GB',
        previewDictionaries: const {
          'en_GB': {'hello': 'Hello GB'},
          'en_US': {'hello': 'Hello US'},
        },
      );
      // Use only preview so en_CA has no asset and resolution falls back to en_GB
      LocalizationService.setTranslationLoaders([]);

      await LocalizationService().loadLocale('en_CA');

      // en_CA is not supported, but en_GB is the first same-language match in the fallback chain.
      expect(LocalizationService().currentLocale, equals('en_GB'));
      expect(LocalizationService().currentDictionary.getString('hello'), equals('Hello GB'));
    });

    test('regional English en_US merges base en and overlay and falls back to en for missing keys', () async {
      final baseEn = <String, dynamic>{
        'appTitle': 'Anas Catalog',
        'create': 'Create',
      };
      final overlayEnUs = <String, dynamic>{
        'appTitle': 'Anas Catalog (US)',
      };
      LocalizationService.setTranslationLoaders([
        _MapTranslationLoader({
          'en': baseEn,
          'en_US': overlayEnUs,
        }),
      ]);
      LocalizationService.configure(
        locales: ['en', 'en_US'],
        fallbackLocaleCode: 'en',
      );
      await LocalizationService().loadLocale('en_US');

      expect(LocalizationService().currentLocale, equals('en_US'));
      expect(LocalizationService().currentDictionary.getString('appTitle'), equals('Anas Catalog (US)'));
      expect(LocalizationService().currentDictionary.getString('create'), equals('Create'));
    });

    test('normalizeLocaleCode normalizes regional English hyphen to underscore', () {
      expect(LocalizationService.normalizeLocaleCode('en-US'), equals('en_US'));
      expect(LocalizationService.normalizeLocaleCode('en-GB'), equals('en_GB'));
      expect(LocalizationService.normalizeLocaleCode('en-CA'), equals('en_CA'));
      expect(LocalizationService.normalizeLocaleCode('en-AU'), equals('en_AU'));
    });
  });
}
