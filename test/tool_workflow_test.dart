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

    test('export and import ARB perform real file operations', () async {
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

      final arbDir = Directory('${tempDir!.path}/arb_out');
      final exportResult = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'export',
          langDir.path,
          'arb',
          arbDir.path,
        ],
      );
      expect(exportResult.exitCode, equals(0));
      expect(File('${arbDir.path}/app_en.arb').existsSync(), isTrue);
      expect(File('${arbDir.path}/app_tr.arb').existsSync(), isTrue);

      final importDir = Directory('${tempDir!.path}/imported_arb_lang');
      final importResult = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'import',
          arbDir.path,
          importDir.path,
        ],
      );
      expect(importResult.exitCode, equals(0));

      final importedEn = jsonDecode(
        await File('${importDir.path}/en.json').readAsString(),
      ) as Map<String, dynamic>;
      final importedTr = jsonDecode(
        await File('${importDir.path}/tr.json').readAsString(),
      ) as Map<String, dynamic>;
      expect((importedEn['home'] as Map<String, dynamic>)['title'], equals('Home'));
      expect((importedTr['home'] as Map<String, dynamic>)['title'], equals('Ana Sayfa'));
    });

    test('imports ARB files from l10n.yaml config', () async {
      final workspace = Directory('${tempDir!.path}/flutter_l10n_workspace')..createSync(recursive: true);
      final arbDir = Directory('${workspace.path}/lib/l10n')..createSync(recursive: true);
      await File('${arbDir.path}/app_en.arb').writeAsString(
        jsonEncode({
          '@@locale': 'en',
          'home.title': 'Home',
        }),
      );
      await File('${arbDir.path}/app_ar.arb').writeAsString(
        jsonEncode({
          '@@locale': 'ar',
          'home.title': 'الرئيسية',
        }),
      );

      final l10nYaml = File('${workspace.path}/l10n.yaml');
      await l10nYaml.writeAsString('''
arb-dir: lib/l10n
template-arb-file: app_en.arb
preferred-supported-locales:
  - en
  - ar
''');

      final importDir = Directory('${tempDir!.path}/imported_from_l10n');
      final importResult = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'import',
          l10nYaml.path,
          importDir.path,
        ],
      );
      expect(importResult.exitCode, equals(0));
      expect(File('${importDir.path}/en.json').existsSync(), isTrue);
      expect(File('${importDir.path}/ar.json').existsSync(), isTrue);
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

    test('watch mode regenerates output after file changes', () async {
      final tempDir = Directory.systemTemp.createTempSync('i18n_codegen_watch_');
      final outputPath = '${tempDir.path}/dictionary.dart';

      Future<void> writeOverrides({
        required String enValue,
        required String trValue,
        required String arValue,
        bool includeNewKey = false,
      }) async {
        Future<void> writeLocale(String locale, String value) async {
          final map = <String, dynamic>{
            'watch_mode': {'label': value},
          };
          if (includeNewKey) {
            map['watch_mode_new'] = value;
          }
          final file = File('${tempDir.path}/$locale.json');
          await file.create(recursive: true);
          await file.writeAsString(jsonEncode(map));
        }

        await writeLocale('en', enValue);
        await writeLocale('tr', trValue);
        await writeLocale('ar', arValue);
      }

      Future<bool> waitFor(bool Function() predicate, {Duration timeout = const Duration(seconds: 20)}) async {
        final deadline = DateTime.now().add(timeout);
        while (DateTime.now().isBefore(deadline)) {
          if (predicate()) return true;
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
        return predicate();
      }

      Process? process;
      try {
        await writeOverrides(
          enValue: 'Initial',
          trValue: 'İlk',
          arValue: 'أولي',
        );

        process = await Process.start(
          'dart',
          ['run', 'anas_localization:localization_gen', '--watch'],
          environment: {
            ...Platform.environment,
            'APP_LANG_DIR': tempDir.path,
            'OUTPUT_DART': outputPath,
          },
        );
        process.stdout.listen((_) {});
        process.stderr.listen((_) {});

        final initialGenerated = await waitFor(() => File(outputPath).existsSync());
        expect(initialGenerated, isTrue);
        await Future<void>.delayed(const Duration(milliseconds: 600));

        await writeOverrides(
          enValue: 'Changed',
          trValue: 'Değişti',
          arValue: 'تغير',
          includeNewKey: true,
        );

        final regenerated = await waitFor(
          () {
            if (!File(outputPath).existsSync()) return false;
            final content = File(outputPath).readAsStringSync();
            return content.contains('watchModeNew');
          },
          timeout: const Duration(seconds: 20),
        );
        expect(regenerated, isTrue);
      } finally {
        if (process != null) {
          process.kill(ProcessSignal.sigint);
          await process.exitCode.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              process?.kill();
              return -1;
            },
          );
        }
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    }, timeout: const Timeout(Duration(seconds: 90)));
  });
}
