library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

typedef TranslationMap = Map<String, dynamic>;

abstract class TranslationLoader {
  const TranslationLoader();

  String get id;

  List<String> get fileExtensions;

  Future<TranslationMap?> load(String basePath);
}

class TranslationLoaderRegistry {
  TranslationLoaderRegistry([Iterable<TranslationLoader>? loaders]) {
    final source = loaders ?? const [JsonTranslationLoader()];
    for (final loader in source) {
      register(loader);
    }
  }

  factory TranslationLoaderRegistry.withDefaults() {
    return TranslationLoaderRegistry(const [
      JsonTranslationLoader(),
      YamlTranslationLoader(),
      CsvTranslationLoader(),
    ]);
  }

  final List<TranslationLoader> _orderedLoaders = <TranslationLoader>[];

  List<TranslationLoader> get loaders => List<TranslationLoader>.unmodifiable(_orderedLoaders);

  void register(TranslationLoader loader, {bool highestPriority = false}) {
    _orderedLoaders.removeWhere((existing) => existing.id == loader.id);
    if (highestPriority) {
      _orderedLoaders.insert(0, loader);
    } else {
      _orderedLoaders.add(loader);
    }
  }

  bool unregister(String loaderId) {
    final before = _orderedLoaders.length;
    _orderedLoaders.removeWhere((loader) => loader.id == loaderId);
    return _orderedLoaders.length != before;
  }

  void resetToDefaults() {
    _orderedLoaders
      ..clear()
      ..addAll(const [
        JsonTranslationLoader(),
        YamlTranslationLoader(),
        CsvTranslationLoader(),
      ]);
  }

  Future<TranslationMap?> loadFirst(String basePath) async {
    for (final loader in _orderedLoaders) {
      final loaded = await loader.load(basePath);
      if (loaded != null) {
        return loaded;
      }
    }
    return null;
  }
}

class JsonTranslationLoader extends TranslationLoader {
  const JsonTranslationLoader();

  @override
  String get id => 'json';

  @override
  List<String> get fileExtensions => const ['json'];

  @override
  Future<TranslationMap?> load(String basePath) async {
    final content = await _loadFirstContent(basePath, fileExtensions);
    if (content == null) return null;
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (error) {
      debugPrint('Failed to parse JSON translation ($basePath): $error');
    }
    return null;
  }
}

class YamlTranslationLoader extends TranslationLoader {
  const YamlTranslationLoader();

  @override
  String get id => 'yaml';

  @override
  List<String> get fileExtensions => const ['yaml', 'yml'];

  @override
  Future<TranslationMap?> load(String basePath) async {
    final content = await _loadFirstContent(basePath, fileExtensions);
    if (content == null) return null;
    try {
      final parsed = loadYaml(content);
      final converted = _yamlToPlainObject(parsed);
      if (converted is Map<String, dynamic>) return converted;
      if (converted is Map) return Map<String, dynamic>.from(converted);
    } catch (error) {
      debugPrint('Failed to parse YAML translation ($basePath): $error');
    }
    return null;
  }
}

class CsvTranslationLoader extends TranslationLoader {
  const CsvTranslationLoader();

  @override
  String get id => 'csv';

  @override
  List<String> get fileExtensions => const ['csv'];

  @override
  Future<TranslationMap?> load(String basePath) async {
    final content = await _loadFirstContent(basePath, fileExtensions);
    if (content == null) return null;

    try {
      final map = <String, dynamic>{};
      final lines = const LineSplitter().convert(content);
      if (lines.isEmpty) {
        return map;
      }

      var startIndex = 0;
      final header = _parseCsvLine(lines.first).map((cell) => cell.trim().toLowerCase()).toList();
      if (header.length >= 2 && header[0] == 'key' && header[1] == 'value') {
        startIndex = 1;
      }

      for (var index = startIndex; index < lines.length; index++) {
        final line = lines[index].trim();
        if (line.isEmpty) continue;
        final cells = _parseCsvLine(line);
        if (cells.isEmpty) continue;
        final key = cells.first.trim();
        if (key.isEmpty) continue;
        final value = cells.length > 1 ? cells[1] : '';
        _setValueByPath(map, key, value);
      }

      return map;
    } catch (error) {
      debugPrint('Failed to parse CSV translation ($basePath): $error');
      return null;
    }
  }
}

