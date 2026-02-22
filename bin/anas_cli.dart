#!/usr/bin/env dart
/// Comprehensive CLI tool for managing Anas Localization translations
library;

import 'dart:convert';
import 'dart:io';
import 'package:anas_localization/src/utils/translation_validator.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    _printHelp();
    return;
  }

  final command = arguments[0];
  final args = arguments.skip(1).toList();

  switch (command) {
    case 'validate':
      await _validateCommand(args);
      break;
    case 'add-key':
      await _addKeyCommand(args);
      break;
    case 'remove-key':
      await _removeKeyCommand(args);
      break;
    case 'add-locale':
      await _addLocaleCommand(args);
      break;
    case 'translate':
      await _translateCommand(args);
      break;
    case 'stats':
      await _statsCommand(args);
      break;
    case 'export':
      await _exportCommand(args);
      break;
    case 'import':
      await _importCommand(args);
      break;
    default:
      _err('Unknown command: $command');
      _printHelp();
  }
}

void _out(Object? message) => stdout.writeln(message);

void _err(Object? message) => stderr.writeln(message);

void _printHelp() {
  _out('''
Anas Localization CLI Tool

Commands:
  validate <lang-dir>           Validate translation files for consistency
  add-key <key> <value>         Add a new translation key to all languages
  remove-key <key>              Remove a translation key from all languages
  add-locale <locale>           Add support for a new locale
  translate <key> <locale> <text>  Add/update translation for specific locale
  stats <lang-dir>              Show translation statistics
  export <lang-dir> <format>    Export translations (csv, xlsx, json)
  import <file> <lang-dir>      Import translations from file

Examples:
  dart run anas_localization:cli validate assets/lang
  dart run anas_localization:cli add-key "new_feature" "New Feature"
  dart run anas_localization:cli add-locale fr
  dart run anas_localization:cli stats assets/lang
''');
}

Future<void> _validateCommand(List<String> args) async {
  if (args.isEmpty) {
    _err('Usage: validate <lang-dir>');
    return;
  }

  final langDir = args[0];
  _out('🔍 Validating translations in $langDir...');

  final result = await TranslationValidator.validateTranslations(langDir);

  if (result.isValid) {
    _out('✅ All translations are valid!');
  } else {
    _err('❌ Validation failed:');
    for (final error in result.errors) {
      _err('  • $error');
    }
  }

  if (result.hasWarnings) {
    _out('⚠️  Warnings:');
    for (final warning in result.warnings) {
      _out('  • $warning');
    }
  }
}

Future<void> _addKeyCommand(List<String> args) async {
  if (args.length < 2) {
    _err('Usage: add-key <key> <value>');
    return;
  }

  final key = args[0];
  final value = args[1];
  final langDir = args.length > 2 ? args[2] : 'assets/lang';

  _out('➕ Adding key "$key" to all translation files...');

  final dir = Directory(langDir);
  if (!dir.existsSync()) {
    _err('❌ Language directory not found: $langDir');
    return;
  }

  final jsonFiles = dir.listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'));

  for (final file in jsonFiles) {
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (!data.containsKey(key)) {
        data[key] = value;
        const encoder = JsonEncoder.withIndent('  ');
        await file.writeAsString(encoder.convert(data));
        _out('  ✅ Added to ${file.uri.pathSegments.last}');
      } else {
        _out('  ⚠️  Key already exists in ${file.uri.pathSegments.last}');
      }
    } catch (e) {
      _err('  ❌ Failed to update ${file.uri.pathSegments.last}: $e');
    }
  }
}

Future<void> _statsCommand(List<String> args) async {
  if (args.isEmpty) {
    _err('Usage: stats <lang-dir>');
    return;
  }

  final langDir = args[0];
  final dir = Directory(langDir);

  if (!dir.existsSync()) {
    _err('❌ Language directory not found: $langDir');
    return;
  }

  _out('📊 Translation Statistics for $langDir\n');

  final jsonFiles = dir.listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'));

  final stats = <String, Map<String, dynamic>>{};

  for (final file in jsonFiles) {
    final locale = file.uri.pathSegments.last.replaceAll('.json', '');
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final keyCount = _countKeys(data);
      final stringCount = _countStrings(data);
      final pluralCount = _countPluralKeys(data);

      stats[locale] = {
        'keys': keyCount,
        'strings': stringCount,
        'plurals': pluralCount,
        'fileSize': await file.length(),
      };
    } catch (e) {
      _err('❌ Failed to analyze $locale.json: $e');
    }
  }

  // Print statistics table
  _out('Locale\tKeys\tStrings\tPlurals\tSize');
  _out('─' * 40);
  for (final entry in stats.entries) {
    final data = entry.value;
    final row = [
      entry.key,
      '${data['keys']}',
      '${data['strings']}',
      '${data['plurals']}',
      _formatFileSize(data['fileSize'] as int),
    ].join('\t');
    _out(row);
  }
}

int _countKeys(Map<String, dynamic> map) {
  int count = 0;
  for (final value in map.values) {
    if (value is Map<String, dynamic>) {
      count += _countKeys(value);
    } else {
      count++;
    }
  }
  return count;
}

int _countStrings(Map<String, dynamic> map) {
  int count = 0;
  for (final value in map.values) {
    if (value is String) {
      count++;
    } else if (value is Map<String, dynamic>) {
      count += _countStrings(value);
    }
  }
  return count;
}

int _countPluralKeys(Map<String, dynamic> map) {
  int count = 0;
  for (final value in map.values) {
    if (value is Map<String, dynamic>) {
      final hasPlural = value.keys.any((k) => ['zero', 'one', 'two', 'few', 'many', 'other'].contains(k));
      if (hasPlural) count++;
    }
  }
  return count;
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}

Future<void> _addLocaleCommand(List<String> args) async {
  // Implementation for adding new locale support
  _out('🌍 Adding new locale support...');
  // This would create new JSON files and update configuration
}

Future<void> _translateCommand(List<String> args) async {
  // Implementation for adding/updating specific translations
  _out('🔄 Updating translation...');
}

Future<void> _removeKeyCommand(List<String> args) async {
  // Implementation for removing translation keys
  _out('🗑️  Removing translation key...');
}

Future<void> _exportCommand(List<String> args) async {
  // Implementation for exporting translations to various formats
  _out('📤 Exporting translations...');
}

Future<void> _importCommand(List<String> args) async {
  // Implementation for importing translations from files
  _out('📥 Importing translations...');
}
