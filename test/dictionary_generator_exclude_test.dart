import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _repoRootPath() {
  final cwd = Directory.current;
  if (File('${cwd.path}/bin/generate_dictionary.dart').existsSync()) return cwd.path;
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
    [scriptPath],
    workingDirectory: workingDirectory.path,
    environment: <String, String>{
      ...Platform.environment,
      ...env,
      'OUTPUT_DART': outputPath,
    },
  );

  if (result.exitCode != 0) {
    throw StateError(
      'generate_dictionary.dart failed (exitCode=${result.exitCode}).\n'
      'STDERR:\n${result.stderr}\nSTDOUT:\n${result.stdout}',
    );
  }

  return File(outputPath).readAsStringSync();
}

Directory _createTempApp({
  required Map<String, dynamic> enData,
  Map<String, dynamic>? trData,
}) {
  final tempAppRoot = Directory.systemTemp.createTempSync(
    'dict_gen_exclude_${DateTime.now().microsecondsSinceEpoch}_',
  );

  File('${tempAppRoot.path}/pubspec.yaml').writeAsStringSync(
    'name: dict_gen_exclude_test\n'
    'version: 0.0.1\n'
    'environment:\n'
    '  sdk: ">=3.3.0 <4.0.0"\n',
  );

  final assetsDir = Directory('${tempAppRoot.path}/assets/lang');
  assetsDir.createSync(recursive: true);

  File('${assetsDir.path}/en.json').writeAsStringSync(jsonEncode(enData));
  if (trData != null) {
    File('${assetsDir.path}/tr.json').writeAsStringSync(jsonEncode(trData));
  }

  return tempAppRoot;
}

