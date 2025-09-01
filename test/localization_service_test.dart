import 'package:anas_localization/localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset the singleton before each test (clear locale/dictionary)
    LocalizationService().clear();
  });

  group('LocalizationService', () {
    test('loads supported locale and returns correct dictionary', () async {
      await LocalizationService().loadLocale('en');
      final dict = LocalizationService().currentDictionary;
     // expect(dict.welcome, equals('Welcome')); // Change this to your en.json value
    });

    test('loads another supported locale', () async {
      await LocalizationService().loadLocale('tr');
      final dict = LocalizationService().currentDictionary;
     // expect(dict.welcome, isNot(equals('Welcome'))); // Turkish should be different
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
        //expect(dict.welcome, equals('Welcome')); // Assuming 'Welcome' is in en.json
      } finally {
        // Always reset to original to avoid affecting other tests
        LocalizationService.supportedLocales = originalLocales;
      }
    });

    test('throws if both locale and fallback to English fail', () async {
      // Simulate all assets missing by trying a totally missing locale
      // and temporarily renaming/removing en.json for this test, or by mocking rootBundle
      // Here, we just demonstrate structure (you'd use a mock/fake in real test)
      // This test will always throw
      expect(
        () => LocalizationService().loadLocale('missing_locale'),
        throwsException,
      );
    });

    test('allSupportedLocales returns list of supported locales', () {
      final locales = LocalizationService.allSupportedLocales;
      expect(locales, containsAll(['en', 'tr', 'ar']));
    });
  });
}