class HttpTranslationLoader extends TranslationLoader {
  HttpTranslationLoader({
    required this.baseUrl,
    this.client,
    this.requestHeaders,
    List<String>? fileExtensions,
  }) : _fileExtensions = fileExtensions ?? const ['json'];

  final String baseUrl;
  final http.Client? client;
  final Map<String, String>? requestHeaders;
  final List<String> _fileExtensions;

  @override
  String get id => 'http';

  @override
  List<String> get fileExtensions => _fileExtensions;

  @override
  Future<TranslationMap?> load(String basePath) async {
    final normalizedBasePath = _stripExtension(basePath);
    final localeCode = normalizedBasePath.split('/').last;
    final requestClient = client ?? http.Client();

    try {
      for (final extension in fileExtensions) {
        final uri = Uri.parse('$baseUrl/$localeCode.$extension');
        final response = await requestClient.get(uri, headers: requestHeaders);
        if (response.statusCode != 200) continue;
        final body = response.body;
        if (extension.toLowerCase() == 'json') {
          final decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } else if (extension.toLowerCase() == 'yaml' || extension.toLowerCase() == 'yml') {
          final parsed = loadYaml(body);
          final converted = _yamlToPlainObject(parsed);
          if (converted is Map<String, dynamic>) return converted;
          if (converted is Map) return Map<String, dynamic>.from(converted);
        } else if (extension.toLowerCase() == 'csv') {
          return const CsvTranslationLoader()._parseFromContent(body);
        }
      }
      return null;
    } catch (error) {
      debugPrint('Failed to load remote translation ($basePath): $error');
      return null;
    } finally {
      if (client == null) {
        requestClient.close();
      }
    }
  }
}

extension on CsvTranslationLoader {
  TranslationMap _parseFromContent(String content) {
    final map = <String, dynamic>{};
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) {
      return map;
    }

    var startIndex = 0;
    final header = _parseCsvLine(lines.first).map((cell) => cell.trim().toLowerCase()).toList();
    if (header.length >= 2 && header[0] == 'key' && header[1] == 'value') {
      startIndex = 1;
    }

    for (var index = startIndex; index < lines.length; index++) {
      final line = lines[index].trim();
      if (line.isEmpty) continue;
      final cells = _parseCsvLine(line);
      if (cells.isEmpty) continue;
      final key = cells.first.trim();
      if (key.isEmpty) continue;
      final value = cells.length > 1 ? cells[1] : '';
      _setValueByPath(map, key, value);
    }

    return map;
  }
}

Future<String?> _loadFirstContent(String basePath, List<String> fileExtensions) async {
  final normalizedBasePath = _stripExtension(basePath);
  for (final extension in fileExtensions) {
    final candidatePath = '$normalizedBasePath.$extension';
    try {
      return await rootBundle.loadString(candidatePath);
    } on FlutterError {
      continue;
    } catch (error) {
      debugPrint('Failed to read translation asset ($candidatePath): $error');
      continue;
    }
  }
  return null;
}

Object? _yamlToPlainObject(Object? input) {
  if (input is YamlMap) {
    return input.map((key, value) => MapEntry(key.toString(), _yamlToPlainObject(value)));
  }
  if (input is YamlList) {
    return input.map(_yamlToPlainObject).toList();
  }
  return input;
}

String _stripExtension(String basePath) {
  final extensionPattern = RegExp(r'\.(json|yaml|yml|csv)$');
  return basePath.replaceFirst(extensionPattern, '');
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

void _setValueByPath(Map<String, dynamic> map, String path, dynamic value) {
  final segments = path.split('.');
  if (segments.isEmpty) return;

  Map<String, dynamic> current = map;
  for (var index = 0; index < segments.length - 1; index++) {
    final key = segments[index];
    final next = current[key];
    if (next is Map<String, dynamic>) {
      current = next;
      continue;
    }
    final created = <String, dynamic>{};
    current[key] = created;
    current = created;
  }

  current[segments.last] = value;
}
