import 'package:flutter_test/flutter_test.dart';

import 'package:anas_localization/src/core/localization_service.dart';
import 'package:anas_localization/src/generated/dictionary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalizationService', () {
    test('loads English dictionary and returns correct values', () async {
      // Load the English locale
      await LocalizationService().loadLocale('en');
      final Dictionary dict = LocalizationService().currentDictionary;

      expect(dict.welcome, equals('Welcome!'));
    });

    test('throws error for unsupported locale', () async {
      expect(() => LocalizationService().loadLocale('fr'), throwsException);
    });
  });

  test('loads Turkish dictionary and returns correct values', () async {
    await LocalizationService().loadLocale('tr');
    final Dictionary dict = LocalizationService().currentDictionary;
    expect(dict.welcome, equals('Hoş geldiniz!'));
  });
}
