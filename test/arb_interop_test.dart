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

  test('ARB locale extraction keeps en_CA and en_US from filename', () {
    final enCa = ArbInterop.parseArb('{}', fileName: 'app_en_CA.arb');
    expect(enCa.locale, equals('en_CA'));

    final enUs = ArbInterop.parseArb('{}', fileName: 'app_en_US.arb');
    expect(enUs.locale, equals('en_US'));
  });

  test('ARB round-trip preserves regional English locale en_CA with British-spelling override', () {
    final enCa = ArbInterop.parseArb(
      jsonEncode({'@@locale': 'en_CA', 'colorLabel': 'Colour'}),
      fileName: 'app_en_CA.arb',
    );
    expect(enCa.locale, equals('en_CA'));
    expect(enCa.translations['colorLabel'], equals('Colour'));

    final serialized = ArbInterop.toArbString(enCa);
    final roundTrip = ArbInterop.parseArb(serialized, fileName: 'app_en_CA.arb');
    expect(roundTrip.locale, equals('en_CA'));
    expect(roundTrip.translations['colorLabel'], equals('Colour'));
  });

  test('ARB import round-trip covers all four regional English locales', () async {
    final temp = Directory.systemTemp.createTempSync('arb_regional_en_');
    addTearDown(() {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    });

    final arbDir = Directory('${temp.path}/lib/l10n')..createSync(recursive: true);
    for (final entry in {
      'app_en.arb': {'@@locale': 'en', 'colorLabel': 'Color'},
      'app_en_US.arb': {'@@locale': 'en_US', 'colorLabel': 'Color'},
      'app_en_GB.arb': {'@@locale': 'en_GB', 'colorLabel': 'Colour'},
      'app_en_CA.arb': {'@@locale': 'en_CA', 'colorLabel': 'Colour'},
      'app_en_AU.arb': {'@@locale': 'en_AU', 'colorLabel': 'Colour'},
    }.entries) {
      await File('${arbDir.path}/${entry.key}').writeAsString(jsonEncode(entry.value));
    }

    final l10nYaml = File('${temp.path}/l10n.yaml');
    await l10nYaml.writeAsString('''
arb-dir: lib/l10n
template-arb-file: app_en.arb
preferred-supported-locales:
  - en
  - en_US
  - en_GB
  - en_CA
  - en_AU
''');

    final imported = await ArbInterop.importUsingL10nYaml(l10nYaml.path);
    expect(imported.keys.toSet(), equals({'en', 'en_US', 'en_GB', 'en_CA', 'en_AU'}));
    expect(imported['en_US']!['colorLabel'], equals('Color'));
    expect(imported['en_GB']!['colorLabel'], equals('Colour'));
    expect(imported['en_CA']!['colorLabel'], equals('Colour'));
    expect(imported['en_AU']!['colorLabel'], equals('Colour'));
  });

  test('ARB round-trip preserves regional English locale en_GB and en_AU', () {
    final enGb = ArbInterop.parseArb(
      jsonEncode({'@@locale': 'en_GB', 'colorLabel': 'Colour'}),
      fileName: 'app_en_GB.arb',
    );
    expect(enGb.locale, equals('en_GB'));
    expect(enGb.translations['colorLabel'], equals('Colour'));

    final enAu = ArbInterop.parseArb(
      jsonEncode({'@@locale': 'en_AU', 'colorLabel': 'Colour'}),
      fileName: 'app_en_AU.arb',
    );
    expect(enAu.locale, equals('en_AU'));

    final serializedGb = ArbInterop.toArbString(enGb);
    final roundTripGb = ArbInterop.parseArb(serializedGb, fileName: 'app_en_GB.arb');
    expect(roundTripGb.locale, equals('en_GB'));
    expect(roundTripGb.translations['colorLabel'], equals('Colour'));
  });
}
