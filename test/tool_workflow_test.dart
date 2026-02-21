import 'dart:convert';
import 'dart:io';

import 'package:anas_localization/src/utils/codegen_utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../bin/validate_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      final validator = TranslationValidator(
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

      final validator = TranslationValidator(
        masterFilePath: '${tempDir!.path}/en.json',
        langDirectoryPath: tempDir!.path,
      );
      final result = await validator.validate();
      expect(result, isTrue);
    });

    test('succeeds when only the master file exists', () async {
      final master = {'hello': 'Hello', 'bye': 'Bye'};
      await writeJsonFile(tempDir!.path, 'en.json', master);

      final validator = TranslationValidator(
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

      final validator = TranslationValidator(
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

      final validator = TranslationValidator(
        masterFilePath: '${tempDir!.path}/en.json',
        langDirectoryPath: tempDir!.path,
      );
      final result = await validator.validate();
      expect(result, isFalse);
    });
  });

  group('Dictionary code generation', () {
    test('generates Dictionary class file with field from source keys', () async {
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
        expect(contents, contains('factory Dictionary.fromMap'));

        final enMap = jsonDecode(await File('assets/lang/en.json').readAsString())
            as Map<String, dynamic>;
        final sampleStringKey = enMap.entries.firstWhere((e) => e.value is String).key;
        final expectedFieldName =
            sanitizeDartIdentifier(snakeToCamel(sampleStringKey));

        expect(contents, contains('final String $expectedFieldName;'));
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
