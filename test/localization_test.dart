import 'package:anas_localization/localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocalizationService().clear();
    LocalizationService.clearPreviewDictionaries();
    LocalizationService.supportedLocales = ['en', 'tr', 'ar'];
    // Use preview dictionaries so tests do not depend on package asset content
    LocalizationService.setPreviewDictionaries({
      'en': {'welcome': 'Welcome'},
      'tr': {'welcome': 'Hoş geldiniz'},
    });
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

    test('authored English wording is returned unchanged for irregular plurals and phrasing', () async {
      LocalizationService.setPreviewDictionaries({
        'en': {
          'welcome': 'Welcome',
          'childCount': {
            'one': '1 child',
            'other': '{count} children',
          },
          'informationLabel': 'Information',
          'theSelectionLabel': 'The selection',
          'formalGreeting': 'Good morning.',
          'informalGreeting': 'Hi!',
        },
      });
      await LocalizationService().loadLocale('en');
      final Dictionary dict = LocalizationService().currentDictionary;

      expect(dict.getString('informationLabel'), equals('Information'));
      expect(dict.getString('theSelectionLabel'), equals('The selection'));
      expect(dict.getString('formalGreeting'), equals('Good morning.'));
      expect(dict.getString('informalGreeting'), equals('Hi!'));

      final ctx = UserContext(locale: 'en');
      expect(
        dict.resolve(ctx, 'childCount', params: {'count': 1}),
        equals('1 child'),
      );
      expect(
        dict.resolve(ctx, 'childCount', params: {'count': 3}),
        equals('3 children'),
      );
    });
  });
}
