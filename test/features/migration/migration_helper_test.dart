import 'dart:convert';
import 'dart:io';

import 'package:anas_localization/src/utils/migration_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MigrationHelper', () {
    Directory? tempDir;

    Future<void> writeJsonFile(String path, Map<String, dynamic> data) async {
      final file = File(path);
      await file.create(recursive: true);
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    }

    Future<void> writeFile(String path, String content) async {
      final file = File(path);
      await file.create(recursive: true);
      await file.writeAsString(content);
    }

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('migration_helper_');
    });

    tearDown(() {
      tempDir?.deleteSync(recursive: true);
    });

    test('rewrites easy_localization reads to generated dictionary accessors', () async {
      final root = tempDir!.path;
      await writeJsonFile('$root/assets/lang/en.json', {
        'home': {'title': 'Home'},
        'greeting': 'Hello {name}',
        'cart': {
          'items': {
            'one': '{count} item',
            'other': '{count} items',
          },
        },
      });

      await writeFile('$root/lib/page.dart', '''
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class Page extends StatelessWidget {
  const Page({super.key});

  @override
  Widget build(BuildContext context) {
    final count = 2;
    final userName = 'Anas';
    return Column(
      children: [
        Text('home.title'.tr()),
        Text('greeting'.tr(namedArgs: {'name': userName})),
        Text('cart.items'.plural(count)),
      ],
    );
  }
}
''');

      final result = await MigrationHelper.migrate(
        MigrationOptions(
          from: 'easy_localization',
          langDir: '$root/assets/lang',
          targets: ['$root/lib/page.dart'],
        ),
      );

      expect(result.changedFiles, equals(1));
      final content = result.fileResults.single.updatedContent;
      expect(content, contains('generated/dictionary.dart'));
      expect(content, contains('Text(getDictionary().homeTitle)'));
      expect(content, contains('Text(getDictionary().greeting(name: userName))'));
      expect(content, contains('Text(getDictionary().cartItems(count: count))'));
    });

    test('falls back to getDictionary().getString when typed accessor naming is ambiguous', () async {
      final root = tempDir!.path;
      await writeJsonFile('$root/assets/lang/en.json', {
        'foo-bar': 'Hyphen',
        'foo_bar': 'Underscore',
      });

      await writeFile('$root/lib/page.dart', '''
import 'package:easy_localization/easy_localization.dart';

String buildTitle() {
  return 'foo-bar'.tr();
}
''');

      final result = await MigrationHelper.migrate(
        MigrationOptions(
          from: 'easy_localization',
          langDir: '$root/assets/lang',
          targets: ['$root/lib/page.dart'],
        ),
      );

      expect(result.fileResults.single.updatedContent, contains("return getDictionary().getString('foo-bar');"));
    });

    test('rewrites locale switching to AnasLocalization.of(context).setLocale with async', () async {
      final root = tempDir!.path;
      await writeJsonFile('$root/assets/lang/en.json', {
        'home': {'title': 'Home'},
      });

      await writeFile('$root/lib/page.dart', '''
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class Page extends StatelessWidget {
  const Page({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.setLocale(const Locale('ar'));
      },
      child: const SizedBox.shrink(),
    );
  }
}
''');

      final result = await MigrationHelper.migrate(
        MigrationOptions(
          from: 'easy_localization',
          langDir: '$root/assets/lang',
          targets: ['$root/lib/page.dart'],
        ),
      );

      final updated = result.fileResults.single.updatedContent;
      expect(updated, contains('onPressed: () async {'));
      expect(updated, contains("await AnasLocalization.of(context).setLocale(const Locale('ar'));"));
    });

    test('rewrites gen_l10n properties and methods to generated dictionary accessors', () async {
      final root = tempDir!.path;
      await writeJsonFile('$root/assets/lang/en.json', {
        'welcome_title': 'Welcome',
        'greeting': 'Hello {name}',
      });

      await writeFile('$root/lib/page.dart', '''
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Page extends StatelessWidget {
  const Page({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = 'Anas';
    return Column(
      children: [
        Text(AppLocalizations.of(context)!.welcomeTitle),
        Text(AppLocalizations.of(context)!.greeting(userName)),
      ],
    );
  }
}
''');

      final result = await MigrationHelper.migrate(
        MigrationOptions(
          from: 'gen_l10n',
          langDir: '$root/assets/lang',
          targets: ['$root/lib/page.dart'],
        ),
      );

      final updated = result.fileResults.single.updatedContent;
      expect(updated, contains('generated/dictionary.dart'));
      expect(updated, contains('Text(getDictionary().welcomeTitle)'));
      expect(updated, contains('Text(getDictionary().greeting(name: userName))'));
    });

    test('reports unsupported easy_localization helpers for manual follow-up', () async {
      final root = tempDir!.path;
      await writeJsonFile('$root/assets/lang/en.json', {
        'home': {'title': 'Home'},
      });

      await writeFile('$root/lib/page.dart', '''
import 'package:easy_localization/easy_localization.dart';

Future<void> reset(BuildContext context) async {
  await context.resetLocale();
}
''');

      final result = await MigrationHelper.migrate(
        MigrationOptions(
          from: 'easy_localization',
          langDir: '$root/assets/lang',
          targets: ['$root/lib/page.dart'],
        ),
      );

      expect(result.changedFiles, equals(0));
      expect(result.globalWarnings.single, contains('Manual follow-up required for resetLocale().'));
    });

    test('defaults to lib only and rewrites tests only when explicitly targeted', () async {
      final root = tempDir!.path;
      await writeJsonFile('$root/assets/lang/en.json', {
        'home': {'title': 'Home'},
      });

      await writeFile('$root/lib/page.dart', '''
import 'package:easy_localization/easy_localization.dart';

String title() => 'home.title'.tr();
''');
      await writeFile('$root/test/page_test.dart', '''
import 'package:easy_localization/easy_localization.dart';

String title() => 'home.title'.tr();
''');

      final defaultResult = await MigrationHelper.migrate(
        MigrationOptions(
          from: 'easy_localization',
          langDir: '$root/assets/lang',
          apply: true,
          workingDirectory: root,
        ),
      );

      expect(defaultResult.changedFiles, equals(1));
      expect(await File('$root/lib/page.dart').readAsString(), contains('getDictionary().homeTitle'));
      expect(await File('$root/test/page_test.dart').readAsString(), contains("'home.title'.tr()"));

      final testResult = await MigrationHelper.migrate(
        MigrationOptions(
          from: 'easy_localization',
          langDir: '$root/assets/lang',
          testTargets: ['$root/test'],
          apply: true,
          workingDirectory: root,
        ),
      );

      expect(testResult.changedFiles, equals(1));
      expect(await File('$root/lib/page.dart').readAsString(), contains('getDictionary().homeTitle'));
      expect(await File('$root/test/page_test.dart').readAsString(), contains('getDictionary().homeTitle'));
    });
  });
}
