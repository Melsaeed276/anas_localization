import 'dart:convert';
import 'dart:io';

import 'package:anas_localization/src/utils/codegen_utils.dart';
import 'package:anas_localization/src/utils/translation_validator.dart' as core_validator;
import 'package:flutter_test/flutter_test.dart';

import '../bin/validate_translations.dart' as bin_validator;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Codegen placeholder parsing', () {
    test('hasPlaceholders detects standard and marker placeholders', () {
      expect(hasPlaceholders('Hello, {name}'), isTrue);
      expect(hasPlaceholders('Hello, {name?}'), isTrue);
      expect(hasPlaceholders('Hello, {name!}'), isTrue);
      expect(hasPlaceholders('Hello, world'), isFalse);
    });

    test('extractPlaceholders strips markers and deduplicates', () {
      final placeholders = extractPlaceholders(
        'Hi {name!}, balance {amount}, optional {name?}, count {count}',
      ).toList();

      expect(placeholders, equals(['name', 'amount', 'count']));
    });
  });

  group('TranslationValidator', () {
    Directory? tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('i18n_test_');
    });

    tearDown(() {
      tempDir?.deleteSync(recursive: true);
    });

    Future<File> writeJsonFile(
      String dir,
      String filename,
      Map<String, dynamic> data,
    ) async {
      final file = File('$dir/$filename');
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(data));
      return file;
    }

    test('returns false when master file is missing', () async {
      final validator = bin_validator.TranslationValidator(
        masterFilePath: '${tempDir!.path}/en.json',
        langDirectoryPath: tempDir!.path,
      );

      final result = await validator.validate();

      expect(result, isFalse);
    });

    test('succeeds when all files match master', () async {
      final master = {'hello': 'Hello', 'bye': 'Bye'};
      await writeJsonFile(tempDir!.path, 'en.json', master);
      await writeJsonFile(tempDir!.path, 'tr.json', master);
      await writeJsonFile(tempDir!.path, 'ar.json', master);

      final validator = bin_validator.TranslationValidator(
        masterFilePath: '${tempDir!.path}/en.json',
        langDirectoryPath: tempDir!.path,
      );
      final result = await validator.validate();
      expect(result, isTrue);
    });

    test('fails when a file has missing keys', () async {
      final master = {'hello': 'Hello', 'bye': 'Bye'};
      final tr = {'hello': 'Merhaba'};
      await writeJsonFile(tempDir!.path, 'en.json', master);
      await writeJsonFile(tempDir!.path, 'tr.json', tr);

      final validator = bin_validator.TranslationValidator(
        masterFilePath: '${tempDir!.path}/en.json',
        langDirectoryPath: tempDir!.path,
      );
      final result = await validator.validate();
      expect(result, isFalse);
    });

    test('fails when a file has extra keys', () async {
      final master = {'hello': 'Hello'};
      final tr = {'hello': 'Merhaba', 'extra': 'Fazla'};
      await writeJsonFile(tempDir!.path, 'en.json', master);
      await writeJsonFile(tempDir!.path, 'tr.json', tr);

      final validator = bin_validator.TranslationValidator(
        masterFilePath: '${tempDir!.path}/en.json',
        langDirectoryPath: tempDir!.path,
      );

      final result = await validator.validate();

      expect(result, isFalse);
    });

    test('library validator handles nested placeholder paths', () async {
      await writeJsonFile(tempDir!.path, 'en.json', {
        'home': {
          'title': 'Hello {name}',
        },
      });
      await writeJsonFile(tempDir!.path, 'tr.json', {
        'home': {
          'title': 'Merhaba {name}',
        },
      });

      final result = await core_validator.TranslationValidator.validateTranslations(tempDir!.path);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('library validator detects placeholder mismatch by content', () async {
      await writeJsonFile(tempDir!.path, 'en.json', {
        'welcome_user': 'Welcome {name}',
      });
      await writeJsonFile(tempDir!.path, 'tr.json', {
        'welcome_user': 'Merhaba {username}',
      });

      final result = await core_validator.TranslationValidator.validateTranslations(tempDir!.path);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('Placeholder mismatch')), isTrue);
    });

    test('library validator can treat extra keys as errors in strict mode', () async {
      await writeJsonFile(tempDir!.path, 'en.json', {'hello': 'Hello'});
      await writeJsonFile(tempDir!.path, 'tr.json', {
        'hello': 'Merhaba',
        'extra': 'Fazla',
      });

      final strictResult = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        treatExtraKeysAsWarnings: false,
      );

      expect(strictResult.isValid, isFalse);
      expect(strictResult.errors.any((e) => e.contains('has extra keys')), isTrue);
    });
  });

  group('CLI workflow', () {
    Directory? tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('i18n_cli_');
    });

    tearDown(() {
      tempDir?.deleteSync(recursive: true);
    });

    test('cli alias command works', () async {
      final result = await Process.run(
        'dart',
        ['run', 'anas_localization:cli', 'help'],
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Anas Localization CLI Tool'));
    });

    test('add-locale and translate update locale files', () async {
      final langDir = Directory('${tempDir!.path}/lang')..createSync(recursive: true);
      final enFile = File('${langDir.path}/en.json');
      await enFile.writeAsString(
        jsonEncode({
          'home': {'title': 'Home'},
        }),
      );

      final addLocaleResult = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'add-locale',
          'fr',
          'en',
          langDir.path,
        ],
      );
      expect(addLocaleResult.exitCode, equals(0));

      final frFile = File('${langDir.path}/fr.json');
      expect(frFile.existsSync(), isTrue);

      final translateResult = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'translate',
          'home.title',
          'fr',
          'Accueil',
          langDir.path,
        ],
      );
      expect(translateResult.exitCode, equals(0));

      final frMap = jsonDecode(await frFile.readAsString()) as Map<String, dynamic>;
      expect((frMap['home'] as Map<String, dynamic>)['title'], equals('Accueil'));
    });

    test('remove-key deletes nested key across locale files', () async {
      final langDir = Directory('${tempDir!.path}/lang')..createSync(recursive: true);
      await File('${langDir.path}/en.json').writeAsString(
        jsonEncode({
          'home': {'title': 'Home', 'subtitle': 'Welcome'},
        }),
      );
      await File('${langDir.path}/tr.json').writeAsString(
        jsonEncode({
          'home': {'title': 'Ana Sayfa', 'subtitle': 'Hoş geldiniz'},
        }),
      );

      final removeResult = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'remove-key',
          'home.subtitle',
          langDir.path,
        ],
      );

      expect(removeResult.exitCode, equals(0));

      final enMap = jsonDecode(await File('${langDir.path}/en.json').readAsString()) as Map<String, dynamic>;
      final trMap = jsonDecode(await File('${langDir.path}/tr.json').readAsString()) as Map<String, dynamic>;

      expect((enMap['home'] as Map<String, dynamic>).containsKey('subtitle'), isFalse);
      expect((trMap['home'] as Map<String, dynamic>).containsKey('subtitle'), isFalse);
    });

    test('export and import json perform real file operations', () async {
      final langDir = Directory('${tempDir!.path}/lang')..createSync(recursive: true);
      await File('${langDir.path}/en.json').writeAsString(
        jsonEncode({
          'home': {'title': 'Home'},
        }),
      );
      await File('${langDir.path}/tr.json').writeAsString(
        jsonEncode({
          'home': {'title': 'Ana Sayfa'},
        }),
      );

      final exportFile = '${tempDir!.path}/translations_export.json';
      final exportResult = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'export',
          langDir.path,
          'json',
          exportFile,
        ],
      );
      expect(exportResult.exitCode, equals(0));
      expect(File(exportFile).existsSync(), isTrue);

      final importDir = Directory('${tempDir!.path}/imported_lang');
      final importResult = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'import',
          exportFile,
          importDir.path,
        ],
      );
      expect(importResult.exitCode, equals(0));
      expect(File('${importDir.path}/en.json').existsSync(), isTrue);
      expect(File('${importDir.path}/tr.json').existsSync(), isTrue);
    });

    test('export and import csv perform real file operations', () async {
      final langDir = Directory('${tempDir!.path}/lang')..createSync(recursive: true);
      await File('${langDir.path}/en.json').writeAsString(
        jsonEncode({
          'home': {'title': 'Home'},
          'count': '{count} items',
        }),
      );
      await File('${langDir.path}/fr.json').writeAsString(
        jsonEncode({
          'home': {'title': 'Accueil'},
          'count': '{count} éléments',
        }),
      );

      final exportFile = '${tempDir!.path}/translations_export.csv';
      final exportResult = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'export',
          langDir.path,
          'csv',
          exportFile,
        ],
      );
      expect(exportResult.exitCode, equals(0));
      expect(File(exportFile).existsSync(), isTrue);

      final importDir = Directory('${tempDir!.path}/imported_csv_lang');
      final importResult = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'import',
          exportFile,
          importDir.path,
        ],
      );
      expect(importResult.exitCode, equals(0));

      final importedFr = jsonDecode(
        await File('${importDir.path}/fr.json').readAsString(),
      ) as Map<String, dynamic>;
      expect((importedFr['home'] as Map<String, dynamic>)['title'], equals('Accueil'));
      expect(importedFr['count'], equals('{count} éléments'));
    });

    test('cli returns non-zero for invalid command usage', () async {
      final unknownCommand = await Process.run(
        'dart',
        ['run', 'anas_localization:anas_cli', 'does-not-exist'],
      );
      expect(unknownCommand.exitCode, isNonZero);

      final missingArgs = await Process.run(
        'dart',
        ['run', 'anas_localization:anas_cli', 'translate', 'home.title'],
      );
      expect(missingArgs.exitCode, isNonZero);
    });
  });

  group('Dictionary code generation', () {
    test('generates Dictionary class file with getters from source keys', () async {
      final tempDir = Directory.systemTemp.createTempSync('i18n_codegen_');

      try {
        final codegenScript = File('bin/generate_dictionary.dart');
        final outputPath = '${tempDir.path}/dictionary.dart';
        final result = await Process.run(
          'dart',
          [codegenScript.path],
          environment: {'OUTPUT_DART': outputPath},
        );

        expect(result.exitCode, equals(0));

        final outputFile = File(outputPath);
        expect(outputFile.existsSync(), isTrue);

        final contents = await outputFile.readAsString();
        expect(contents, contains('class Dictionary'));
        expect(contents, contains('Dictionary.fromMap('));
        expect(contents, contains("import 'package:anas_localization/anas_localization.dart' as base;"));
        expect(
          contents,
          contains("import 'package:anas_localization/anas_localization.dart' as base;"),
        );

        final enMap = jsonDecode(await File('assets/lang/en.json').readAsString()) as Map<String, dynamic>;
        final sampleStringKey = enMap.entries.firstWhere((e) => e.value is String).key;
        final expectedGetterName = sanitizeDartIdentifier(sampleStringKey);

        expect(contents, contains('String get $expectedGetterName =>'));
        expect(
          contents,
          contains('String get ${sanitizeDartIdentifier('supported_languages.en')} =>'),
        );
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('generates APIs for nested string and nested plural keys', () async {
      final tempDir = Directory.systemTemp.createTempSync('i18n_codegen_nested_');

      Future<void> writeOverride(String locale, Map<String, dynamic> data) async {
        final file = File('${tempDir.path}/$locale.json');
        await file.create(recursive: true);
        await file.writeAsString(jsonEncode(data));
      }

      try {
        await writeOverride('en', {
          'checkout': {
            'title': 'Checkout',
            'items': {
              'one': '{count} item',
              'other': '{count} items',
            },
          },
        });
        await writeOverride('tr', {
          'checkout': {
            'title': 'Ödeme',
            'items': {
              'one': '{count} ürün',
              'other': '{count} ürün',
            },
          },
        });
        await writeOverride('ar', {
          'checkout': {
            'title': 'الدفع',
            'items': {
              'one': '{count} عنصر',
              'other': '{count} عناصر',
            },
          },
        });

        final outputPath = '${tempDir.path}/dictionary.dart';
        final result = await Process.run(
          'dart',
          ['run', 'anas_localization:localization_gen'],
          environment: {
            'APP_LANG_DIR': tempDir.path,
            'OUTPUT_DART': outputPath,
          },
        );

        expect(result.exitCode, equals(0));
        final generated = await File(outputPath).readAsString();
        expect(generated, contains('String get checkoutTitle => getString(\'checkout.title\');'));
        expect(generated, contains('String checkoutItems({required int count}) {'));
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
