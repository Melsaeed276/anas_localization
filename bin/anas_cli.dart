#!/usr/bin/env dart

/// Comprehensive CLI tool for managing Anas Localization translations
library;

import 'dart:convert';
import 'dart:io';
import 'package:anas_localization/src/utils/translation_validator.dart';
import 'package:anas_localization/src/utils/arb_interop.dart';

const String _defaultLangDir = 'assets/lang';

Future<void> main(List<String> arguments) async {
  final success = await _run(arguments);
  if (!success) {
    exitCode = 1;
  }
}

Future<bool> _run(List<String> arguments) async {
  if (arguments.isEmpty) {
    _printHelp();
    return true;
  }

  final command = arguments[0];
  final args = arguments.skip(1).toList();

  switch (command) {
    case 'validate':
      return _validateCommand(args);
    case 'add-key':
      return _addKeyCommand(args);
    case 'remove-key':
      return _removeKeyCommand(args);
    case 'add-locale':
      return _addLocaleCommand(args);
    case 'translate':
      return _translateCommand(args);
    case 'stats':
      return _statsCommand(args);
    case 'export':
      return _exportCommand(args);
    case 'import':
      return _importCommand(args);
    case 'help':
      _printHelp();
      return true;
    default:
      _err('Unknown command: $command');
      _printHelp();
      return false;
  }
}

void _out(Object? message) => stdout.writeln(message);

void _err(Object? message) => stderr.writeln(message);

void _printHelp() {
  _out('''
Anas Localization CLI Tool

Commands:
  validate <lang-dir>           Validate translation files for consistency
  add-key <key> <value> [dir]   Add a new translation key to all languages
  remove-key <key> [dir]        Remove a translation key from all languages
  add-locale <locale> [tpl] [dir] Add support for a new locale from template locale
  translate <key> <locale> <text> [dir]  Add/update translation for specific locale
  stats <lang-dir>              Show translation statistics
  export <lang-dir> <format> [out]  Export translations (csv, json, arb)
  import <file|dir> <lang-dir>      Import translations from json/csv/arb or l10n.yaml
  help                          Show this help

Examples:
  dart run anas_localization:anas_cli validate assets/lang
  dart run anas_localization:anas_cli add-key "home.title" "Home"
  dart run anas_localization:anas_cli add-locale fr en assets/lang
  dart run anas_localization:anas_cli stats assets/lang
''');
}

