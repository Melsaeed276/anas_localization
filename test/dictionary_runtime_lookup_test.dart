import 'package:anas_localization/anas_localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dictionary dotted runtime lookup', () {
    late Dictionary dictionary;

    setUp(() {
      dictionary = Dictionary.fromMap(
        {
          'welcome': 'Welcome',
          'home': {
            'title': 'Home',
            'car': {
              'one': 'Car',
              'other': '{count} Cars',
            },
          },
        },
        locale: 'en',
      );
    });

    test('getString resolves dotted nested key paths', () {
      expect(dictionary.getString('home.title'), equals('Home'));
    });

    test('getString keeps flat key behavior unchanged', () {
      expect(dictionary.getString('welcome'), equals('Welcome'));
    });

    test('getPluralData resolves dotted nested plural maps', () {
      final plural = dictionary.getPluralData('home.car');

      expect(plural, isNotNull);
      expect(plural!['one'], equals('Car'));
      expect(plural['other'], equals('{count} Cars'));
    });

    test('hasKey resolves dotted nested key paths', () {
      expect(dictionary.hasKey('home.title'), isTrue);
      expect(dictionary.hasKey('home.missing'), isFalse);
    });
  });
}
