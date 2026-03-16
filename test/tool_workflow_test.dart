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

    test('library validator detects requiredness marker mismatch', () async {
      await writeJsonFile(tempDir!.path, 'en.json', {
        'welcome_user': 'Welcome {name!}',
      });
      await writeJsonFile(tempDir!.path, 'tr.json', {
        'welcome_user': 'Merhaba {name?}',
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.strict,
      );

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('required=')), isTrue);
    });

    test('library validator detects ARB placeholder type mismatches', () async {
      await writeJsonFile(tempDir!.path, 'app_en.arb', {
        '@@locale': 'en',
        'cart_summary': '{count} items, total {amount}',
        '@cart_summary': {
          'placeholders': {
            'count': {'type': 'int'},
            'amount': {'type': 'double', 'format': 'currency'},
          },
        },
      });
      await writeJsonFile(tempDir!.path, 'app_tr.arb', {
        '@@locale': 'tr',
        'cart_summary': '{count} öğe, toplam {amount}',
        '@cart_summary': {
          'placeholders': {
            'count': {'type': 'String'},
            'amount': {'type': 'double', 'format': 'currency'},
          },
        },
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.strict,
      );

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('expected type "int"')), isTrue);
    });

    test('balanced profile keeps schema metadata gaps as warnings', () async {
      await writeJsonFile(tempDir!.path, 'app_en.arb', {
        '@@locale': 'en',
        'cart_summary': '{count} items',
        '@cart_summary': {
          'placeholders': {
            'count': {'type': 'int'},
          },
        },
      });
      await writeJsonFile(tempDir!.path, 'app_tr.arb', {
        '@@locale': 'tr',
        'cart_summary': '{count} öğe',
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.balanced,
      );

      expect(result.isValid, isTrue);
      expect(result.hasWarnings, isTrue);
      expect(result.warnings.any((e) => e.contains('metadata missing')), isTrue);
    });

    test('schema sidecar can enforce placeholder type consistency', () async {
      await writeJsonFile(tempDir!.path, 'en.json', {
        'cart_summary': '{count} items, total {amount}',
      });
      await writeJsonFile(tempDir!.path, 'tr.json', {
        'cart_summary': '{count} öğe, toplam {amount}',
      });
      final schemaFile = await writeJsonFile(tempDir!.path, 'placeholder_schema.json', {
        'default': {
          'cart_summary': {
            'count': {'type': 'int', 'required': true},
            'amount': {'type': 'double', 'format': 'currency'},
          },
        },
        'locales': {
          'tr': {
            'cart_summary': {
              'count': {'type': 'String'},
              'amount': {'type': 'double', 'format': 'currency'},
            },
          },
        },
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.strict,
        schemaFilePath: schemaFile.path,
      );

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('expected type "int"')), isTrue);
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

    test('balanced profile reports extra keys as warnings', () async {
      await writeJsonFile(tempDir!.path, 'en.json', {'hello': 'Hello'});
      await writeJsonFile(tempDir!.path, 'tr.json', {
        'hello': 'Merhaba',
        'extra': 'Fazla',
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.balanced,
      );

      expect(result.isValid, isTrue);
      expect(result.hasWarnings, isTrue);
      expect(result.warnings.single, contains('has extra keys'));
    });

    test('strict profile can fail on warnings deterministically', () async {
      await writeJsonFile(tempDir!.path, 'en.json', {'hello': 'Hello'});
      await writeJsonFile(tempDir!.path, 'tr.json', {
        'hello': 'Merhaba',
        'extra': 'Fazla',
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.strict,
        treatExtraKeysAsWarnings: true,
        failOnWarnings: true,
      );

      expect(result.isValid, isFalse);
      expect(result.errors, isEmpty);
      expect(result.warnings.single, contains('has extra keys'));
    });

    test('lenient profile ignores placeholder mismatches', () async {
      await writeJsonFile(tempDir!.path, 'en.json', {
        'welcome_user': 'Welcome {name}',
      });
      await writeJsonFile(tempDir!.path, 'tr.json', {
        'welcome_user': 'Merhaba {username}',
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.lenient,
      );

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('lenient profile keeps disabled rules when overriding one toggle', () async {
      await writeJsonFile(tempDir!.path, 'en.json', {
        'welcome_user': 'Welcome {name}',
        'bye': 'Bye',
      });
      await writeJsonFile(tempDir!.path, 'tr.json', {
        'welcome_user': 'Merhaba {username}',
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.lenient,
        ruleToggles: const core_validator.ValidationRuleToggles(
          checkMissingKeys: false,
        ),
      );

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('rule toggles can disable placeholder check in strict mode', () async {
      await writeJsonFile(tempDir!.path, 'en.json', {
        'welcome_user': 'Welcome {name}',
      });
      await writeJsonFile(tempDir!.path, 'tr.json', {
        'welcome_user': 'Merhaba {username}',
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.strict,
        ruleToggles: const core_validator.ValidationRuleToggles(
          checkPlaceholders: false,
        ),
      );

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('plural and gender rules can be toggled independently', () async {
      await writeJsonFile(tempDir!.path, 'en.json', {
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
      await writeJsonFile(tempDir!.path, 'tr.json', {
        'cart': {
          'items': {
            'one': {
              'male': '{count} ürün',
            },
            'other': '{count} ürün',
          },
        },
      });

      final withRules = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.strict,
        ruleToggles: const core_validator.ValidationRuleToggles(
          checkMissingKeys: false,
          checkPluralForms: true,
          checkGenderForms: true,
        ),
      );
      expect(withRules.isValid, isFalse);
      expect(withRules.errors.any((item) => item.contains('Gender forms mismatch')), isTrue);

      final withoutRules = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.strict,
        ruleToggles: const core_validator.ValidationRuleToggles(
          checkMissingKeys: false,
          checkPluralForms: false,
          checkGenderForms: false,
        ),
      );
      expect(withoutRules.isValid, isTrue);
    });

    test('English scope validation passes without Arabic-only features', () async {
      await writeJsonFile(tempDir!.path, 'en.json', {
        'welcome': 'Welcome',
        'itemsCount': {'one': '{count} item', 'other': '{count} items'},
      });
      await writeJsonFile(tempDir!.path, 'en_US.json', {
        'welcome': 'Welcome',
        'itemsCount': {'one': '{count} item', 'other': '{count} items'},
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.strict,
      );

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(
        result.errors.where((e) => e.contains('Plural forms mismatch') || e.contains('Gender')),
        isEmpty,
      );
    });
  });

  group('CLI workflow', () {
    Directory? tempDir;

    Future<ProcessResult> runCli(
      List<String> args, {
      String executable = 'anas_cli',
      String? workingDirectory,
    }) {
      return Process.run(
        'dart',
        ['run', 'anas_localization:$executable', ...args],
        workingDirectory: workingDirectory,
      );
    }

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('i18n_cli_');
    });

    tearDown(() {
      tempDir?.deleteSync(recursive: true);
    });

    test('cli alias command works', () async {
      final result = await runCli(['help'], executable: 'cli');

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Anas Localization CLI Tool'));
    });

    test('anas alias command works', () async {
      final result = await runCli(['help'], executable: 'anas');

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Anas Localization CLI Tool'));
      expect(result.stdout.toString(), contains('anas convert --from easy_localization'));
      expect(result.stdout.toString(), contains('validate-migration'));
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

    test('convert imports gen_l10n ARB files into normalized JSON', () async {
      final workspace = Directory('${tempDir!.path}/convert_gen_l10n')..createSync(recursive: true);
      final arbDir = Directory('${workspace.path}/lib/l10n')..createSync(recursive: true);
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
      final l10nYaml = File('${workspace.path}/l10n.yaml');
      await l10nYaml.writeAsString('''
arb-dir: lib/l10n
template-arb-file: app_en.arb
''');

      final outputDir = Directory('${tempDir!.path}/converted_from_gen_l10n');
      final result = await runCli([
        'convert',
        '--from',
        'gen_l10n',
        '--source',
        l10nYaml.path,
        '--out',
        outputDir.path,
      ]);

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Converted gen_l10n translations.'));
      expect(result.stdout.toString(), contains('doc/MIGRATION_GEN_L10N.md'));

      final trMap = jsonDecode(await File('${outputDir.path}/tr.json').readAsString()) as Map<String, dynamic>;
      expect((trMap['home'] as Map<String, dynamic>)['title'], equals('Ana Sayfa'));
    });

    test('convert imports easy_localization JSON files into normalized JSON', () async {
      final sourceDir = Directory('${tempDir!.path}/easy_json')..createSync(recursive: true);
      await File('${sourceDir.path}/en.json').writeAsString(
        jsonEncode({
          'home': {'title': 'Home'},
        }),
      );
      await File('${sourceDir.path}/tr.json').writeAsString(
        jsonEncode({
          'home': {'title': 'Ana Sayfa'},
        }),
      );

      final outputDir = Directory('${tempDir!.path}/converted_easy_json');
      final result = await runCli([
        'convert',
        '--from',
        'easy_localization',
        '--source',
        sourceDir.path,
        '--out',
        outputDir.path,
      ]);

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Locales: en, tr'));

      final enMap = jsonDecode(await File('${outputDir.path}/en.json').readAsString()) as Map<String, dynamic>;
      expect((enMap['home'] as Map<String, dynamic>)['title'], equals('Home'));
    });

    test('convert imports easy_localization YAML files into normalized JSON', () async {
      final sourceDir = Directory('${tempDir!.path}/easy_yaml')..createSync(recursive: true);
      await File('${sourceDir.path}/en.yaml').writeAsString('''
home:
  title: Home
''');
      await File('${sourceDir.path}/ar.yml').writeAsString('''
home:
  title: الرئيسية
''');

      final outputDir = Directory('${tempDir!.path}/converted_easy_yaml');
      final result = await runCli([
        'convert',
        '--from',
        'easy_localization',
        '--source',
        sourceDir.path,
        '--out',
        outputDir.path,
      ]);

      expect(result.exitCode, equals(0));
      final arMap = jsonDecode(await File('${outputDir.path}/ar.json').readAsString()) as Map<String, dynamic>;
      expect((arMap['home'] as Map<String, dynamic>)['title'], equals('الرئيسية'));
    });

    test('convert imports easy_localization CSV files into normalized JSON', () async {
      final sourceDir = Directory('${tempDir!.path}/easy_csv')..createSync(recursive: true);
      await File('${sourceDir.path}/en.csv').writeAsString('''
key,value
home.title,Home
cart.items,"{""one"":""{count} item"",""other"":""{count} items""}"
''');
      await File('${sourceDir.path}/fr.csv').writeAsString('''
key,value
home.title,Accueil
cart.items,"{""one"":""{count} article"",""other"":""{count} articles""}"
''');

      final outputDir = Directory('${tempDir!.path}/converted_easy_csv');
      final result = await runCli([
        'convert',
        '--from',
        'easy_localization',
        '--source',
        sourceDir.path,
        '--out',
        outputDir.path,
      ]);

      expect(result.exitCode, equals(0));
      final frMap = jsonDecode(await File('${outputDir.path}/fr.json').readAsString()) as Map<String, dynamic>;
      expect((frMap['home'] as Map<String, dynamic>)['title'], equals('Accueil'));
      expect((frMap['cart'] as Map<String, dynamic>)['items'], isA<Map<String, dynamic>>());
    });

    test('convert prints clickable issue URL for unsupported packages', () async {
      final result = await runCli([
        'convert',
        '--from',
        'foo_localizer',
      ]);

      expect(result.exitCode, isNonZero);
      expect(result.stderr.toString(), contains('Package "foo_localizer" is not supported yet.'));
      expect(
        result.stderr.toString(),
        contains(
          'https://github.com/Melsaeed276/anas_localization/issues/new?title=Support+converter+for+foo_localizer',
        ),
      );
    });

    test('convert returns non-zero when --from is missing', () async {
      final result = await runCli(['convert']);

      expect(result.exitCode, isNonZero);
      expect(result.stderr.toString(), contains('Usage: convert --from <package>'));
    });

    test('convert returns non-zero when default gen_l10n source is missing', () async {
      final result = await runCli([
        'convert',
        '--from',
        'gen_l10n',
      ]);

      expect(result.exitCode, isNonZero);
      final stderr = result.stderr.toString();
      expect(
        stderr.contains('l10n.yaml source file not found') || stderr.contains('ARB directory not found'),
        isTrue,
        reason: 'Expected convert to report missing l10n.yaml or ARB dir, got: $stderr',
      );
    });

    test('convert returns non-zero when default easy_localization source is missing', () async {
      final result = await runCli([
        'convert',
        '--from',
        'easy_localization',
      ]);

      expect(result.exitCode, isNonZero);
      expect(result.stderr.toString(), contains('easy_localization source directory not found'));
    });

    test('convert returns non-zero for mixed easy_localization formats', () async {
      final sourceDir = Directory('${tempDir!.path}/easy_mixed')..createSync(recursive: true);
      await File('${sourceDir.path}/en.json').writeAsString(jsonEncode({'home': 'Home'}));
      await File('${sourceDir.path}/tr.yaml').writeAsString('home: Ana Sayfa');

      final outputDir = Directory('${tempDir!.path}/converted_easy_mixed');
      final result = await runCli([
        'convert',
        '--from',
        'easy_localization',
        '--source',
        sourceDir.path,
        '--out',
        outputDir.path,
      ]);

      expect(result.exitCode, isNonZero);
      expect(result.stderr.toString(), contains('Mixed easy_localization source formats are not supported.'));
    });

    test('migrate dry run rewrites easy_localization callsites without writing files', () async {
      final langDir = Directory('${tempDir!.path}/migrate_easy_lang')..createSync(recursive: true);
      await File('${langDir.path}/en.json').writeAsString(
        jsonEncode({
          'home': {'title': 'Home'},
        }),
      );

      final sourceFile = File('${tempDir!.path}/page.dart');
      await sourceFile.writeAsString('''
import 'package:easy_localization/easy_localization.dart';

String title() => 'home.title'.tr();
''');

      final result = await runCli([
        'migrate',
        '--from',
        'easy_localization',
        '--lang-dir',
        langDir.path,
        '--target',
        sourceFile.path,
        '--dry-run',
      ]);

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Dry run migration for easy_localization.'));
      expect(result.stdout.toString(), contains('getDictionary().homeTitle'));
      expect(await sourceFile.readAsString(), contains("'home.title'.tr()"));
    });

    test('migrate dry run rewrites gen_l10n callsites', () async {
      final langDir = Directory('${tempDir!.path}/migrate_gen_lang')..createSync(recursive: true);
      await File('${langDir.path}/en.json').writeAsString(
        jsonEncode({
          'welcome_title': 'Welcome',
        }),
      );

      final sourceFile = File('${tempDir!.path}/gen_page.dart');
      await sourceFile.writeAsString('''
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

String title(BuildContext context) => AppLocalizations.of(context)!.welcomeTitle;
''');

      final result = await runCli([
        'migrate',
        '--from',
        'gen_l10n',
        '--lang-dir',
        langDir.path,
        '--target',
        sourceFile.path,
        '--dry-run',
      ]);

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('getDictionary().welcomeTitle'));
      expect(await sourceFile.readAsString(), contains('AppLocalizations.of(context)!.welcomeTitle'));
    });

    test('convert --rewrite forwards to migration and supports explicit test paths', () async {
      final langDir = Directory('${tempDir!.path}/rewrite_lang')..createSync(recursive: true);
      await File('${langDir.path}/en.json').writeAsString(
        jsonEncode({
          'home': {'title': 'Home'},
        }),
      );

      final libFile = File('${tempDir!.path}/rewrite_page.dart');
      await libFile.writeAsString('''
import 'package:easy_localization/easy_localization.dart';

String title() => 'home.title'.tr();
''');

      final testFile = File('${tempDir!.path}/widget_test.dart');
      await testFile.writeAsString('''
import 'package:easy_localization/easy_localization.dart';

String title() => 'home.title'.tr();
''');

      final result = await runCli([
        'convert',
        '--from',
        'easy_localization',
        '--rewrite',
        '--lang-dir',
        langDir.path,
        '--target',
        libFile.path,
        '--test',
        testFile.path,
        '--dry-run',
      ]);

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Dry run migration for easy_localization.'));
      expect(result.stdout.toString(), contains(testFile.path));
      expect(result.stdout.toString(), contains('getDictionary().homeTitle'));
    });

    test('migrate --apply updates explicitly targeted test files', () async {
      final langDir = Directory('${tempDir!.path}/apply_lang')..createSync(recursive: true);
      await File('${langDir.path}/en.json').writeAsString(
        jsonEncode({
          'home': {'title': 'Home'},
        }),
      );

      final libFile = File('${tempDir!.path}/apply_page.dart');
      await libFile.writeAsString('''
import 'package:easy_localization/easy_localization.dart';

String libTitle() => 'home.title'.tr();
''');

      final testDir = Directory('${tempDir!.path}/test')..createSync(recursive: true);
      final testFile = File('${testDir.path}/widget_test.dart');
      await testFile.writeAsString('''
import 'package:easy_localization/easy_localization.dart';

String testTitle() => 'home.title'.tr();
''');

      final result = await runCli([
        'migrate',
        '--from',
        'easy_localization',
        '--lang-dir',
        langDir.path,
        '--target',
        libFile.path,
        '--test',
        testDir.path,
        '--apply',
      ]);

      expect(result.exitCode, equals(0));
      expect(await libFile.readAsString(), contains('getDictionary().homeTitle'));
      expect(await testFile.readAsString(), contains('getDictionary().homeTitle'));
    });

    test(
      'validate-migration runs easy_localization demo flow and writes a report',
      () async {
        final reportFile = File('${tempDir!.path}/migration_report_easy.json');
        final baselineFile = File('${tempDir!.path}/migration_baseline_easy.json');

        final result = await runCli([
          'validate-migration',
          '--from',
          'easy_localization',
          '--temp-dir',
          tempDir!.path,
          '--report',
          reportFile.path,
          '--compare',
          baselineFile.path,
          '--update-baseline',
        ]);

        expect(result.exitCode, equals(0));
        expect(result.stdout.toString(), contains('Migration validation complete.'));
        expect(reportFile.existsSync(), isTrue);

        final report = jsonDecode(await reportFile.readAsString()) as Map<String, dynamic>;
        final results = report['results'] as List<dynamic>;
        expect(results, hasLength(1));
        expect((results.first as Map<String, dynamic>)['sourcePackage'], equals('easy_localization'));
        expect((results.first)['success'], isTrue);
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );

    test(
      'validate-migration warns on timing regressions without failing functional validation',
      () async {
        final reportFile = File('${tempDir!.path}/migration_report_gen.json');
        final baselineFile = File('${tempDir!.path}/migration_baseline_gen.json');
        await baselineFile.writeAsString(
          jsonEncode({
            'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
            'os': 'test-os',
            'runtime': 'test-runtime',
            'threshold': 0.25,
            'results': [
              {
                'sourcePackage': 'gen_l10n',
                'workspacePath': '/tmp/fake',
                'success': true,
                'steps': [
                  {
                    'name': 'generate-demo',
                    'durationMs': 1,
                    'success': true,
                  },
                  {
                    'name': 'flutter-pub-get',
                    'durationMs': 1,
                    'success': true,
                  },
                  {
                    'name': 'convert',
                    'durationMs': 1,
                    'success': true,
                  },
                  {
                    'name': 'migrate',
                    'durationMs': 1,
                    'success': true,
                  },
                  {
                    'name': 'codegen',
                    'durationMs': 1,
                    'success': true,
                  },
                  {
                    'name': 'analyze',
                    'durationMs': 1,
                    'success': true,
                  },
                  {
                    'name': 'test',
                    'durationMs': 1,
                    'success': true,
                  },
                ],
                'totalDurationMs': 7,
                'warnings': [],
              },
            ],
            'regressions': [],
            'globalWarnings': [],
          }),
        );

        final result = await runCli([
          'validate-migration',
          '--from',
          'gen_l10n',
          '--temp-dir',
          tempDir!.path,
          '--report',
          reportFile.path,
          '--compare',
          baselineFile.path,
        ]);

        expect(result.exitCode, equals(0));
        expect(result.stdout.toString(), contains('Timing regressions:'));
        expect(reportFile.existsSync(), isTrue);

        final report = jsonDecode(await reportFile.readAsString()) as Map<String, dynamic>;
        final regressions = report['regressions'] as List<dynamic>;
        expect(regressions, isNotEmpty);
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );

    test('validate supports strict profile and fail-on-warnings flags', () async {
      final langDir = Directory('${tempDir!.path}/lang')..createSync(recursive: true);
      await File('${langDir.path}/en.json').writeAsString(jsonEncode({'hello': 'Hello'}));
      await File('${langDir.path}/tr.json').writeAsString(
        jsonEncode({
          'hello': 'Merhaba',
          'extra': 'Fazla',
        }),
      );

      final strictResult = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'validate',
          langDir.path,
          '--profile=strict',
        ],
      );
      expect(strictResult.exitCode, isNonZero);

      final failWarningsResult = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'validate',
          langDir.path,
          '--profile=strict',
          '--extra-as-warnings',
          '--fail-on-warnings',
        ],
      );
      expect(failWarningsResult.exitCode, isNonZero);
      expect(failWarningsResult.stdout.toString(), contains('Warnings'));
    });

    test('validate accepts regional English with en as base and regional overrides', () async {
      final langDir = Directory('${tempDir!.path}/lang')..createSync(recursive: true);
      await File('${langDir.path}/en.json').writeAsString(
        jsonEncode({
          'hello': 'Hello',
          'colorLabel': 'Color',
          'itemsCount': {'one': '{count} item', 'other': '{count} items'},
        }),
      );
      await File('${langDir.path}/en_US.json').writeAsString(
        jsonEncode({
          'hello': 'Hello',
          'colorLabel': 'Color',
          'itemsCount': {'one': '{count} item', 'other': '{count} items'},
        }),
      );
      await File('${langDir.path}/en_GB.json').writeAsString(
        jsonEncode({
          'hello': 'Hello',
          'colorLabel': 'Colour',
          'itemsCount': {'one': '{count} item', 'other': '{count} items'},
        }),
      );

      final result = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'validate',
          langDir.path,
          '--profile=balanced',
        ],
      );

      expect(result.exitCode, equals(0));
    });

    test('validate supports schema file option', () async {
      final langDir = Directory('${tempDir!.path}/lang')..createSync(recursive: true);
      await File('${langDir.path}/en.json').writeAsString(
        jsonEncode({'cart_summary': '{count} items'}),
      );
      await File('${langDir.path}/tr.json').writeAsString(
        jsonEncode({'cart_summary': '{count} öğe'}),
      );

      final schemaFile = File('${tempDir!.path}/schema.json');
      await schemaFile.writeAsString(
        jsonEncode({
          'default': {
            'cart_summary': {
              'count': {'type': 'int'},
            },
          },
          'locales': {
            'tr': {
              'cart_summary': {
                'count': {'type': 'String'},
              },
            },
          },
        }),
      );

      final result = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'validate',
          langDir.path,
          '--profile=strict',
          '--schema-file=${schemaFile.path}',
        ],
      );

      expect(result.exitCode, isNonZero);
      expect(result.stderr.toString(), contains('expected type "int"'));
    });

    test('import returns non-zero for malformed json payload', () async {
      final malformed = File('${tempDir!.path}/broken.json');
      await malformed.writeAsString('{"en": {"hello": "Hello",}');
      final importDir = Directory('${tempDir!.path}/imported_broken_json');

      final result = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'import',
          malformed.path,
          importDir.path,
        ],
      );

      expect(result.exitCode, isNonZero);
      expect(result.stderr.toString(), contains('JSON import failed'));
    });

    test('import returns non-zero for malformed csv header', () async {
      final malformed = File('${tempDir!.path}/broken.csv');
      await malformed.writeAsString('locale,en\nhome.title,Home');
      final importDir = Directory('${tempDir!.path}/imported_broken_csv');

      final result = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'import',
          malformed.path,
          importDir.path,
        ],
      );

      expect(result.exitCode, isNonZero);
      expect(result.stderr.toString(), contains('CSV header must start with "key".'));
    });

    test('import returns non-zero for malformed arb payload', () async {
      final malformed = File('${tempDir!.path}/broken.arb');
      await malformed.writeAsString('{"@@locale":"en","hello":"Hello",}');
      final importDir = Directory('${tempDir!.path}/imported_broken_arb');

      final result = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'import',
          malformed.path,
          importDir.path,
        ],
      );

      expect(result.exitCode, isNonZero);
      expect(result.stderr.toString(), contains('ARB import failed'));
    });

    test('export returns non-zero for unsupported format', () async {
      final langDir = Directory('${tempDir!.path}/lang')..createSync(recursive: true);
      await File('${langDir.path}/en.json').writeAsString(jsonEncode({'hello': 'Hello'}));

      final result = await Process.run(
        'dart',
        [
          'run',
          'anas_localization:anas_cli',
          'export',
          langDir.path,
          'xml',
        ],
      );

      expect(result.exitCode, isNonZero);
      expect(result.stderr.toString(), contains('Unsupported format'));
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
            'SUPPORTED_LOCALES': 'en,tr,ar',
          },
        );

        expect(result.exitCode, equals(0), reason: '${result.stdout}\n${result.stderr}');
        final generated = await File(outputPath).readAsString();
        expect(generated, contains('String get checkoutTitle => getString(\'checkout.title\');'));
        expect(generated, contains('String checkoutItems({required num count}) {'));
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('generates namespaced module surfaces and avoids collisions', () async {
      final tempDir = Directory.systemTemp.createTempSync('i18n_codegen_modules_');

      Future<void> writeOverride(String locale, Map<String, dynamic> data) async {
        final file = File('${tempDir.path}/$locale.json');
        await file.create(recursive: true);
        await file.writeAsString(jsonEncode(data));
      }

      try {
        const payload = {
          'home': {
            'title': 'Home',
            'summary': {'items': '{count} items'},
          },
          'home-screen': {
            'title': 'Home Screen',
          },
          'checkout': {
            'title': 'Checkout',
          },
        };
        await writeOverride('en', payload);
        await writeOverride('tr', payload);
        await writeOverride('ar', payload);

        final outputPath = '${tempDir.path}/dictionary.dart';
        final result = await Process.run(
          'dart',
          [
            'run',
            'anas_localization:localization_gen',
            '--modules',
            '--module-depth=1',
          ],
          environment: {
            'APP_LANG_DIR': tempDir.path,
            'OUTPUT_DART': outputPath,
            'SUPPORTED_LOCALES': 'en,tr,ar',
          },
        );

        expect(result.exitCode, equals(0), reason: '${result.stdout}\n${result.stderr}');
        final generated = await File(outputPath).readAsString();
        expect(generated, contains('class HomeModule {'));
        expect(generated, contains('late final HomeModule home = HomeModule(this);'));
        expect(generated, contains('late final HomeScreenModule homeScreen = HomeScreenModule(this);'));
        expect(generated, contains('String summaryItems({required String count}) {'));
        expect(generated, contains('String homeSummaryItems({required String count}) {'));
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('modules-only mode keeps namespaced APIs off root surface', () async {
      final tempDir = Directory.systemTemp.createTempSync('i18n_codegen_modules_only_');

      Future<void> writeOverride(String locale, Map<String, dynamic> data) async {
        final file = File('${tempDir.path}/$locale.json');
        await file.create(recursive: true);
        await file.writeAsString(jsonEncode(data));
      }

      try {
        const payload = {
          'settings': {
            'title': 'Settings',
          },
          'simple_key': 'Simple',
        };
        await writeOverride('en', payload);
        await writeOverride('tr', payload);
        await writeOverride('ar', payload);

        final outputPath = '${tempDir.path}/dictionary.dart';
        final result = await Process.run(
          'dart',
          [
            'run',
            'anas_localization:localization_gen',
            '--modules-only',
          ],
          environment: {
            'APP_LANG_DIR': tempDir.path,
            'OUTPUT_DART': outputPath,
            'SUPPORTED_LOCALES': 'en,tr,ar',
          },
        );

        expect(result.exitCode, equals(0), reason: '${result.stdout}\n${result.stderr}');
        final generated = await File(outputPath).readAsString();
        expect(generated, contains('class SettingsModule {'));
        expect(generated, contains('late final SettingsModule settings = SettingsModule(this);'));
        expect(generated, isNot(contains('String get settingsTitle => getString(\'settings.title\');')));
        expect(generated, contains('String get simpleKey => getString(\'simple_key\');'));
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('module-depth splits namespaces by configured prefix depth', () async {
      final tempDir = Directory.systemTemp.createTempSync('i18n_codegen_module_depth_');

      Future<void> writeOverride(String locale, Map<String, dynamic> data) async {
        final file = File('${tempDir.path}/$locale.json');
        await file.create(recursive: true);
        await file.writeAsString(jsonEncode(data));
      }

      try {
        const payload = {
          'feature': {
            'auth': {
              'login': {
                'title': 'Login',
              },
            },
            'billing': {
              'invoice': {
                'title': 'Invoice',
              },
            },
          },
        };
        await writeOverride('en', payload);
        await writeOverride('tr', payload);
        await writeOverride('ar', payload);

        final outputPath = '${tempDir.path}/dictionary.dart';
        final result = await Process.run(
          'dart',
          [
            'run',
            'anas_localization:localization_gen',
            '--modules',
            '--module-depth=2',
          ],
          environment: {
            'APP_LANG_DIR': tempDir.path,
            'OUTPUT_DART': outputPath,
            'SUPPORTED_LOCALES': 'en,tr,ar',
          },
        );

        expect(result.exitCode, equals(0), reason: '${result.stdout}\n${result.stderr}');
        final generated = await File(outputPath).readAsString();
        expect(generated, contains('class FeatureAuthModule {'));
        expect(generated, contains('class FeatureBillingModule {'));
        expect(generated, contains('late final FeatureAuthModule featureAuth = FeatureAuthModule(this);'));
        expect(generated, contains('String get loginTitle => _dictionary.getString(\'feature.auth.login.title\');'));
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test(
      'watch mode regenerates output after file changes',
      () async {
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
              'SUPPORTED_LOCALES': 'en,tr,ar',
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
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );
  });

  group('Regional English validation', () {
    Directory? tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('i18n_regional_en_');
    });

    tearDown(() {
      tempDir?.deleteSync(recursive: true);
    });

    Future<File> writeJsonFile(String filename, Map<String, dynamic> data) async {
      final file = File('${tempDir!.path}/$filename');
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(data));
      return file;
    }

    test('regional en_GB overlay passes validation without requiring all base en keys', () async {
      await writeJsonFile('en.json', {
        'appTitle': 'Anas Catalog',
        'colorLabel': 'Color',
        'cancel': 'Cancel',
      });
      await writeJsonFile('en_GB.json', {
        'colorLabel': 'Colour',
        'catalogLanguage': 'Catalogue Language',
      });

      final result = await core_validator.TranslationValidator.validateTranslations(tempDir!.path);

      expect(
        result.errors.where((e) => e.contains('en_GB.json missing keys')),
        isEmpty,
        reason: 'Regional overlay should not fail for missing base keys',
      );
    });

    test('all four regional English overlays pass validation without requiring full key set', () async {
      await writeJsonFile('en.json', {
        'colorLabel': 'Color',
        'appTitle': 'App',
        'cancel': 'Cancel',
      });
      for (final variant in ['en_US', 'en_GB', 'en_CA', 'en_AU']) {
        await writeJsonFile('$variant.json', {'colorLabel': 'Colour'});
      }

      final result = await core_validator.TranslationValidator.validateTranslations(tempDir!.path);

      for (final variant in ['en_US', 'en_GB', 'en_CA', 'en_AU']) {
        expect(
          result.errors.where((e) => e.contains('$variant.json missing keys')),
          isEmpty,
          reason: '$variant should not fail missing-key check as regional overlay',
        );
      }
    });

    test('English locale with one/other plural data passes validation without Arabic six-form requirement', () async {
      await writeJsonFile('en.json', {
        'itemsCount': {
          'one': '{count} item',
          'other': '{count} items',
        },
      });
      await writeJsonFile('en_US.json', <String, dynamic>{});

      final result = await core_validator.TranslationValidator.validateTranslations(tempDir!.path);

      expect(result.isValid, isTrue, reason: 'English one/other plural should pass validation');
      expect(result.errors, isEmpty);
    });

    test('English regional locale file is recognized as English and not required to have Arabic plural forms',
        () async {
      await writeJsonFile('en.json', {
        'items': {
          '_type': 'plural',
          'one': '{count} item',
          'other': '{count} items',
        },
      });
      await writeJsonFile('en_GB.json', {
        'items': {
          '_type': 'plural',
          'one': '{count} item',
          'other': '{count} items',
        },
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.strict,
      );

      expect(
        result.warnings.where((w) => w.contains('en_GB') && w.contains('zero')),
        isEmpty,
        reason: 'en_GB should not be warned about missing Arabic plural forms',
      );
    });
  });

  group('English-vs-Arabic validation regression (US3)', () {
    Directory? tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('i18n_en_ar_regression_');
    });

    tearDown(() {
      tempDir?.deleteSync(recursive: true);
    });

    Future<File> writeJsonFile(String filename, Map<String, dynamic> data) async {
      final file = File('${tempDir!.path}/$filename');
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(data));
      return file;
    }

    test('Arabic locale with six plural forms passes validation when English base has one/other', () async {
      await writeJsonFile('en.json', {
        'itemsCount': {
          'one': '{count} item',
          'other': '{count} items',
        },
      });
      await writeJsonFile('ar.json', {
        'itemsCount': {
          'zero': '{count} عناصر',
          'one': '{count} عنصر',
          'two': '{count} عنصران',
          'few': '{count} عناصر',
          'many': '{count} عنصرًا',
          'other': '{count} عنصر',
        },
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.balanced,
      );

      expect(
        result.errors.where((e) => e.contains('ar.json') && e.contains('extra keys')),
        isEmpty,
        reason: 'Arabic extra plural forms should be allowed when base is English',
      );
      expect(
        result.isValid,
        isTrue,
        reason: 'Validation should pass with English one/other base and Arabic six-form translation',
      );
    });

    test('English file with Arabic-specific plural forms passes validation (extra forms allowed)', () async {
      await writeJsonFile('en.json', {
        'cart': {
          'one': '{count} item',
          'other': '{count} items',
        },
      });
      await writeJsonFile('ar.json', {
        'cart': {
          'zero': '{count} عنصر',
          'one': '{count} عنصر',
          'two': '{count} عنصران',
          'few': '{count} عناصر',
          'many': '{count} عنصرًا',
          'other': '{count} عنصر',
        },
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.lenient,
      );

      expect(result.errors, isEmpty, reason: 'Lenient profile should not error on Arabic having extra forms');
    });

    test('English locale optional-type plural warning uses one/other only, not six-form', () async {
      await writeJsonFile('en.json', {
        'cart': {
          '_type': 'plural',
          'other': '{count} items',
        },
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.balanced,
      );

      final warnings = result.warnings.where((w) => w.contains('cart')).toList();
      expect(
        warnings.any((w) => w.contains("'one'")),
        isTrue,
        reason: 'Should warn about missing one form for English',
      );
      expect(
        warnings.any((w) => w.contains("'zero'") || w.contains("'two'") || w.contains("'few'") || w.contains("'many'")),
        isFalse,
        reason: 'English should not warn about Arabic six-form requirements',
      );
    });

    test('Arabic locale optional-type plural warning uses six-form requirement', () async {
      await writeJsonFile('en.json', {
        'items': '{count} items',
      });
      await writeJsonFile('ar.json', {
        'items': {
          '_type': 'plural',
          'one': '{count} عنصر',
          'other': '{count} عنصر',
        },
      });

      final result = await core_validator.TranslationValidator.validateTranslations(
        tempDir!.path,
        profile: core_validator.ValidationProfile.balanced,
      );

      final arWarnings = result.warnings.where((w) => w.contains('ar:')).toList();
      final missingArabicForms = arWarnings
          .where((w) => w.contains("'zero'") || w.contains("'two'") || w.contains("'few'") || w.contains("'many'"));
      expect(
        missingArabicForms,
        isNotEmpty,
        reason: 'Arabic locale should warn about missing six-form plural requirements',
      );
    });
  });
}