Future<bool> _validateCommand(List<String> args) async {
  if (args.isEmpty) {
    _err('Usage: validate <lang-dir>');
    return false;
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

  return result.isValid;
}

Future<bool> _addKeyCommand(List<String> args) async {
  if (args.length < 2) {
    _err('Usage: add-key <key> <value> [lang-dir]');
    return false;
  }

  final key = args[0];
  final value = args[1];
  final langDir = args.length > 2 ? args[2] : _defaultLangDir;

  _out('➕ Adding key "$key" to all translation files...');

  final dir = Directory(langDir);
  if (!dir.existsSync()) {
    _err('❌ Language directory not found: $langDir');
    return false;
  }

  var success = true;
  final jsonFiles = _jsonFilesInDir(dir).toList();

  for (final file in jsonFiles) {
    try {
      final data = await _readJsonFile(file);

      if (!_hasPath(data, key)) {
        _setValueByPath(data, key, value, overwrite: true);
        await _writeJsonFile(file, data);
        _out('  ✅ Added to ${file.uri.pathSegments.last}');
      } else {
        _out('  ⚠️  Key already exists in ${file.uri.pathSegments.last} at "$key"');
      }
    } catch (e) {
      success = false;
      _err('  ❌ Failed to update ${file.uri.pathSegments.last}: $e');
    }
  }

  return success;
}

Future<bool> _statsCommand(List<String> args) async {
  if (args.isEmpty) {
    _err('Usage: stats <lang-dir>');
    return false;
  }

  final langDir = args[0];
  final dir = Directory(langDir);

  if (!dir.existsSync()) {
    _err('❌ Language directory not found: $langDir');
    return false;
  }

  _out('📊 Translation Statistics for $langDir\n');

  var success = true;
  final jsonFiles = _jsonFilesInDir(dir);

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
      success = false;
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

  return success;
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

Future<bool> _addLocaleCommand(List<String> args) async {
  if (args.isEmpty) {
    _err('Usage: add-locale <locale> [template-locale] [lang-dir]');
    return false;
  }

  final locale = args[0];
  final templateLocale = args.length > 1 ? args[1] : 'en';
  final langDir = args.length > 2 ? args[2] : _defaultLangDir;
  final dir = Directory(langDir);

  if (!dir.existsSync()) {
    _err('❌ Language directory not found: $langDir');
    return false;
  }

  final targetFile = File('$langDir/$locale.json');
  if (targetFile.existsSync()) {
    _err('❌ Locale file already exists: ${targetFile.path}');
    return false;
  }

  File? templateFile = File('$langDir/$templateLocale.json');
  if (!templateFile.existsSync()) {
    final candidates = _jsonFilesInDir(dir).toList();
    if (candidates.isEmpty) {
      _err('❌ No template files found in $langDir');
      return false;
    }
    templateFile = candidates.first;
  }

  try {
    final templateMap = await _readJsonFile(templateFile);
    final localeMap = _cloneStructureForNewLocale(templateMap);
    await _writeJsonFile(targetFile, localeMap);
    _out('✅ Added locale file: ${targetFile.path}');
    return true;
  } catch (error) {
    _err('❌ Failed to add locale "$locale": $error');
    return false;
  }
}

Future<bool> _translateCommand(List<String> args) async {
  if (args.length < 3) {
    _err('Usage: translate <key> <locale> <text> [lang-dir]');
    return false;
  }

  final key = args[0];
  final locale = args[1];
  final text = args[2];
  final langDir = args.length > 3 ? args[3] : _defaultLangDir;
  final file = File('$langDir/$locale.json');

  if (!file.existsSync()) {
    _err('❌ Locale file not found: ${file.path}');
    return false;
  }

  try {
    final data = await _readJsonFile(file);
    _setValueByPath(data, key, text, overwrite: true);
    await _writeJsonFile(file, data);
    _out('✅ Updated "$key" in ${file.uri.pathSegments.last}');
    return true;
  } catch (error) {
    _err('❌ Failed to update translation: $error');
    return false;
  }
}

Future<bool> _removeKeyCommand(List<String> args) async {
  if (args.isEmpty) {
    _err('Usage: remove-key <key> [lang-dir]');
    return false;
  }

  final key = args[0];
  final langDir = args.length > 1 ? args[1] : _defaultLangDir;
  final dir = Directory(langDir);
  if (!dir.existsSync()) {
    _err('❌ Language directory not found: $langDir');
    return false;
  }

  var success = true;
  for (final file in _jsonFilesInDir(dir)) {
    try {
      final data = await _readJsonFile(file);
      final removed = _removeValueByPath(data, key);
      if (removed) {
        await _writeJsonFile(file, data);
        _out('  ✅ Removed from ${file.uri.pathSegments.last}');
      } else {
        _out('  ⚠️  Key not found in ${file.uri.pathSegments.last}');
      }
    } catch (error) {
      success = false;
      _err('  ❌ Failed to update ${file.uri.pathSegments.last}: $error');
    }
  }

  return success;
}

Future<bool> _exportCommand(List<String> args) async {
  if (args.length < 2) {
    _err('Usage: export <lang-dir> <format> [output]');
    return false;
  }

  final langDir = args[0];
  final format = args[1].toLowerCase();
  final defaultOutput = switch (format) {
    'csv' => 'translations_export.csv',
    'arb' => 'arb',
    _ => 'translations_export.json',
  };
  final outputPath = args.length > 2 ? args[2] : defaultOutput;

  final dir = Directory(langDir);
  if (!dir.existsSync()) {
    _err('❌ Language directory not found: $langDir');
    return false;
  }

  final localeData = <String, Map<String, dynamic>>{};
  for (final file in _jsonFilesInDir(dir)) {
    final locale = file.uri.pathSegments.last.replaceAll('.json', '');
    localeData[locale] = await _readJsonFile(file);
  }

  switch (format) {
    case 'json':
      await File(outputPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(localeData),
      );
      _out('✅ Exported JSON to $outputPath');
      return true;
    case 'csv':
      await _exportCsv(localeData, outputPath);
      _out('✅ Exported CSV to $outputPath');
      return true;
    case 'arb':
      final exported = await _exportArb(localeData, outputPath);
      if (exported) {
        _out('✅ Exported ARB files to $outputPath');
      }
      return exported;
    default:
      _err('❌ Unsupported format: $format. Use "json", "csv", or "arb".');
      return false;
  }
}

Future<bool> _importCommand(List<String> args) async {
  if (args.length < 2) {
    _err('Usage: import <file> <lang-dir>');
    return false;
  }

  final importPath = args[0];
  final importFile = File(importPath);
  final importDirectory = Directory(importPath);
  final langDir = args[1];
  final hasFile = importFile.existsSync();
  final hasDirectory = importDirectory.existsSync();
  if (!hasFile && !hasDirectory) {
    _err('❌ Import source not found: $importPath');
    return false;
  }

  final dir = Directory(langDir);
  await dir.create(recursive: true);

  if (hasDirectory) {
    final arbFiles =
        importDirectory.listSync().whereType<File>().where((file) => file.path.toLowerCase().endsWith('.arb')).toList();
    if (arbFiles.isNotEmpty) {
      return _importArbDirectory(importDirectory, langDir);
    }
    _err('❌ Unsupported directory import source: ${importDirectory.path}');
    return false;
  }

  final extension = importFile.path.split('.').last.toLowerCase();
  switch (extension) {
    case 'json':
      return _importJson(importFile, langDir);
    case 'csv':
      return _importCsv(importFile, langDir);
    case 'arb':
      return _importArbFile(importFile, langDir);
    case 'yaml':
    case 'yml':
      return _importFromL10nYaml(importFile, langDir);
    default:
      _err('❌ Unsupported import file type: .$extension');
      return false;
  }
}

Iterable<File> _jsonFilesInDir(Directory dir) {
  final files = dir.listSync().whereType<File>().where((file) => file.path.endsWith('.json')).toList()
    ..sort((left, right) => left.path.compareTo(right.path));
  return files;
}

Future<Map<String, dynamic>> _readJsonFile(File file) async {
  final content = await file.readAsString();
  return jsonDecode(content) as Map<String, dynamic>;
}

Future<void> _writeJsonFile(File file, Map<String, dynamic> data) async {
  await file.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
}

Map<String, dynamic> _cloneStructureForNewLocale(Map<String, dynamic> source) {
  final output = <String, dynamic>{};
  for (final entry in source.entries) {
    output[entry.key] = _cloneValueForNewLocale(entry.value);
  }
  return output;
}

dynamic _cloneValueForNewLocale(dynamic value) {
  if (value is String) {
    return '';
  }

  if (value is Map<String, dynamic>) {
    final map = <String, dynamic>{};
    for (final entry in value.entries) {
      map[entry.key] = _cloneValueForNewLocale(entry.value);
    }
    return map;
  }

  if (value is List) {
    return value.map(_cloneValueForNewLocale).toList();
  }

  return value;
}

bool _setValueByPath(
  Map<String, dynamic> map,
  String path,
  dynamic value, {
  required bool overwrite,
}) {
  final parts = path.split('.');
  if (parts.isEmpty) {
    return false;
  }

  Map<String, dynamic> current = map;
  for (var index = 0; index < parts.length - 1; index++) {
    final part = parts[index];
    final next = current[part];
    if (next is Map<String, dynamic>) {
      current = next;
      continue;
    }
    final created = <String, dynamic>{};
    current[part] = created;
    current = created;
  }

  final leaf = parts.last;
  if (!overwrite && current.containsKey(leaf)) {
    return false;
  }
  current[leaf] = value;
  return true;
}

bool _hasPath(Map<String, dynamic> map, String path) {
  final parts = path.split('.');
  dynamic current = map;
  for (final part in parts) {
    if (current is Map<String, dynamic> && current.containsKey(part)) {
      current = current[part];
    } else {
      return false;
    }
  }
  return true;
}

bool _removeValueByPath(Map<String, dynamic> map, String path) {
  final parts = path.split('.');
  if (parts.isEmpty) {
    return false;
  }

  Map<String, dynamic> current = map;
  for (var index = 0; index < parts.length - 1; index++) {
    final next = current[parts[index]];
    if (next is! Map<String, dynamic>) {
      return false;
    }
    current = next;
  }

  return current.remove(parts.last) != null;
}

Future<void> _exportCsv(
  Map<String, Map<String, dynamic>> localeData,
  String outputPath,
) async {
  final locales = localeData.keys.toList()..sort();
  final flattenedByLocale = <String, Map<String, String>>{};
  final allKeys = <String>{};

  for (final locale in locales) {
    final flattened = <String, String>{};
    _flattenMapForCsv(localeData[locale]!, '', flattened);
    flattenedByLocale[locale] = flattened;
    allKeys.addAll(flattened.keys);
  }

  final orderedKeys = allKeys.toList()..sort();
  final lines = <String>[];
  lines.add(['key', ...locales].map(_escapeCsv).join(','));

  for (final key in orderedKeys) {
    final row = <String>[key];
    for (final locale in locales) {
      row.add(flattenedByLocale[locale]![key] ?? '');
    }
    lines.add(row.map(_escapeCsv).join(','));
  }

  await File(outputPath).writeAsString(lines.join('\n'));
}

void _flattenMapForCsv(
  Map<String, dynamic> map,
  String prefix,
  Map<String, String> output,
) {
  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      _flattenMapForCsv(value, key, output);
    } else if (value is String) {
      output[key] = value;
    } else {
      output[key] = jsonEncode(value);
    }
  }
}

