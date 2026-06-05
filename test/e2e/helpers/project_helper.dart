import 'dart:convert';
import 'dart:io';

class ProjectHelper {
  ProjectHelper({required this.packageRoot});

  final String packageRoot;
  late final Directory tempDir;

  Directory get langDir => Directory('${tempDir.path}/assets/lang');
  Directory get generatedDir => Directory('${tempDir.path}/lib/generated');
  File get generatedDictionary => File('${tempDir.path}/lib/generated/dictionary.dart');

  Future<void> setUp() async {
    tempDir = Directory.systemTemp.createTempSync('anas_e2e_');
    await _writePubspec();
    final mainFile = File('${tempDir.path}/lib/main.dart');
    await mainFile.create(recursive: true);
    await mainFile.writeAsString('void main() {}');
    await langDir.create(recursive: true);
    await generatedDir.create(recursive: true);

    final result = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: tempDir.path,
    );
    if (result.exitCode != 0) {
      throw Exception(
        'flutter pub get failed in ${tempDir.path}:\n${result.stderr}',
      );
    }
  }

  Future<void> tearDown() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  }

  Future<void> writeLangFile(
    String locale,
    Map<String, dynamic> content,
  ) async {
    final file = File('${langDir.path}/$locale.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(content),
    );
  }

  Future<Map<String, dynamic>> readLangFile(String locale) async {
    final file = File('${langDir.path}/$locale.json');
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  Future<void> clearLangDir() async {
    for (final entity in langDir.listSync()) {
      await entity.delete(recursive: true);
    }
  }

  Future<ProcessResult> runCli(List<String> args) => Process.run(
        'dart',
        ['run', 'anas_localization:anas', ...args],
        workingDirectory: tempDir.path,
      );

  Future<void> _writePubspec() async {
    final content = '''
name: test_consumer
description: E2E integration test consumer
publish_to: none

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  anas_localization:
    path: $packageRoot

flutter:
  generate: true
  assets:
    - assets/lang/
''';
    await File('${tempDir.path}/pubspec.yaml').writeAsString(content);
  }
}