void main() {
  group('Dictionary generator exclude keys', () {
    test('GEN_EXCLUDE_KEYS env excludes exact keys from generated output', () async {
      final tempApp = _createTempApp(
        enData: {
          'welcome': 'Welcome',
          'hello': 'Hello',
          'goodbye': 'Goodbye',
        },
        trData: {
          'welcome': 'Hoş geldiniz',
          'hello': 'Merhaba',
          'goodbye': 'Hoşça kal',
        },
      );
      addTearDown(() => tempApp.deleteSync(recursive: true));

      final outFile = File(
        '${Directory.systemTemp.path}/dict_gen_exclude_exact_${DateTime.now().microsecondsSinceEpoch}.dart',
      );

      final output = await _runGeneratorToTempFile(
        workingDirectory: tempApp,
        env: <String, String>{
          'SUPPORTED_LOCALES': 'en,tr',
          'APP_LANG_DIR': 'assets/lang',
          'GEN_EXCLUDE_KEYS': 'hello',
        },
        outputPath: outFile.path,
      );

      // Excluded key should NOT appear as a getter
      expect(output, isNot(contains('String get hello')));
      expect(output, isNot(contains("getString('hello')")));

      // Non-excluded keys should still be present
      expect(output, contains('String get welcome'));
      expect(output, contains('String get goodbye'));
    });

    test('GEN_EXCLUDE_KEYS supports multiple comma-separated patterns', () async {
      final tempApp = _createTempApp(
        enData: {
          'alpha': 'Alpha',
          'beta': 'Beta',
          'gamma': 'Gamma',
          'delta': 'Delta',
        },
      );
      addTearDown(() => tempApp.deleteSync(recursive: true));

      final outFile = File(
        '${Directory.systemTemp.path}/dict_gen_exclude_multi_${DateTime.now().microsecondsSinceEpoch}.dart',
      );

      final output = await _runGeneratorToTempFile(
        workingDirectory: tempApp,
        env: <String, String>{
          'SUPPORTED_LOCALES': 'en',
          'APP_LANG_DIR': 'assets/lang',
          'GEN_EXCLUDE_KEYS': 'alpha,gamma',
        },
        outputPath: outFile.path,
      );

      expect(output, isNot(contains('String get alpha')));
      expect(output, isNot(contains('String get gamma')));
      expect(output, contains('String get beta'));
      expect(output, contains('String get delta'));
    });

    test('wildcard pattern home.* excludes all keys under home namespace', () async {
      final tempApp = _createTempApp(
        enData: {
          'home': {
            'title': 'Home',
            'subtitle': 'Welcome back',
            'description': 'Main page',
          },
          'settings': {
            'title': 'Settings',
          },
        },
      );
      addTearDown(() => tempApp.deleteSync(recursive: true));

      final outFile = File(
        '${Directory.systemTemp.path}/dict_gen_exclude_wildcard_${DateTime.now().microsecondsSinceEpoch}.dart',
      );

      final output = await _runGeneratorToTempFile(
        workingDirectory: tempApp,
        env: <String, String>{
          'SUPPORTED_LOCALES': 'en',
          'APP_LANG_DIR': 'assets/lang',
          'GEN_EXCLUDE_KEYS': 'home.*',
        },
        outputPath: outFile.path,
      );

      // home.* keys should be excluded
      expect(output, isNot(contains("getString('home.title')")));
      expect(output, isNot(contains("getString('home.subtitle')")));
      expect(output, isNot(contains("getString('home.description')")));

      // settings.title should still be present
      expect(output, contains("getString('settings.title')"));
    });

    test('global wildcard * excludes all keys', () async {
      final tempApp = _createTempApp(
        enData: {
          'welcome': 'Welcome',
          'hello': 'Hello',
        },
      );
      addTearDown(() => tempApp.deleteSync(recursive: true));

      final outFile = File(
        '${Directory.systemTemp.path}/dict_gen_exclude_all_${DateTime.now().microsecondsSinceEpoch}.dart',
      );

      final output = await _runGeneratorToTempFile(
        workingDirectory: tempApp,
        env: <String, String>{
          'SUPPORTED_LOCALES': 'en',
          'APP_LANG_DIR': 'assets/lang',
          'GEN_EXCLUDE_KEYS': '*',
        },
        outputPath: outFile.path,
      );

      // No translation getters should be generated
      expect(output, isNot(contains('String get welcome')));
      expect(output, isNot(contains('String get hello')));

      // But the boilerplate should still exist
      expect(output, contains('class Dictionary extends base.Dictionary'));
    });

    test('suffix wildcard *_text excludes matching keys', () async {
      final tempApp = _createTempApp(
        enData: {
          'submit_text': 'Submit',
          'cancel_text': 'Cancel',
          'welcome': 'Welcome',
        },
      );
      addTearDown(() => tempApp.deleteSync(recursive: true));

      final outFile = File(
        '${Directory.systemTemp.path}/dict_gen_exclude_suffix_${DateTime.now().microsecondsSinceEpoch}.dart',
      );

      final output = await _runGeneratorToTempFile(
        workingDirectory: tempApp,
        env: <String, String>{
          'SUPPORTED_LOCALES': 'en',
          'APP_LANG_DIR': 'assets/lang',
          'GEN_EXCLUDE_KEYS': '*_text',
        },
        outputPath: outFile.path,
      );

      expect(output, isNot(contains('String get submitText')));
      expect(output, isNot(contains('String get cancelText')));
      expect(output, contains('String get welcome'));
    });

    test('exact key with dots is excluded correctly', () async {
      final tempApp = _createTempApp(
        enData: {
          'checkout': {
            'title': 'Checkout',
            'button': 'Pay now',
          },
        },
      );
      addTearDown(() => tempApp.deleteSync(recursive: true));

      final outFile = File(
        '${Directory.systemTemp.path}/dict_gen_exclude_dotted_${DateTime.now().microsecondsSinceEpoch}.dart',
      );

      final output = await _runGeneratorToTempFile(
        workingDirectory: tempApp,
        env: <String, String>{
          'SUPPORTED_LOCALES': 'en',
          'APP_LANG_DIR': 'assets/lang',
          'GEN_EXCLUDE_KEYS': 'checkout.button',
        },
        outputPath: outFile.path,
      );

      expect(output, isNot(contains("getString('checkout.button')")));
      expect(output, contains("getString('checkout.title')"));
    });

    test('no exclude patterns generates all keys (backward compatible)', () async {
      final tempApp = _createTempApp(
        enData: {
          'welcome': 'Welcome',
          'hello': 'Hello',
        },
      );
      addTearDown(() => tempApp.deleteSync(recursive: true));

      final outFile = File(
        '${Directory.systemTemp.path}/dict_gen_exclude_none_${DateTime.now().microsecondsSinceEpoch}.dart',
      );

      final output = await _runGeneratorToTempFile(
        workingDirectory: tempApp,
        env: <String, String>{
          'SUPPORTED_LOCALES': 'en',
          'APP_LANG_DIR': 'assets/lang',
        },
        outputPath: outFile.path,
      );

      expect(output, contains('String get welcome'));
      expect(output, contains('String get hello'));
    });

    test('exclude works with parameterized keys', () async {
      final tempApp = _createTempApp(
        enData: {
          'welcome_user': 'Welcome, {name}!',
          'hello': 'Hello',
        },
      );
      addTearDown(() => tempApp.deleteSync(recursive: true));

      final outFile = File(
        '${Directory.systemTemp.path}/dict_gen_exclude_params_${DateTime.now().microsecondsSinceEpoch}.dart',
      );

      final output = await _runGeneratorToTempFile(
        workingDirectory: tempApp,
        env: <String, String>{
          'SUPPORTED_LOCALES': 'en',
          'APP_LANG_DIR': 'assets/lang',
          'GEN_EXCLUDE_KEYS': 'welcome_user',
        },
        outputPath: outFile.path,
      );

      expect(output, isNot(contains("getStringWithParams('welcome_user'")));
      expect(output, contains('String get hello'));
    });

    test('exclude works with plural keys', () async {
      final tempApp = _createTempApp(
        enData: {
          'items_count': {
            'one': '{count} item',
            'other': '{count} items',
          },
          'hello': 'Hello',
        },
      );
      addTearDown(() => tempApp.deleteSync(recursive: true));

      final outFile = File(
        '${Directory.systemTemp.path}/dict_gen_exclude_plural_${DateTime.now().microsecondsSinceEpoch}.dart',
      );

      final output = await _runGeneratorToTempFile(
        workingDirectory: tempApp,
        env: <String, String>{
          'SUPPORTED_LOCALES': 'en',
          'APP_LANG_DIR': 'assets/lang',
          'GEN_EXCLUDE_KEYS': 'items_count',
        },
        outputPath: outFile.path,
      );

      expect(output, isNot(contains('itemsCount(')));
      expect(output, isNot(contains("getPluralData('items_count')")));
      expect(output, contains('String get hello'));
    });
  });

  group('JSON @skip annotation', () {
    test('root-level @skip array excludes listed keys', () async {
      final tempApp = _createTempApp(
        enData: {
          '@skip': ['internal_key', 'debug_info'],
          'welcome': 'Welcome',
          'internal_key': 'Internal',
          'debug_info': 'Debug',
          'hello': 'Hello',
        },
      );
      addTearDown(() => tempApp.deleteSync(recursive: true));

      final outFile = File(
        '${Directory.systemTemp.path}/dict_gen_skip_annotation_${DateTime.now().microsecondsSinceEpoch}.dart',
      );

      final output = await _runGeneratorToTempFile(
        workingDirectory: tempApp,
        env: <String, String>{
          'SUPPORTED_LOCALES': 'en',
          'APP_LANG_DIR': 'assets/lang',
        },
        outputPath: outFile.path,
      );

      // Skipped keys should not appear
      expect(output, isNot(contains('String get internalKey')));
      expect(output, isNot(contains('String get debugInfo')));

      // Non-skipped keys should be present
      expect(output, contains('String get welcome'));
      expect(output, contains('String get hello'));
    });

    test('per-key @keyname annotation with codegen.skip excludes that key', () async {
      final tempApp = _createTempApp(
        enData: {
          'welcome': 'Welcome',
          'hidden_key': 'Hidden',
          '@hidden_key': {
            'codegen': {'skip': true},
          },
          'visible_key': 'Visible',
        },
      );
      addTearDown(() => tempApp.deleteSync(recursive: true));

      final outFile = File(
        '${Directory.systemTemp.path}/dict_gen_skip_perkey_${DateTime.now().microsecondsSinceEpoch}.dart',
      );

      final output = await _runGeneratorToTempFile(
        workingDirectory: tempApp,
        env: <String, String>{
          'SUPPORTED_LOCALES': 'en',
          'APP_LANG_DIR': 'assets/lang',
        },
        outputPath: outFile.path,
      );

      expect(output, isNot(contains('String get hiddenKey')));
      expect(output, contains('String get welcome'));
      expect(output, contains('String get visibleKey'));
    });

    test('@skip and --exclude can be combined', () async {
      final tempApp = _createTempApp(
        enData: {
          '@skip': ['skipped_by_annotation'],
          'welcome': 'Welcome',
          'skipped_by_annotation': 'Skipped via annotation',
          'skipped_by_cli': 'Skipped via CLI',
          'visible': 'Visible',
        },
      );
      addTearDown(() => tempApp.deleteSync(recursive: true));

      final outFile = File(
        '${Directory.systemTemp.path}/dict_gen_skip_combined_${DateTime.now().microsecondsSinceEpoch}.dart',
      );

      final output = await _runGeneratorToTempFile(
        workingDirectory: tempApp,
        env: <String, String>{
          'SUPPORTED_LOCALES': 'en',
          'APP_LANG_DIR': 'assets/lang',
          'GEN_EXCLUDE_KEYS': 'skipped_by_cli',
        },
        outputPath: outFile.path,
      );

      expect(output, isNot(contains('String get skippedByAnnotation')));
      expect(output, isNot(contains('String get skippedByCli')));
      expect(output, contains('String get welcome'));
      expect(output, contains('String get visible'));
    });
  });
}
