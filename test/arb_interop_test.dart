import 'dart:convert';
import 'dart:io';

import 'package:anas_localization/anas_localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ARB parse and serialize preserves metadata for round trip', () {
    const arbContent = '''
{
  "@@locale": "en",
  "hello": "Hello {name}",
  "@hello": {
    "description": "Greeting",
    "placeholders": {
      "name": {}
    }
  }
}
''';

    final parsed = ArbInterop.parseArb(arbContent, fileName: 'app_en.arb');
    expect(parsed.locale, 'en');
    expect(parsed.translations['hello'], 'Hello {name}');
    expect(parsed.metadata['@hello'], isNotNull);

    final serialized = ArbInterop.toArbString(parsed);
    final roundTrip = ArbInterop.parseArb(serialized, fileName: 'app_en.arb');
    expect(roundTrip.metadata['@hello'], equals(parsed.metadata['@hello']));
    expect(roundTrip.translations['hello'], equals(parsed.translations['hello']));
  });

  test('ARB locale extraction keeps full locale tail from filename', () {
    final enUs = ArbInterop.parseArb(
      '{}',
      fileName: 'app_en_US.arb',
    );
    expect(enUs.locale, equals('en_US'));

    final zhHantTw = ArbInterop.parseArb(
      '{}',
      fileName: 'app_zh_Hant_TW.arb',
    );
    expect(zhHantTw.locale, equals('zh_Hant_TW'));

    final directLocale = ArbInterop.parseArb(
      '{}',
      fileName: 'en_US.arb',
    );
    expect(directLocale.locale, equals('en_US'));
  });

  test('imports ARB files using l10n.yaml compatibility fields', () async {
    final temp = Directory.systemTemp.createTempSync('arb_interop_');
    addTearDown(() {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    });

    final arbDir = Directory('${temp.path}/lib/l10n')..createSync(recursive: true);
    await File('${arbDir.path}/app_en.arb').writeAsString(
      jsonEncode({
        '@@locale': 'en',
        'home.title': 'Home',
      }),
    );
    await File('${arbDir.path}/app_tr.arb').writeAsString(
      jsonEncode({
        '@@locale': 'tr',
        'home.title': 'Ana Sayfa',
      }),
    );

    final l10nYaml = File('${temp.path}/l10n.yaml');
    await l10nYaml.writeAsString('''
arb-dir: lib/l10n
template-arb-file: app_en.arb
preferred-supported-locales:
  - en
  - tr
''');

    final imported = await ArbInterop.importUsingL10nYaml(l10nYaml.path);
    expect(imported.keys.toSet(), equals({'en', 'tr'}));
    expect(imported['en']!['home.title'], equals('Home'));
    expect(imported['tr']!['home.title'], equals('Ana Sayfa'));
  });
}
