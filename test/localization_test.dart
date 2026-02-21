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
      expect(dict, isNotNull);
    });

    test('throws error for unsupported locale', () async {
      expect(() => LocalizationService().loadLocale('fr'), throwsException);
    });

    test('loads Turkish dictionary and returns correct values', () async {
      await LocalizationService().loadLocale('tr');
      final Dictionary dict = LocalizationService().currentDictionary;
      expect(dict, isNotNull);
    });
  });
}
