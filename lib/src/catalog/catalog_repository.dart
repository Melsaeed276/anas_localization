library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../utils/arb_interop.dart';
import 'catalog_config.dart';
import 'catalog_flatten.dart';

class CatalogDataset {
  CatalogDataset({
    required this.translationsByLocale,
    this.arbMetadataByLocale = const <String, Map<String, dynamic>>{},
  });

  final Map<String, Map<String, dynamic>> translationsByLocale;
  final Map<String, Map<String, dynamic>> arbMetadataByLocale;

  List<String> get locales => translationsByLocale.keys.toList()..sort();
}

class CatalogRepository {
  CatalogRepository({
    required this.config,
    required this.projectRootPath,
  });

  final CatalogConfig config;
  final String projectRootPath;

  String get _langDirectoryPath => config.resolveLangDirectory(projectRootPath);

  Future<CatalogDataset> load() async {
    switch (config.format) {
      case CatalogFileFormat.json:
        return _loadJsonLike('json');
      case CatalogFileFormat.yaml:
        return _loadYaml();
      case CatalogFileFormat.csv:
        return _loadCsv();
      case CatalogFileFormat.arb:
        return _loadArb();
    }
  }

  Future<void> save(CatalogDataset dataset) async {
    final dir = Directory(_langDirectoryPath);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    switch (config.format) {
      case CatalogFileFormat.json:
        await _saveJsonLike(
          dataset,
          extension: 'json',
        );
        return;
      case CatalogFileFormat.yaml:
        await _saveYaml(dataset);
        return;
      case CatalogFileFormat.csv:
        await _saveCsv(dataset);
        return;
      case CatalogFileFormat.arb:
        await _saveArb(dataset);
        return;
    }
  }

  Future<CatalogDataset> _loadJsonLike(String extension) async {
    final data = <String, Map<String, dynamic>>{};
    final dir = Directory(_langDirectoryPath);
    if (!dir.existsSync()) {
      return CatalogDataset(translationsByLocale: data);
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.$extension'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final locale = p.basenameWithoutExtension(file.path);
      if (!_isLocaleCode(locale)) {
        continue;
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) {
        data[locale] = Map<String, dynamic>.from(decoded);
      }
    }

    return CatalogDataset(translationsByLocale: data);
  }

  Future<CatalogDataset> _loadYaml() async {
    final data = <String, Map<String, dynamic>>{};
    final dir = Directory(_langDirectoryPath);
    if (!dir.existsSync()) {
      return CatalogDataset(translationsByLocale: data);
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((file) {
          final lower = file.path.toLowerCase();
          return lower.endsWith('.yaml') || lower.endsWith('.yml');
        })
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final locale = p.basenameWithoutExtension(file.path);
      if (!_isLocaleCode(locale)) {
        continue;
      }
      final parsed = loadYaml(await file.readAsString());
      final plain = _yamlToPlainObject(parsed);
      if (plain is Map) {
        data[locale] = Map<String, dynamic>.from(plain);
      }
    }

    return CatalogDataset(translationsByLocale: data);
  }

  Future<CatalogDataset> _loadCsv() async {
    final data = <String, Map<String, dynamic>>{};
    final dir = Directory(_langDirectoryPath);
    if (!dir.existsSync()) {
      return CatalogDataset(translationsByLocale: data);
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.csv'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final locale = p.basenameWithoutExtension(file.path);
      if (!_isLocaleCode(locale)) {
        continue;
      }
      final map = <String, dynamic>{};
      final lines = const LineSplitter().convert(await file.readAsString());
      var startIndex = 0;
      if (lines.isNotEmpty) {
        final header = _parseCsvLine(lines.first).map((cell) => cell.trim().toLowerCase()).toList();
        if (header.length >= 2 && header[0] == 'key' && header[1] == 'value') {
          startIndex = 1;
        }
      }
      for (var index = startIndex; index < lines.length; index++) {
        final line = lines[index].trim();
        if (line.isEmpty) {
          continue;
        }
        final cells = _parseCsvLine(line);
        if (cells.isEmpty || cells.first.trim().isEmpty) {
          continue;
        }
        final keyPath = cells.first.trim();
        final value = cells.length > 1 ? cells[1] : '';
        catalogSetValueByPath(map, keyPath, value);
      }
      data[locale] = map;
    }

    return CatalogDataset(translationsByLocale: data);
  }

  Future<CatalogDataset> _loadArb() async {
    final data = <String, Map<String, dynamic>>{};
    final metadataByLocale = <String, Map<String, dynamic>>{};
    final dir = Directory(_langDirectoryPath);
    if (!dir.existsSync()) {
      return CatalogDataset(translationsByLocale: data);
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.arb'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final document = ArbInterop.parseArb(
        await file.readAsString(),
        fileName: p.basename(file.path),
      );
      if (!_isLocaleCode(document.locale)) {
        continue;
      }
      data[document.locale] = Map<String, dynamic>.from(document.translations);
      metadataByLocale[document.locale] = Map<String, dynamic>.from(document.metadata);
    }

