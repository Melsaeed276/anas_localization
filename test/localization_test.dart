import 'package:anas_localization/localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocalizationService().clear();
    LocalizationService.clearPreviewDictionaries();
    LocalizationService.supportedLocales = ['en', 'tr', 'ar'];
  });

  group('LocalizationService', () {
    test('loads English dictionary and returns correct values', () async {
      await LocalizationService().loadLocale('en');
      final Dictionary dict = LocalizationService().currentDictionary;
      expect(dict.getString('welcome'), equals('Welcome'));
    });

    test('throws UnsupportedLocaleException for unsupported locale', () async {
      expect(
        () => LocalizationService().loadLocale('fr'),
        throwsA(isA<UnsupportedLocaleException>()),
      );
    });

    test('loads Turkish dictionary and returns correct values', () async {
      await LocalizationService().loadLocale('tr');
      final Dictionary dict = LocalizationService().currentDictionary;
      expect(dict.getString('welcome'), equals('Hoş geldiniz'));
    });
  });
}
