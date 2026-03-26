import 'dart:io';

import 'package:anas_localization/localization.dart';
import 'package:flutter_test/flutter_test.dart';

String _repoRootPath() {
  final cwd = Directory.current;
  // In CI / dev runs, flutter_test usually executes with repo root as cwd.
  if (File('${cwd.path}/bin/generate_dictionary.dart').existsSync()) return cwd.path;
  // Fallback: walk upwards a bit.
  var dir = cwd;
  for (var i = 0; i < 5; i++) {
    final candidate = '${dir.path}/bin/generate_dictionary.dart';
    if (File(candidate).existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return cwd.path;
}

Future<String> _runGeneratorToTempFile({
  required Directory workingDirectory,
  required Map<String, String> env,
  required String outputPath,
}) async {
  final repoRoot = _repoRootPath();
  final scriptPath = '$repoRoot/bin/generate_dictionary.dart';

  final result = await Process.run(
    'dart',
    [
      'run',
      scriptPath,
    ],
    workingDirectory: workingDirectory.path,
    environment: <String, String>{
      ...Platform.environment,
      ...env,
      'OUTPUT_DART': outputPath,
    },
  );

  if (result.exitCode != 0) {
    throw StateError(
      'generate_dictionary.dart failed (exitCode=${result.exitCode}).\nSTDERR:\n${result.stderr}',
    );
  }

  return File(outputPath).readAsStringSync();
}

void main() {
  setUp(() {
    // Ensure singleton state is not shared across tests.
    LocalizationService().clear();
    LocalizationService.clearPreviewDictionaries();
  });

  group('Dictionary generator override precedence + typed placeholder semantics', () {
    test('package-root codegen uses example overrides and generates optional params', () async {
      final repoRoot = Directory(_repoRootPath());
      final outFile = File(
        '${Directory.systemTemp.path}/dict_gen_out_pkg_${DateTime.now().microsecondsSinceEpoch}.dart',
      );
      final output = await _runGeneratorToTempFile(
        workingDirectory: repoRoot,
        env: <String, String>{
          'SUPPORTED_LOCALES': 'en',
        },
        outputPath: outFile.path,
      );

      // US1: ensure example overrides are used (example assets contain `basic_demo`).
      expect(output, contains('String get basicDemo'));

      // US1 + FR-002: `money_args` uses `{name?}` so typed getter should be nullable and omit null entries.
      expect(output, contains('String moneyArgs({String? name'));
      expect(output, contains("if (name != null) 'name': name,"));
      expect(output, contains("getStringWithParams('money_args'"));
    });

    test('typed getters emit correct signatures for dotted keys + {param?}/{param!}', () async {
      final tempAppRoot = Directory.systemTemp.createTempSync(
        'dict_gen_temp_app_${DateTime.now().microsecondsSinceEpoch}_',
      );
      addTearDown(() {
        tempAppRoot.deleteSync(recursive: true);
      });

      // Make the generator treat this as a non-package app root.
      File('${tempAppRoot.path}/pubspec.yaml').writeAsStringSync(
        'name: dict_gen_temp_app\nversion: 0.0.1\nenvironment:\n  sdk: ">=3.3.0 <4.0.0"\n',
      );

      final assetsDir = Directory('${tempAppRoot.path}/assets/lang');
      assetsDir.createSync(recursive: true);

      // Provide nested keys so the generator creates dotted-path getters.
      File('${assetsDir.path}/en.json').writeAsStringSync(
        const <String, dynamic>{
          'home': <String, dynamic>{
            'welcome_optional': 'Hello, {name?}!',
            'welcome_required': 'Hello, {name!}!',
          },
        }.toString(),
      );

      // The generator expects valid JSON, so overwrite with proper JSON encoding.
      final jsonContent = '{"home":{"welcome_optional":"Hello, {name?}!","welcome_required":"Hello, {name!}!"}}';
      File('${assetsDir.path}/en.json').writeAsStringSync(jsonContent);

      final outFile = File(
        '${Directory.systemTemp.path}/dict_gen_out_dotted_${DateTime.now().microsecondsSinceEpoch}.dart',
      );

      final output = await _runGeneratorToTempFile(
        workingDirectory: tempAppRoot,
        env: <String, String>{
          'SUPPORTED_LOCALES': 'en',
          // Use the synthetic app's translations as overrides.
          'APP_LANG_DIR': 'assets/lang',
        },
        outputPath: outFile.path,
      );

      // Dotted key flattening: `home.welcome_optional` -> `homeWelcomeOptional`.
      expect(output, contains('String homeWelcomeOptional({String? name})'));
      expect(output, contains("if (name != null) 'name': name,"));
      expect(output, contains("getStringWithParams('home.welcome_optional'"));

      // Required marker: `home.welcome_required` -> `homeWelcomeRequired`.
      expect(output, contains('String homeWelcomeRequired({required String name})'));
      expect(output, contains("'name': name,"));
      expect(output, contains("getStringWithParams('home.welcome_required'"));
    });
  });
}
