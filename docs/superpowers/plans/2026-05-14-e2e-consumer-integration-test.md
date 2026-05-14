# E2E Consumer Integration Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create an end-to-end test suite that scaffolds a real Flutter consumer project in a temp directory, then exercises the CLI and runtime across: dictionary generation, `add-key`, `add-locale`, `validate`, and `stats`.

**Architecture:** A shared `ProjectHelper` class (in `test/e2e/helpers/project_helper.dart`) scaffolds a temp Flutter project with an absolute path dependency to this package and runs `flutter pub get` once per suite in `setUpAll`. Each test resets only `assets/lang/` in `setUp` so the slow pub-get step never repeats. All temp dirs live under `Directory.systemTemp` — nothing needs gitignoring.

**Tech Stack:** `package:flutter_test` (provides `package:test`), `dart:io`, `dart:convert`, Flutter 3.41+, `dart run anas_localization:anas` CLI.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `test/e2e/helpers/project_helper.dart` | Temp-project scaffolding + `runCli()` wrapper |
| Create | `test/e2e/consumer_integration_test.dart` | Full E2E test suite (6 test cases) |

---

## Task 1: Create `ProjectHelper`

**Files:**
- Create: `test/e2e/helpers/project_helper.dart`

The helper owns:
- `setUp()` — create dir tree, write pubspec, run `flutter pub get` (once per suite)
- `tearDown()` — delete temp dir
- `writeLangFile(locale, map)` / `readLangFile(locale)` / `clearLangDir()`
- `runCli(args)` — `dart run anas_localization:anas <args>` from tempDir

- [ ] **Step 1: Write the helper file**

```dart
// test/e2e/helpers/project_helper.dart
import 'dart:convert';
import 'dart:io';

class ProjectHelper {
  late final Directory tempDir;
  final String packageRoot;

  ProjectHelper({required this.packageRoot});

  Directory get langDir => Directory('${tempDir.path}/assets/lang');
  Directory get generatedDir => Directory('${tempDir.path}/lib/generated');
  File get generatedDictionary =>
      File('${tempDir.path}/lib/generated/dictionary.dart');

  Future<void> setUp() async {
    tempDir = Directory.systemTemp.createTempSync('anas_e2e_');
    await _writePubspec();
    await File('${tempDir.path}/lib/main.dart').create(recursive: true);
    await File('${tempDir.path}/lib/main.dart').writeAsString('void main() {}');
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
```

- [ ] **Step 2: Verify the file compiles (no test yet)**

```bash
cd /Users/cay/Documents/work/projects/anas_localization
dart analyze test/e2e/helpers/project_helper.dart
```

Expected: 0 issues.

---

## Task 2: Test — Dictionary generation (`update --gen`)

**Files:**
- Create: `test/e2e/consumer_integration_test.dart`

This task creates the test file with the first test group. Later tasks append groups.

- [ ] **Step 1: Write the failing test**

