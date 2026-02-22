import 'package:anas_localization/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocalizationService().clear();
    LocalizationService.supportedLocales = ['en', 'tr', 'ar'];
    LocalizationService.clearPreviewDictionaries();
  });

  test('loads dictionary from preview dictionaries without bundle assets', () async {
    LocalizationService.configure(
      locales: ['en', 'es'],
      previewDictionaries: {
        'en': {'hello': 'Hello Preview'},
        'es': {'hello': 'Hola Preview'},
      },
    );

    await LocalizationService().loadLocale('es');

    expect(LocalizationService().currentLocale, 'es');
    expect(LocalizationService().currentDictionary.getString('hello'), 'Hola Preview');
  });

  testWidgets('AnasLocalization configures service from widget locales', (tester) async {
    await tester.pumpWidget(
      AnasLocalization(
        fallbackLocale: const Locale('en'),
        assetLocales: const [Locale('en'), Locale('es')],
        previewDictionaries: const {
          'en': {'title': 'EN title'},
          'es': {'title': 'ES title'},
        },
        app: Builder(
          builder: (context) {
            return Text(context.dict.getString('title'), textDirection: TextDirection.ltr);
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(LocalizationService.supportedLocales, ['en', 'es']);
    expect(find.text('EN title'), findsOneWidget);
  });
}
