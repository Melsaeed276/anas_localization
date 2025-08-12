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
    test('generates Dictionary class from master json', () async {
      // Create a temp dir and files
      final tempDir = Directory.systemTemp.createTempSync('i18n_codegen_');
      final master = {'hello': 'Hello', 'bye_message': 'Bye {user}!'};
      final masterFile = File('${tempDir.path}/en.json');
      await masterFile.create(recursive: true);
      await masterFile.writeAsString(jsonEncode(master));

      // Copy your codegen and utils to temp dir if needed, or patch imports for this test
      // For now, just check the file can be created
      final codegenScript = File('bin/generate_dictionary.dart');
      final result = await Process.run('dart', [
        codegenScript.path,
      ], environment: {
        'MASTER_JSON': masterFile.path,
        'OUTPUT_DART': '${tempDir.path}/dictionary.dart',
      });
      // if (result.exitCode != 0) {
      //   print('STDOUT: ${result.stdout}');
      //   print('STDERR: ${result.stderr}');
      // }

      expect(result.exitCode, equals(0));
      final outputFile = File('${tempDir.path}/dictionary.dart');
      expect(outputFile.existsSync(), isTrue);

      final contents = await outputFile.readAsString();
      expect(contents, contains('class Dictionary'));
      expect(contents, contains('final String hello;'));
      expect(contents, contains('String byeMessage(String user)'));
    });
  });
}