```dart
// test/e2e/consumer_integration_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/project_helper.dart';

void main() {
  // Locate the package root relative to this test file.
  // `dart test` sets cwd to the package root.
  final packageRoot = Directory.current.path;

  late ProjectHelper helper;

  setUpAll(() async {
    helper = ProjectHelper(packageRoot: packageRoot);
    await helper.setUp(); // runs flutter pub get once
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
    test('generates Dictionary with simple string getter', () async {
      await helper.writeLangFile('en', {
        'appTitle': 'App',
        'welcome': 'Welcome',
      });
      await helper.writeLangFile('ar', {
        'appTitle': 'تطبيق',
        'welcome': 'أهلاً',
      });

      final result = await helper.runCli(['update', '--gen']);

      expect(result.exitCode, 0,
          reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}');
      expect(helper.generatedDictionary.existsSync(), isTrue);

      final content = await helper.generatedDictionary.readAsString();
      expect(content, contains('String get appTitle'));
      expect(content, contains('String get welcome'));
      expect(content, contains('class Dictionary extends'));
    });

    test('generates parametric getter for placeholder key', () async {
      await helper.writeLangFile('en', {
        'greeting': 'Hello {name}',
      });
      await helper.writeLangFile('ar', {
        'greeting': 'مرحبا {name}',
      });

      final result = await helper.runCli(['update', '--gen']);

      expect(result.exitCode, 0,
          reason: 'stderr: ${result.stderr}');
      final content = await helper.generatedDictionary.readAsString();
      // Parametric keys become methods, not bare getters
      expect(content, contains('greeting('));
      expect(content, contains('String name'));
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails (helper not yet implemented)**

```bash
cd /Users/cay/Documents/work/projects/anas_localization
flutter test test/e2e/consumer_integration_test.dart --timeout 180s
```

Expected: compilation error because helper file doesn't exist yet (or test fails if helper partially exists). This is the TDD red step.

- [ ] **Step 3: Confirm Task 1 helper is in place, then run again**

```bash
flutter test test/e2e/consumer_integration_test.dart --timeout 180s
```

Expected: both tests PASS (may take 60–90 s on first run due to `flutter pub get`).

- [ ] **Step 4: Commit**

```bash
git add test/e2e/helpers/project_helper.dart test/e2e/consumer_integration_test.dart
git commit -m "test(e2e): scaffold consumer project helper and dictionary generation tests"
```

---

## Task 3: Test — `add-key` command

**Files:**
- Modify: `test/e2e/consumer_integration_test.dart` (append a new group)

- [ ] **Step 1: Write the failing tests**

Append inside `main()` after the `update --gen` group:

```dart
  // ────────────────────────────────────────
  // Group 2: add-key
  // ────────────────────────────────────────
  group('add-key', () {
    test('adds key with value to every locale file', () async {
      await helper.writeLangFile('en', {'title': 'Title'});
      await helper.writeLangFile('ar', {'title': 'العنوان'});

      final result = await helper.runCli([
        'add-key',
        'logout',
        'Logout',
      ]);

      expect(result.exitCode, 0,
          reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}');

      final en = await helper.readLangFile('en');
      final ar = await helper.readLangFile('ar');

      expect(en['logout'], equals('Logout'));
      expect(ar['logout'], equals('Logout'));
    });

    test('add-key then regenerate exposes new getter', () async {
      await helper.writeLangFile('en', {'title': 'Title'});
      await helper.writeLangFile('ar', {'title': 'العنوان'});

      await helper.runCli(['add-key', 'signIn', 'Sign In']);
      final genResult = await helper.runCli(['update', '--gen']);

      expect(genResult.exitCode, 0,
          reason: 'stderr: ${genResult.stderr}');
      final dict = await helper.generatedDictionary.readAsString();
      expect(dict, contains('String get signIn'));
    });

    test('add-key to existing key prints warning, does not overwrite', () async {
      await helper.writeLangFile('en', {'title': 'Original'});

      final result = await helper.runCli([
        'add-key',
        'title',
        'Should Not Replace',
      ]);

      expect(result.exitCode, 0); // non-overwrite is still success
      final stdout = result.stdout as String;
      expect(stdout, contains('⚠️'));

      final en = await helper.readLangFile('en');
      expect(en['title'], equals('Original')); // unchanged
    });
  });
```

- [ ] **Step 2: Run to verify new tests fail**

```bash
flutter test test/e2e/consumer_integration_test.dart --timeout 180s
```

Expected: the new 3 tests FAIL (group doesn't exist yet in file).

Wait — you already appended the code above, so they will run. Expected: PASS on all 3.

- [ ] **Step 3: Run and confirm all tests pass**

```bash
flutter test test/e2e/consumer_integration_test.dart --timeout 180s
```

Expected: 5 tests pass (2 from group 1, 3 from group 2).

- [ ] **Step 4: Commit**

```bash
git add test/e2e/consumer_integration_test.dart
git commit -m "test(e2e): add-key CLI integration tests"
```

---

## Task 4: Test — `add-locale` command

**Files:**
- Modify: `test/e2e/consumer_integration_test.dart` (append group 3)

- [ ] **Step 1: Write the failing tests**

Append inside `main()`:

```dart
  // ────────────────────────────────────────
  // Group 3: add-locale
  // ────────────────────────────────────────
  group('add-locale', () {
    test('creates new locale file from template locale', () async {
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

      final result = await helper.runCli([
        'add-locale',
        'fr',
        'en', // template
      ]);

      expect(result.exitCode, 0,
          reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}');

      final frFile = File('${helper.langDir.path}/fr.json');
      expect(frFile.existsSync(), isTrue);

      final fr = jsonDecode(await frFile.readAsString()) as Map<String, dynamic>;
      expect(fr.keys, containsAll(['title', 'subtitle', 'cta']));
    });

    test('new locale values copied from template', () async {
      await helper.writeLangFile('en', {'hello': 'Hello', 'bye': 'Goodbye'});

      await helper.runCli(['add-locale', 'de', 'en']);

      final de = await helper.readLangFile('de');
      // Values are copied from template
      expect(de['hello'], equals('Hello'));
      expect(de['bye'], equals('Goodbye'));
    });
  });
