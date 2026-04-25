import 'package:anas_localization/anas_localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    // Keep tests order-independent by resetting any singleton state.
    LocalizationService().clear();
  });

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

  group('Dictionary runtime lookup without generation - getStringWithParams', () {
    late Dictionary dictionary;

    setUp(() {
      dictionary = Dictionary.fromMap(
        {
          'greeting': 'Hello, {name}!',
          'greetingOptional': 'Hello, {name?}!',
          'greetingRequired': 'Hello, {name!}!',
          'multiParams': '{name} has {amount} {currency}',
          'mixedMarkers': '{name!} purchased {count?} items for {total}',
          'user': {
            'welcome': 'Welcome back, {username}!',
            'balance': 'Your balance is {amount} {currency}',
          },
          'noParams': 'This has no parameters',
        },
        locale: 'en',
      );
    });

    test('getStringWithParams replaces single parameter', () {
      final result = dictionary.getStringWithParams(
        'greeting',
        {'name': 'Ahmed'},
      );
      expect(result, equals('Hello, Ahmed!'));
    });

    test('getStringWithParams replaces parameter with optional marker', () {
      final result = dictionary.getStringWithParams(
        'greetingOptional',
        {'name': 'Sarah'},
      );
      expect(result, equals('Hello, Sarah!'));
    });

    test('getStringWithParams replaces parameter with required marker', () {
      final result = dictionary.getStringWithParams(
        'greetingRequired',
        {'name': 'John'},
      );
      expect(result, equals('Hello, John!'));
    });

    test('getStringWithParams replaces multiple parameters', () {
      final result = dictionary.getStringWithParams(
        'multiParams',
        {
          'name': 'Alice',
          'amount': '500',
          'currency': 'USD',
        },
      );
      expect(result, equals('Alice has 500 USD'));
    });

    test('getStringWithParams handles mixed markers', () {
      final result = dictionary.getStringWithParams(
        'mixedMarkers',
        {
          'name': 'Bob',
          'count': '3',
          'total': '\$99.99',
        },
      );
      expect(result, equals('Bob purchased 3 items for \$99.99'));
    });

    test('getStringWithParams works with dotted keys', () {
      final result = dictionary.getStringWithParams(
        'user.welcome',
        {'username': 'admin'},
      );
      expect(result, equals('Welcome back, admin!'));
    });

    test('getStringWithParams works with nested dotted keys', () {
      final result = dictionary.getStringWithParams(
        'user.balance',
        {
          'amount': '1,250.00',
          'currency': 'EUR',
        },
      );
      expect(result, equals('Your balance is 1,250.00 EUR'));
    });

    test('getStringWithParams handles missing parameter gracefully', () {
      final result = dictionary.getStringWithParams(
        'greeting',
        {},
      );
      expect(result, equals('Hello, {name}!'));
    });

    test('getStringWithParams with no parameters returns template unchanged', () {
      final result = dictionary.getStringWithParams(
        'noParams',
        {},
      );
      expect(result, equals('This has no parameters'));
    });

    test('getStringWithParams converts non-string values to string', () {
      final result = dictionary.getStringWithParams(
        'multiParams',
        {
          'name': 'Test',
          'amount': 100, // int
          'currency': true, // bool
        },
      );
      expect(result, equals('Test has 100 true'));
    });

    test('getStringWithParams uses fallback when key not found', () {
      final result = dictionary.getStringWithParams(
        'missing.key',
        {'name': 'Test'},
        fallback: 'Fallback: {name}',
      );
      expect(result, equals('Fallback: Test'));
    });

    test('getStringWithParams returns key when no fallback and key missing', () {
      final result = dictionary.getStringWithParams(
        'missing.key',
        {'name': 'Test'},
      );
      expect(result, equals('missing.key'));
    });
  });

  group('Dictionary runtime lookup - getString edge cases', () {
    late Dictionary dictionary;

    setUp(() {
      dictionary = Dictionary.fromMap(
        {
          'simple': 'Simple value',
          'nested': {
            'deep': {
              'key': 'Deep value',
            },
          },
          'empty': '',
          'number': 42,
          'boolean': true,
          'list': ['a', 'b', 'c'],
        },
        locale: 'en',
      );
    });

    test('getString returns custom fallback for missing key', () {
      final result = dictionary.getString(
        'nonexistent',
        fallback: 'Custom fallback',
      );
      expect(result, equals('Custom fallback'));
    });

    test('getString returns key itself when no fallback and key missing', () {
      final result = dictionary.getString('nonexistent');
      expect(result, equals('nonexistent'));
    });

    test('getString handles empty string value', () {
      final result = dictionary.getString('empty');
      expect(result, equals(''));
    });

    test('getString returns fallback for non-string values (number)', () {
      final result = dictionary.getString('number', fallback: 'Not a string');
      expect(result, equals('Not a string'));
    });

    test('getString returns key for non-string values without fallback', () {
      final result = dictionary.getString('boolean');
      expect(result, equals('boolean'));
    });

    test('getString returns fallback for list values', () {
      final result = dictionary.getString('list', fallback: 'List found');
      expect(result, equals('List found'));
    });

    test('getString handles deeply nested keys', () {
      final result = dictionary.getString('nested.deep.key');
      expect(result, equals('Deep value'));
    });

    test('getString returns fallback for partial path match', () {
      final result = dictionary.getString(
        'nested.deep.nonexistent',
        fallback: 'Partial path',
      );
      expect(result, equals('Partial path'));
    });
  });

  group('Dictionary runtime lookup - hasKey', () {
    late Dictionary dictionary;

    setUp(() {
      dictionary = Dictionary.fromMap(
        {
          'simple': 'value',
          'nested': {
            'key': 'nested value',
            'deep': {
              'key': 'deep value',
            },
          },
          'empty': '',
        },
        locale: 'en',
      );
    });

    test('hasKey returns true for existing flat key', () {
      expect(dictionary.hasKey('simple'), isTrue);
    });

    test('hasKey returns true for existing nested key', () {
      expect(dictionary.hasKey('nested.key'), isTrue);
    });

    test('hasKey returns true for deeply nested key', () {
      expect(dictionary.hasKey('nested.deep.key'), isTrue);
    });

    test('hasKey returns true for empty string value', () {
      expect(dictionary.hasKey('empty'), isTrue);
    });

    test('hasKey returns false for nonexistent key', () {
      expect(dictionary.hasKey('nonexistent'), isFalse);
    });

    test('hasKey returns false for partial path match', () {
      expect(dictionary.hasKey('nested.nonexistent'), isFalse);
    });

    test('hasKey returns false for invalid nested path', () {
      expect(dictionary.hasKey('simple.invalid'), isFalse);
    });
  });

  group('Dictionary runtime lookup - locale and toMap', () {
    test('locale getter returns the correct locale', () {
      final dict = Dictionary.fromMap({'key': 'value'}, locale: 'en_US');
      expect(dict.locale, equals('en_US'));
    });

    test('toMap returns a copy of translations', () {
      final originalMap = {
        'simple': 'value',
        'nested': {'key': 'nested'},
      };
      final dict = Dictionary.fromMap(originalMap, locale: 'en');
      final mapCopy = dict.toMap();

      expect(mapCopy, equals(originalMap));
      expect(identical(mapCopy, originalMap), isFalse);
    });

    test('toMap preserves nested structure', () {
      final dict = Dictionary.fromMap(
        {
          'level1': {
            'level2': {
              'level3': 'deep value',
            },
          },
        },
        locale: 'en',
      );

      final map = dict.toMap();
      expect(map['level1']['level2']['level3'], equals('deep value'));
    });
  });

  group('Dictionary runtime lookup - complete workflow without generation', () {
    test('complete app flow using only runtime lookup APIs', () {
      // Simulate loading translations without generating Dictionary class
      final translations = {
        'app_name': 'My App',
        'welcome_message': 'Welcome, {username}!',
        'item_count': '{count} items in cart',
        'settings': {
          'title': 'Settings',
          'profile': {
            'title': 'Profile Settings',
            'description': 'Manage your profile for {appName}',
          },
        },
      };

      final dict = Dictionary.fromMap(translations, locale: 'en');

      // Check keys exist
      expect(dict.hasKey('app_name'), isTrue);
      expect(dict.hasKey('settings.profile.title'), isTrue);

      // Get simple strings
      expect(dict.getString('app_name'), equals('My App'));
      expect(dict.getString('settings.title'), equals('Settings'));

      // Get nested strings
      expect(
        dict.getString('settings.profile.title'),
        equals('Profile Settings'),
      );

      // Get strings with parameters
      expect(
        dict.getStringWithParams('welcome_message', {'username': 'John'}),
        equals('Welcome, John!'),
      );

      expect(
        dict.getStringWithParams('item_count', {'count': '5'}),
        equals('5 items in cart'),
      );

      // Nested with parameters
      expect(
        dict.getStringWithParams(
          'settings.profile.description',
          {'appName': 'My App'},
        ),
        equals('Manage your profile for My App'),
      );

      // Missing keys with fallback
      expect(
        dict.getString('missing', fallback: 'Not found'),
        equals('Not found'),
      );
    });

    test('multi-locale workflow without generation', () {
      final enDict = Dictionary.fromMap(
        {
          'greeting': 'Hello, {name}!',
          'farewell': 'Goodbye!',
        },
        locale: 'en',
      );

      final arDict = Dictionary.fromMap(
        {
          'greeting': 'مرحباً، {name}!',
          'farewell': 'وداعاً!',
        },
        locale: 'ar',
      );

      final trDict = Dictionary.fromMap(
        {
          'greeting': 'Merhaba, {name}!',
          'farewell': 'Güle güle!',
        },
        locale: 'tr',
      );

      // Verify locales
      expect(enDict.locale, equals('en'));
      expect(arDict.locale, equals('ar'));
      expect(trDict.locale, equals('tr'));

      // Same key, different locales
      expect(
        enDict.getStringWithParams('greeting', {'name': 'Ahmed'}),
        equals('Hello, Ahmed!'),
      );
      expect(
        arDict.getStringWithParams('greeting', {'name': 'أحمد'}),
        equals('مرحباً، أحمد!'),
      );
      expect(
        trDict.getStringWithParams('greeting', {'name': 'Ahmet'}),
        equals('Merhaba, Ahmet!'),
      );
    });
  });
}
