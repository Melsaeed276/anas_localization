import 'dart:convert';
import 'dart:io';
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

    Future<File> writeJsonFile(String dir, String filename, Map<String, dynamic> data) async {
      final file = File('$dir/$filename');
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(data));
      return file;
    }

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
    // This is trickier to test, because it involves running a script.
    // A robust way is to invoke the script as a subprocess and check output file.
    // Here is a simple structure:
    test('generates Dictionary class file', () async {
      final tempDir = Directory.systemTemp.createTempSync('i18n_codegen_');

      final codegenScript = File('bin/generate_dictionary.dart');
      final result = await Process.run('dart', [
        codegenScript.path,
      ], environment: {
        'OUTPUT_DART': '${tempDir.path}/dictionary.dart',
      });

      expect(result.exitCode, equals(0));
      final outputFile = File('${tempDir.path}/dictionary.dart');
      expect(outputFile.existsSync(), isTrue);

      final contents = await outputFile.readAsString();
      expect(contents, contains('class Dictionary'));
      expect(contents, contains('final String welcome;'));
      expect(contents, contains('factory Dictionary.fromMap'));
    });
  });
}