```

Add the missing import at the top of the file (already has `dart:io`; `dart:convert` is needed for `jsonDecode`):

```dart
import 'dart:convert';
```

- [ ] **Step 2: Run and verify**

```bash
flutter test test/e2e/consumer_integration_test.dart --timeout 180s
```

Expected: 7 tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/e2e/consumer_integration_test.dart
git commit -m "test(e2e): add-locale CLI integration tests"
```

---

## Task 5: Test — `validate` command

**Files:**
- Modify: `test/e2e/consumer_integration_test.dart` (append group 4)

- [ ] **Step 1: Write the failing tests**

Append inside `main()`:

```dart
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

      expect(result.exitCode, 0,
          reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}');
    });

    test('returns non-zero exit code when a locale is missing a key', () async {
      await helper.writeLangFile('en', {
        'title': 'Title',
        'description': 'Description',
        'cta': 'Get started',
      });
      await helper.writeLangFile('ar', {
        'title': 'العنوان',
        // 'description' missing
        'cta': 'ابدأ',
      });

      final result = await helper.runCli(['validate', 'assets/lang']);

      expect(result.exitCode, isNot(0));
      final combined = '${result.stdout}${result.stderr}';
      expect(combined.toLowerCase(), contains('description'));
    });
  });
```

- [ ] **Step 2: Run and verify**

```bash
flutter test test/e2e/consumer_integration_test.dart --timeout 180s
```

Expected: 9 tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/e2e/consumer_integration_test.dart
git commit -m "test(e2e): validate CLI integration tests"
```

---

## Task 6: Test — `stats` command

**Files:**
- Modify: `test/e2e/consumer_integration_test.dart` (append group 5)

- [ ] **Step 1: Write the failing tests**

Append inside `main()`:

```dart
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

      expect(result.exitCode, 0,
          reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}');

      final out = result.stdout as String;
      expect(out, contains('en'));
      expect(out, contains('ar'));
      // en has 3 keys, ar has 2 keys — both counts visible
      expect(out, contains('3'));
      expect(out, contains('2'));
    });
  });
```

- [ ] **Step 2: Run full suite and verify everything passes**

```bash
flutter test test/e2e/consumer_integration_test.dart --timeout 180s
```

Expected: 10 tests pass, 0 failures.

- [ ] **Step 3: Run dart analyze to ensure zero warnings**

```bash
dart analyze test/e2e/
```

Expected: No issues found!

- [ ] **Step 4: Final commit**

```bash
git add test/e2e/consumer_integration_test.dart
git commit -m "test(e2e): stats CLI integration test — completes e2e consumer test suite"
```

---

## Running the Suite

```bash
# Run the full e2e suite (allow extra time for flutter pub get on first run)
flutter test test/e2e/ --timeout 180s

# Run a specific group only
flutter test test/e2e/consumer_integration_test.dart --name "add-key" --timeout 180s

# Run with verbose output to see CLI stdout/stderr
flutter test test/e2e/ --timeout 180s --reporter expanded
```

> **Note:** First run takes ~60–90 s for `flutter pub get` in the temp project. Subsequent runs reuse the pub cache and complete in ~10–20 s.

---

## Self-Review Checklist

- [x] **Dictionary generation** — covers simple getter and parametric getter
- [x] **add-key** — covers adding to all locales, idempotency warning, and regeneration
- [x] **add-locale** — covers locale creation and value copying from template
- [x] **validate** — covers clean pass and missing-key failure with exit code check
- [x] **stats** — covers locale names and key count output
- [x] **No placeholders** — all steps include actual code and exact commands
- [x] **Temp dirs** — no gitignore changes needed; all under `Directory.systemTemp`
- [x] **`flutter pub get` runs once** — `setUpAll` pattern avoids repeat cost
