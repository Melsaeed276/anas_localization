import 'package:anas_localization/anas_localization.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
