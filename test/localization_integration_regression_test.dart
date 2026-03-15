import 'dart:convert';
import 'dart:io';

import 'package:anas_localization/anas_localization.dart';
import 'package:anas_localization/src/utils/translation_validator.dart' as core_validator;
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocalizationService().clear();
    LocalizationService.clearPreviewDictionaries();
    LocalizationService.resetTranslationLoaders();
    LocalizationService.setFallbackLocaleCode('en');
  });

  test('nested lookup remains correct through script-aware fallback', () async {
    LocalizationService.configure(
      locales: ['en', 'zh_Hant'],
      fallbackLocaleCode: 'en',
      previewDictionaries: const {
        'en': {
          'checkout': {
            'summary': {'title': 'Summary'},
          },
        },
        'zh_Hant': {
          'checkout': {
            'summary': {'title': '摘要'},
          },
        },
      },
    );

    await LocalizationService().loadLocale('zh_Hant_TW');

    expect(LocalizationService().currentLocale, equals('zh_Hant'));
    expect(
      LocalizationService().currentDictionary.getString('checkout.summary.title'),
      equals('摘要'),
    );
    expect(
      LocalizationService().getLastLocaleResolutionPath(),
      equals(['zh_Hant_TW', 'zh_Hant', 'zh_TW', 'zh', 'en']),
    );
  });

  test('English plural uses one only when count.abs() == 1', () async {
    LocalizationService.configure(
      locales: ['en'],
      fallbackLocaleCode: 'en',
      previewDictionaries: const {
        'en': {
          'itemsCount': {
            'one': '{count} item',
            'other': '{count} items',
          },
        },
      },
    );
    LocalizationService.setTranslationLoaders([]);

    await LocalizationService().loadLocale('en');
    final dict = LocalizationService().currentDictionary;
    const context = UserContext(locale: 'en');

    expect(dict.resolve(context, 'itemsCount', params: {'count': 0}), equals('0 items'));
    expect(dict.resolve(context, 'itemsCount', params: {'count': 1}), equals('1 item'));
    expect(dict.resolve(context, 'itemsCount', params: {'count': 2}), equals('2 items'));
    expect(dict.resolve(context, 'itemsCount', params: {'count': 5}), equals('5 items'));
    expect(dict.resolve(context, 'itemsCount', params: {'count': -1}), equals('-1 item'));
    expect(dict.resolve(context, 'itemsCount', params: {'count': -2}), equals('-2 items'));
    expect(dict.resolve(context, 'itemsCount', params: {'count': 1.5}), equals('1.5 items'));
  });

  test('plural and gender maps are available after cross-locale switch', () async {
    LocalizationService.configure(
      locales: ['en', 'ar'],
      fallbackLocaleCode: 'en',
      previewDictionaries: const {
        'en': {
          'cart': {
            'items': {
              'one': '{count} item',
              'other': '{count} items',
            },
          },
        },
        'ar': {
          'cart': {
            'items': {
              'one': {
                'male': '{count} عنصر له',
                'female': '{count} عنصر لها',
              },
              'few': '{count} عناصر',
              'other': '{count} عنصر',
            },
          },
        },
      },
    );

    await LocalizationService().loadLocale('ar');
    final arPlural = LocalizationService().currentDictionary.getPluralData('cart.items');
    expect(arPlural, isNotNull);
    expect(arPlural!['one'], isA<Map>());
    expect((arPlural['one'] as Map)['male'], equals('{count} عنصر له'));

    await LocalizationService().loadLocale('en');
    final enPlural = LocalizationService().currentDictionary.getPluralData('cart.items');
    expect(enPlural, isNotNull);
    expect(enPlural!['one'], equals('{count} item'));
    expect(enPlural['other'], equals('{count} items'));
  });

  test('English regional number formatters produce locale-appropriate decimal output', () {
    final usNumber = AnasNumberFormatter(Locale('en', 'US')).formatDecimal(1234.56);
    final gbNumber = AnasNumberFormatter(Locale('en', 'GB')).formatDecimal(1234.56);

    expect(usNumber, isNotEmpty);
    expect(gbNumber, isNotEmpty);
    expect(usNumber, contains('1'));
    expect(gbNumber, contains('1'));
  });

  test('validator catches nested gender-form regressions', () async {
    final tempDir = Directory.systemTemp.createTempSync('i18n_gender_regression_');
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Future<void> writeLocale(String locale, Map<String, dynamic> data) async {
      final file = File('${tempDir.path}/$locale.json');
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(data));
    }

    await writeLocale('en', {
      'cart': {
        'items': {
          'one': {
            'male': '{count} item for him',
            'female': '{count} item for her',
          },
          'other': '{count} items',
        },
      },
    });
    await writeLocale('tr', {
      'cart': {
        'items': {
          'one': {
            'male': '{count} ürün',
          },
          'other': '{count} ürün',
        },
      },
    });

    final result = await core_validator.TranslationValidator.validateTranslations(
      tempDir.path,
      profile: core_validator.ValidationProfile.strict,
      ruleToggles: const core_validator.ValidationRuleToggles(
        checkMissingKeys: false,
      ),
    );

    expect(result.isValid, isFalse);
    expect(
      result.errors.any((item) => item.contains('Gender forms mismatch')),
      isTrue,
    );
  });
}
