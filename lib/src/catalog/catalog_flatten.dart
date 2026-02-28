library;

import 'dart:convert';

const Set<String> _pluralKeys = {'zero', 'one', 'two', 'few', 'many', 'other'};
const Set<String> _genderKeys = {'male', 'female'};

Map<String, dynamic> flattenTranslationMap(Map<String, dynamic> map) {
  final output = <String, dynamic>{};
  _flattenInto(output, map, '');
  return output;
}

void _flattenInto(
  Map<String, dynamic> output,
  Map<String, dynamic> map,
  String prefix,
) {
  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;

    if (value is Map<String, dynamic> && !_isLeafLikeMap(value)) {
      _flattenInto(output, value, key);
      continue;
    }

    output[key] = value;
  }
}

bool _isLeafLikeMap(Map<String, dynamic> value) {
  if (value.isEmpty) {
    return false;
  }

  final keys = value.keys.toSet();
  final pluralish = keys.any(_pluralKeys.contains);
  final genderish = keys.any(_genderKeys.contains);
  return pluralish || genderish;
}

bool catalogHasPath(Map<String, dynamic> map, String keyPath) {
  return catalogGetValueByPath(map, keyPath) != null;
}

dynamic catalogGetValueByPath(Map<String, dynamic> map, String keyPath) {
  if (keyPath.trim().isEmpty) {
    return null;
  }
  final parts = keyPath.split('.');
  dynamic current = map;
  for (final part in parts) {
    if (current is! Map<String, dynamic>) {
      return null;
    }
    if (!current.containsKey(part)) {
      return null;
    }
    current = current[part];
  }
  return current;
}

void catalogSetValueByPath(
  Map<String, dynamic> map,
  String keyPath,
  dynamic value,
) {
  final parts = keyPath.split('.');
  if (parts.isEmpty) return;

  Map<String, dynamic> current = map;
  for (var index = 0; index < parts.length - 1; index++) {
    final part = parts[index];
    final existing = current[part];
    if (existing is Map<String, dynamic>) {
      current = existing;
      continue;
    }
    final next = <String, dynamic>{};
    current[part] = next;
    current = next;
  }
  current[parts.last] = value;
}

bool catalogRemoveValueByPath(Map<String, dynamic> map, String keyPath) {
  final parts = keyPath.split('.');
  if (parts.isEmpty) return false;
  return _removeRecursive(map, parts, 0);
}

bool _removeRecursive(
  Map<String, dynamic> current,
  List<String> parts,
  int index,
) {
  final part = parts[index];
  if (!current.containsKey(part)) {
    return false;
  }

  if (index == parts.length - 1) {
    current.remove(part);
    return true;
  }

  final next = current[part];
  if (next is! Map<String, dynamic>) {
    return false;
  }

  final removed = _removeRecursive(next, parts, index + 1);
  if (removed && next.isEmpty) {
    current.remove(part);
  }
  return removed;
}

bool isValidCatalogKeyPath(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.startsWith('.') || trimmed.endsWith('.') || trimmed.contains('..')) {
    return false;
  }

  final segmentPattern = RegExp(r'^[a-zA-Z0-9_]+$');
  return trimmed.split('.').every(segmentPattern.hasMatch);
}

bool isCatalogValueEmpty(dynamic value) {
  if (value == null) return true;
  if (value is String) return value.trim().isEmpty;
  if (value is List) return value.isEmpty;
  if (value is Map) return value.isEmpty;
  return false;
}

String canonicalizeCatalogValue(dynamic value) {
  return _canonicalize(value);
}

String _canonicalize(dynamic value) {
  if (value == null) return 'null';
  if (value is String) return jsonEncode(value);
  if (value is num || value is bool) return value.toString();

  if (value is List) {
    final values = value.map(_canonicalize).join(',');
    return '[$values]';
  }

  if (value is Map) {
    final normalized = Map<String, dynamic>.from(value.map((key, nested) => MapEntry(key.toString(), nested)));
    final keys = normalized.keys.toList()..sort();
    final pairs = keys.map((key) => '${jsonEncode(key)}:${_canonicalize(normalized[key])}').join(',');
    return '{$pairs}';
  }

  return jsonEncode(value.toString());
}
