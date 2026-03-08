library;

import 'dart:convert';

import 'package:yaml/yaml.dart';

class TranslationFileParser {
  const TranslationFileParser._();

  static Map<String, dynamic> parseJsonContent(String content) {
    final decoded = jsonDecode(content);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw const FormatException('JSON translation content must be an object.');
  }

  static Map<String, dynamic> parseYamlContent(String content) {
    final parsed = loadYaml(content);
    final converted = yamlToPlainObject(parsed);
    if (converted is Map<String, dynamic>) {
      return converted;
    }
    if (converted is Map) {
      return Map<String, dynamic>.from(converted);
    }
    throw const FormatException('YAML translation content must be an object.');
  }

  static Map<String, dynamic> parseCsvContent(String content) {
    final map = <String, dynamic>{};
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) {
      return map;
    }

    var startIndex = 0;
    final header = parseCsvLine(lines.first).map((cell) => cell.trim().toLowerCase()).toList();
    if (header.length >= 2 && header[0] == 'key' && header[1] == 'value') {
      startIndex = 1;
    }

    for (var index = startIndex; index < lines.length; index++) {
      final line = lines[index].trim();
      if (line.isEmpty) continue;
      final cells = parseCsvLine(line);
      if (cells.isEmpty) continue;
      final key = cells.first.trim();
      if (key.isEmpty) continue;
      final value = cells.length > 1 ? cells[1] : '';
      setValueByPath(map, key, decodeMaybeJsonValue(value));
    }

    return map;
  }

  static Map<String, dynamic> expandDottedMap(Map<String, dynamic> source) {
    final expanded = <String, dynamic>{};
    for (final entry in source.entries) {
      final value = entry.value is String ? decodeMaybeJsonValue(entry.value as String) : entry.value;
      setValueByPath(expanded, entry.key, value);
    }
    return expanded;
  }

  static Object? yamlToPlainObject(Object? input) {
    if (input is YamlMap) {
      return input.map((key, value) => MapEntry(key.toString(), yamlToPlainObject(value)));
    }
    if (input is YamlList) {
      return input.map(yamlToPlainObject).toList();
    }
    return input;
  }

  static List<String> parseCsvLine(String line) {
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

  static dynamic decodeMaybeJsonValue(String value) {
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

  static void setValueByPath(Map<String, dynamic> map, String path, dynamic value) {
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
}