String _escapeCsv(String input) {
  if (input.contains(',') || input.contains('"') || input.contains('\n')) {
    final escaped = input.replaceAll('"', '""');
    return '"$escaped"';
  }
  return input;
}

Future<bool> _importJson(File importFile, String langDir) async {
  try {
    final content = await importFile.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      _err('❌ JSON import must be an object of locale-to-translations.');
      return false;
    }

    var success = true;
    for (final entry in decoded.entries) {
      final locale = entry.key.toString();
      final value = entry.value;
      if (value is! Map<String, dynamic>) {
        success = false;
        _err('❌ Skipping "$locale": translation value must be an object.');
        continue;
      }
      final file = File('$langDir/$locale.json');
      await _writeJsonFile(file, value);
      _out('✅ Imported $locale (${file.path})');
    }
    return success;
  } catch (error) {
    _err('❌ JSON import failed: $error');
    return false;
  }
}

Future<bool> _importCsv(File importFile, String langDir) async {
  try {
    final lines = await importFile.readAsLines();
    if (lines.isEmpty) {
      _err('❌ CSV import file is empty.');
      return false;
    }

    final header = _parseCsvLine(lines.first);
    if (header.length < 2 || header.first != 'key') {
      _err('❌ CSV header must start with "key".');
      return false;
    }

    final locales = header.skip(1).toList();
    final byLocale = <String, Map<String, dynamic>>{
      for (final locale in locales) locale: <String, dynamic>{},
    };

    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final row = _parseCsvLine(line);
      if (row.isEmpty) continue;
      final key = row.first;
      for (var index = 0; index < locales.length; index++) {
        final locale = locales[index];
        final value = index + 1 < row.length ? row[index + 1] : '';
        _setValueByPath(
          byLocale[locale]!,
          key,
          _decodeMaybeJson(value),
          overwrite: true,
        );
      }
    }

    for (final entry in byLocale.entries) {
      final file = File('$langDir/${entry.key}.json');
      await _writeJsonFile(file, entry.value);
      _out('✅ Imported ${entry.key} (${file.path})');
    }
    return true;
  } catch (error) {
    _err('❌ CSV import failed: $error');
    return false;
  }
}

