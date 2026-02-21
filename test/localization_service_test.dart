import 'package:anas_localization/localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset the singleton before each test (clear locale/dictionary)
    LocalizationService().clear();
    LocalizationService.clearPreviewDictionaries();
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

    test('throws for unsupported locale', () async {
      expect(() => LocalizationService().loadLocale('fr'), throwsException);
    });

    test('throws if currentDictionary is accessed before loading', () {
      expect(() => LocalizationService().currentDictionary, throwsException);
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
      expect(() => LocalizationService().currentDictionary, throwsException);
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
  });
}
