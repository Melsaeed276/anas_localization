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

    test('resolve with count matches raw plural form selection for English one/other', () {
      const context = UserContext(locale: 'en');
      for (final entry in [
        (0, '0 Cars'),
        (1, 'Car'),
        (2, '2 Cars'),
        (-1, 'Car'),
        (-2, '-2 Cars'),
        (1.5, '1.5 Cars'),
      ]) {
        final resolved = dictionary.resolve(
          context,
          'home.car',
          params: {'count': entry.$1},
        );
        expect(resolved, equals(entry.$2));
      }
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

    test('shared-base overlay lookup resolves base and overridden keys from merged map', () {
      final merged = {
        'welcome': 'Welcome',
        'colorLabel': 'Colour',
        'home': {
          'title': 'Home',
          'car': {
            'one': 'Car',
            'other': '{count} Cars',
          },
        },
      };
      final overlayDictionary = Dictionary.fromMap(merged, locale: 'en_GB');

      expect(overlayDictionary.getString('welcome'), equals('Welcome'));
      expect(overlayDictionary.getString('colorLabel'), equals('Colour'));
      expect(overlayDictionary.getString('home.title'), equals('Home'));
      expect(
        overlayDictionary.resolve(
          const UserContext(locale: 'en_GB'),
          'home.car',
          params: {'count': 2},
        ),
        equals('2 Cars'),
      );
    });

    test('en_CA overlay preserves base en plural resolution with Colour spelling', () {
      final merged = {
        'colorLabel': 'Colour',
        'itemsCount': {
          'one': '{count} item',
          'other': '{count} items',
        },
      };
      final dict = Dictionary.fromMap(merged, locale: 'en_CA');
      const ctx = UserContext(locale: 'en_CA');

      expect(dict.getString('colorLabel'), equals('Colour'));
      expect(dict.resolve(ctx, 'itemsCount', params: {'count': 1}), equals('1 item'));
      expect(dict.resolve(ctx, 'itemsCount', params: {'count': 5}), equals('5 items'));
    });

    test('en_AU overlay resolves Australian greeting override and shared plural', () {
      final merged = {
        'informalGreeting': "G'day!",
        'personCount': {
          'one': '1 person',
          'other': '{count} people',
        },
      };
      final dict = Dictionary.fromMap(merged, locale: 'en_AU');
      const ctx = UserContext(locale: 'en_AU');

      expect(dict.getString('informalGreeting'), equals("G'day!"));
      expect(dict.resolve(ctx, 'personCount', params: {'count': 1}), equals('1 person'));
      expect(dict.resolve(ctx, 'personCount', params: {'count': 3}), equals('3 people'));
    });

    test('en_US and en_GB overlays resolve the same plural keys with different spelling overrides', () {
      final usDict = Dictionary.fromMap({'colorLabel': 'Color', 'cancel': 'Cancel'}, locale: 'en_US');
      final gbDict = Dictionary.fromMap({'colorLabel': 'Colour', 'cancel': 'Cancel'}, locale: 'en_GB');

      expect(usDict.getString('colorLabel'), equals('Color'));
      expect(gbDict.getString('colorLabel'), equals('Colour'));
      expect(usDict.getString('cancel'), equals('Cancel'));
      expect(gbDict.getString('cancel'), equals('Cancel'));
    });
  });
}