Future<bool> _exportArb(
  Map<String, Map<String, dynamic>> localeData,
  String outputPath,
) async {
  try {
    final flattened = <String, Map<String, dynamic>>{};
    for (final entry in localeData.entries) {
      final localeFlat = <String, dynamic>{};
      _flattenMapForArb(entry.value, '', localeFlat);
      flattened[entry.key] = localeFlat;
    }

    await ArbInterop.exportArbDirectory(
      localeData: flattened,
      outputDirectory: outputPath,
    );
    return true;
  } catch (error) {
    _err('❌ ARB export failed: $error');
    return false;
  }
}

Future<bool> _importArbFile(File importFile, String langDir) async {
  try {
    final document = ArbInterop.parseArb(
      await importFile.readAsString(),
      fileName: importFile.uri.pathSegments.last,
    );
    final expanded = _expandDottedMap(document.translations);
    final output = File('$langDir/${document.locale}.json');
    await _writeJsonFile(output, expanded);
    _out('✅ Imported ${document.locale} (${output.path})');
    return true;
  } catch (error) {
    _err('❌ ARB import failed: $error');
    return false;
  }
}

Future<bool> _importArbDirectory(Directory importDirectory, String langDir) async {
  try {
    final imported = await ArbInterop.importArbDirectory(importDirectory.path);
    for (final entry in imported.entries) {
      final expanded = _expandDottedMap(entry.value);
      final output = File('$langDir/${entry.key}.json');
      await _writeJsonFile(output, expanded);
      _out('✅ Imported ${entry.key} (${output.path})');
    }
    return true;
  } catch (error) {
    _err('❌ ARB directory import failed: $error');
    return false;
  }
}

