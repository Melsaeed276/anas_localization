// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/project_helper.dart';

void main() {
  // `dart test` / `flutter test` sets cwd to the package root.
  final packageRoot = Directory.current.path;

  late ProjectHelper helper;

  setUpAll(() async {
    helper = ProjectHelper(packageRoot: packageRoot);
    await helper.setUp(); // runs flutter pub get once for the whole suite
    print('[e2e] temp project: ${helper.tempDir.path}');
  });

  tearDownAll(() async {
    await helper.tearDown();
  });

  setUp(() async {
    await helper.clearLangDir();
  });

  // ────────────────────────────────────────
  // Group 1: update --gen
  // ────────────────────────────────────────
  group('update --gen', () {
    test('generates Dictionary with simple string getters', () async {
      await helper.writeLangFile('en', {
        'appTitle': 'App',
        'welcome': 'Welcome',
      });
      await helper.writeLangFile('ar', {
        'appTitle': 'تطبيق',
        'welcome': 'أهلاً',
      });

      final result = await helper.runCli(['update', '--gen']);

      expect(
        result.exitCode,
        0,
        reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
      );
      expect(helper.generatedDictionary.existsSync(), isTrue);

      final content = await helper.generatedDictionary.readAsString();
      expect(content, contains('String get appTitle'));
      expect(content, contains('String get welcome'));
      expect(content, contains('class Dictionary extends'));
    });

    test('generates parametric method for placeholder key', () async {
      await helper.writeLangFile('en', {'greeting': 'Hello {name}'});
      await helper.writeLangFile('ar', {'greeting': 'مرحبا {name}'});

      final result = await helper.runCli(['update', '--gen']);

      expect(
        result.exitCode,
        0,
        reason: 'stderr: ${result.stderr}',
      );
      final content = await helper.generatedDictionary.readAsString();
      // Parametric keys become methods, not bare getters
      expect(content, contains('greeting('));
      expect(content, contains('String name'));
    });
  });

  // ────────────────────────────────────────
  // Group 2: add-key
  // ────────────────────────────────────────
  group('add-key', () {
    test('adds key with value to every locale file', () async {
      await helper.writeLangFile('en', {'title': 'Title'});
      await helper.writeLangFile('ar', {'title': 'العنوان'});

      final result = await helper.runCli(['add-key', 'logout', 'Logout']);

      expect(
        result.exitCode,
        0,
        reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
      );

      final en = await helper.readLangFile('en');
      final ar = await helper.readLangFile('ar');
      expect(en['logout'], equals('Logout'));
      expect(ar['logout'], equals('Logout'));
    });

    test('add-key then regenerate exposes new getter in Dictionary', () async {
      await helper.writeLangFile('en', {'title': 'Title'});
      await helper.writeLangFile('ar', {'title': 'العنوان'});

      await helper.runCli(['add-key', 'signIn', 'Sign In']);
      final genResult = await helper.runCli(['update', '--gen']);

      expect(
        genResult.exitCode,
        0,
        reason: 'stderr: ${genResult.stderr}',
      );
      final dict = await helper.generatedDictionary.readAsString();
      expect(dict, contains('String get signIn'));
    });

    test('add-key to existing key prints warning and does not overwrite', () async {
      await helper.writeLangFile('en', {'title': 'Original'});

      final result = await helper.runCli([
        'add-key',
        'title',
        'Should Not Replace',
      ]);

      expect(result.exitCode, 0); // idempotency is still success
      final stdout = result.stdout as String;
      expect(stdout, contains('⚠️'));

      final en = await helper.readLangFile('en');
      expect(en['title'], equals('Original'));
    });
  });

  // ────────────────────────────────────────
  // Group 3: add-locale
  // ────────────────────────────────────────
  group('add-locale', () {
    test('creates new locale file with all keys from template', () async {
      await helper.writeLangFile('en', {
        'title': 'Title',
        'subtitle': 'Subtitle',
        'cta': 'Get started',
      });
      await helper.writeLangFile('ar', {
        'title': 'العنوان',
        'subtitle': 'العنوان الفرعي',
        'cta': 'ابدأ الآن',
      });

      final result = await helper.runCli(['add-locale', 'fr', 'en']);

      expect(
        result.exitCode,
        0,
        reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
      );

      final frFile = File('${helper.langDir.path}/fr.json');
      expect(frFile.existsSync(), isTrue);

      final fr = jsonDecode(await frFile.readAsString()) as Map<String, dynamic>;
      expect(fr.keys, containsAll(['title', 'subtitle', 'cta']));
    });

    test('new locale has all keys with blank values ready for translation', () async {
      await helper.writeLangFile('en', {'hello': 'Hello', 'bye': 'Goodbye'});

      await helper.runCli(['add-locale', 'de', 'en']);

      final de = await helper.readLangFile('de');
      // Keys are copied from template; values are blanked for translators
      expect(de.containsKey('hello'), isTrue);
      expect(de.containsKey('bye'), isTrue);
      expect(de['hello'], equals(''));
      expect(de['bye'], equals(''));
    });
  });

  // ────────────────────────────────────────
  // Group 4: validate
  // ────────────────────────────────────────
  group('validate', () {
    test('returns exit code 0 for consistent locale files', () async {
      await helper.writeLangFile('en', {
        'title': 'Title',
        'description': 'Description',
      });
      await helper.writeLangFile('ar', {
        'title': 'العنوان',
        'description': 'الوصف',
      });

      final result = await helper.runCli(['validate', 'assets/lang']);

      expect(
        result.exitCode,
        0,
        reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
      );
    });

    test('returns non-zero exit code when a locale is missing a key', () async {
      await helper.writeLangFile('en', {
        'title': 'Title',
        'description': 'Description',
        'cta': 'Get started',
      });
      await helper.writeLangFile('ar', {
        'title': 'العنوان',
        // 'description' deliberately missing
        'cta': 'ابدأ',
      });

      final result = await helper.runCli(['validate', 'assets/lang']);

      expect(result.exitCode, isNot(0));
      final combined = '${result.stdout}${result.stderr}';
      expect(combined.toLowerCase(), contains('description'));
    });
  });

  // ────────────────────────────────────────
  // Group 5: stats
  // ────────────────────────────────────────
  group('stats', () {
    test('outputs locale names and key counts', () async {
      await helper.writeLangFile('en', {
        'k1': 'v1',
        'k2': 'v2',
        'k3': 'v3',
      });
      await helper.writeLangFile('ar', {
        'k1': 'ق1',
        'k2': 'ق2',
      });

      final result = await helper.runCli(['stats', 'assets/lang']);

      expect(
        result.exitCode,
        0,
        reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
      );

      final out = result.stdout as String;
      expect(out, contains('en'));
      expect(out, contains('ar'));
      // en has 3 keys, ar has 2 — both counts must appear in output
      expect(out, contains('3'));
      expect(out, contains('2'));
    });
  });
}