    return CatalogDataset(
      translationsByLocale: data,
      arbMetadataByLocale: metadataByLocale,
    );
  }

  Future<void> _saveJsonLike(
    CatalogDataset dataset, {
    required String extension,
  }) async {
    final writes = <String, String>{};
    for (final locale in dataset.locales) {
      final path = p.join(_langDirectoryPath, '$locale.$extension');
      writes[path] = const JsonEncoder.withIndent('  ').convert(dataset.translationsByLocale[locale]);
    }
    await _writeWithTransaction(writes);
  }

  Future<void> _saveYaml(CatalogDataset dataset) async {
    final writes = <String, String>{};
    for (final locale in dataset.locales) {
      final path = p.join(_langDirectoryPath, '$locale.yaml');
      writes[path] = _toYamlString(dataset.translationsByLocale[locale] ?? const <String, dynamic>{});
    }
    await _writeWithTransaction(writes);
  }

  Future<void> _saveCsv(CatalogDataset dataset) async {
    final writes = <String, String>{};
    for (final locale in dataset.locales) {
      final path = p.join(_langDirectoryPath, '$locale.csv');
      final flat = flattenTranslationMap(dataset.translationsByLocale[locale] ?? const <String, dynamic>{});
      final keys = flat.keys.toList()..sort();
      final lines = <String>['key,value'];
      for (final key in keys) {
        final value = flat[key];
        lines.add('${_escapeCsvCell(key)},${_escapeCsvCell(value?.toString() ?? '')}');
      }
      writes[path] = '${lines.join('\n')}\n';
    }
    await _writeWithTransaction(writes);
  }

  Future<void> _saveArb(CatalogDataset dataset) async {
    final writes = <String, String>{};
    for (final locale in dataset.locales) {
      final metadata = dataset.arbMetadataByLocale[locale] ?? const <String, dynamic>{};
      final document = ArbLocaleDocument(
        locale: locale,
        translations: dataset.translationsByLocale[locale] ?? const <String, dynamic>{},
        metadata: metadata,
      );
      final path = p.join(_langDirectoryPath, '${config.arbFilePrefix}_$locale.arb');
      writes[path] = ArbInterop.toArbString(document);
    }
    await _writeWithTransaction(writes);
  }

  Future<void> _writeWithTransaction(Map<String, String> writes) async {
    final backups = <String, _FileBackup>{};
    try {
      for (final entry in writes.entries) {
        final file = File(entry.key);
        backups[entry.key] = _FileBackup(
          existed: file.existsSync(),
          content: file.existsSync() ? await file.readAsString() : null,
        );
      }

      for (final entry in writes.entries) {
        final file = File(entry.key);
        await file.create(recursive: true);
        await file.writeAsString(entry.value);
      }
    } catch (error) {
      for (final entry in backups.entries) {
        final file = File(entry.key);
        final backup = entry.value;
        if (!backup.existed) {
          if (file.existsSync()) {
            file.deleteSync();
          }
          continue;
        }
        await file.create(recursive: true);
        await file.writeAsString(backup.content ?? '');
      }
      rethrow;
    }
  }

  static bool _isLocaleCode(String candidate) {
    final normalized = candidate.replaceAll('-', '_');
    return RegExp(r'^[a-zA-Z]{2,3}(?:_[a-zA-Z0-9]{2,8})*$').hasMatch(normalized);
  }
}

class _FileBackup {
  _FileBackup({
    required this.existed,
    required this.content,
  });

  final bool existed;
  final String? content;
}

dynamic _yamlToPlainObject(dynamic value) {
  if (value is YamlMap) {
    final map = <String, dynamic>{};
    for (final entry in value.entries) {
      map[entry.key.toString()] = _yamlToPlainObject(entry.value);
    }
    return map;
  }
  if (value is YamlList) {
    return value.map(_yamlToPlainObject).toList();
  }
  return value;
}

String _toYamlString(dynamic value, {int indent = 0}) {
  final padding = '  ' * indent;
  if (value is Map) {
    final map = Map<String, dynamic>.from(value.map((key, nested) => MapEntry(key.toString(), nested)));
    final keys = map.keys.toList();
    final lines = <String>[];
    for (final key in keys) {
      final nested = map[key];
      if (nested is Map || nested is List) {
        lines.add('$padding$key:');
        lines.add(_toYamlString(nested, indent: indent + 1));
      } else {
        lines.add('$padding$key: ${_yamlScalar(nested)}');
      }
    }
    return lines.join('\n');
  }
  if (value is List) {
    final lines = <String>[];
    for (final nested in value) {
      if (nested is Map || nested is List) {
        lines.add('$padding-');
        lines.add(_toYamlString(nested, indent: indent + 1));
      } else {
        lines.add('$padding- ${_yamlScalar(nested)}');
      }
    }
    return lines.join('\n');
  }
  return '$padding${_yamlScalar(value)}';
}

String _yamlScalar(dynamic value) {
  if (value == null) return 'null';
  if (value is num || value is bool) return value.toString();

  final text = value.toString();
  final escaped = text
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
  return '"$escaped"';
}

List<String> _parseCsvLine(String line) {
  final cells = <String>[];
  final current = StringBuffer();
  var inQuotes = false;

  for (var index = 0; index < line.length; index++) {
    final char = line[index];

    if (char == '"') {
      final nextIndex = index + 1;
      if (inQuotes && nextIndex < line.length && line[nextIndex] == '"') {
        current.write('"');
        index = nextIndex;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (char == ',' && !inQuotes) {
      cells.add(current.toString());
      current.clear();
      continue;
    }

    current.write(char);
  }

  cells.add(current.toString());
  return cells;
}

String _escapeCsvCell(String value) {
  if (value.contains('"') || value.contains(',') || value.contains('\n')) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
  return value;
}