Future<bool> _importFromL10nYaml(File l10nYamlFile, String langDir) async {
  try {
    final imported = await ArbInterop.importUsingL10nYaml(l10nYamlFile.path);
    if (imported.isEmpty) {
      _err('❌ No locale ARB files found for l10n config: ${l10nYamlFile.path}');
      return false;
    }
    for (final entry in imported.entries) {
      final expanded = _expandDottedMap(entry.value);
      final output = File('$langDir/${entry.key}.json');
      await _writeJsonFile(output, expanded);
      _out('✅ Imported ${entry.key} (${output.path})');
    }
    return true;
  } catch (error) {
    _err('❌ l10n.yaml import failed: $error');
    return false;
  }
}

void _flattenMapForArb(
  Map<String, dynamic> map,
  String prefix,
  Map<String, dynamic> output,
) {
  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;

    if (value is String) {
      output[key] = value;
      continue;
    }

    if (value is Map<String, dynamic>) {
      if (_isPluralFormsMap(value) && value.values.every((item) => item is String)) {
        output[key] = _pluralFormsMapToIcu(value);
      } else {
        _flattenMapForArb(value, key, output);
      }
      continue;
    }

    output[key] = jsonEncode(value);
  }
}

bool _isPluralFormsMap(Map<String, dynamic> map) {
  const pluralForms = {'zero', 'one', 'two', 'few', 'many', 'other', 'more'};
  return map.keys.isNotEmpty && map.keys.every(pluralForms.contains);
}

String _pluralFormsMapToIcu(Map<String, dynamic> pluralMap) {
  const orderedForms = ['zero', 'one', 'two', 'few', 'many', 'other'];
  final forms = <String>[];
  for (final form in orderedForms) {
    final value = pluralMap[form];
    if (value is! String) continue;
    final selector = form == 'zero' ? '=0' : form;
    forms.add('$selector{$value}');
  }
  final other = pluralMap['other'];
  if (other is String && !forms.any((entry) => entry.startsWith('other{'))) {
    forms.add('other{$other}');
  }
  if (forms.isEmpty) {
    return '';
  }
  return '{count, plural, ${forms.join(' ')}}';
}

Map<String, dynamic> _expandDottedMap(Map<String, dynamic> source) {
  final expanded = <String, dynamic>{};
  for (final entry in source.entries) {
    final value = entry.value is String ? _decodeMaybeJson(entry.value as String) : entry.value;
    _setValueByPath(
      expanded,
      entry.key,
      value,
      overwrite: true,
    );
  }
  return expanded;
}

List<String> _parseCsvLine(String line) {
  final cells = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (var index = 0; index < line.length; index++) {
    final char = line[index];
    if (char == '"') {
      final nextIsQuote = index + 1 < line.length && line[index + 1] == '"';
      if (inQuotes && nextIsQuote) {
        buffer.write('"');
        index++;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (char == ',' && !inQuotes) {
      cells.add(buffer.toString());
      buffer.clear();
      continue;
    }

    buffer.write(char);
  }
  cells.add(buffer.toString());
  return cells;
}

dynamic _decodeMaybeJson(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  if ((trimmed.startsWith('{') && trimmed.endsWith('}')) || (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return value;
    }
  }
  return value;
}
