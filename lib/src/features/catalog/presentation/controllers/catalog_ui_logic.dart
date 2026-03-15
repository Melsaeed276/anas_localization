library;

import 'dart:convert';

import '../../domain/services/catalog_flatten.dart';

enum CatalogEditorMode {
  plain,
  gender,
  plural,
  pluralGender,
  raw,
}

enum CatalogDraftSyncState {
  clean,
  dirty,
  saving,
  saved,
  saveError,
}

const List<String> catalogPluralKeys = <String>[
  'zero',
  'one',
  'two',
  'few',
  'many',
  'other',
];

const List<String> catalogGenderKeys = <String>[
  'male',
  'female',
];

dynamic cloneCatalogValue(dynamic value) {
  if (value == null) {
    return null;
  }
  return jsonDecode(jsonEncode(value));
}

String formatCatalogLocale(String locale) {
  return locale.replaceAll('_', '-').toUpperCase();
}

String prettyCatalogJson(dynamic value) {
  return const JsonEncoder.withIndent('  ').convert(value);
}

bool isPlainCatalogObject(dynamic value) {
  return value is Map && value is! List;
}

bool isPrimitiveCatalogLeaf(dynamic value) {
  return value == null || value is String || value is num || value is bool;
}

List<String> normalizedPluralKeys(dynamic value) {
  if (!isPlainCatalogObject(value)) {
    return const <String>[];
  }
  final map = Map<String, dynamic>.from(value as Map);
  final existing = map.keys.toList();
  final canonical = catalogPluralKeys.where(existing.contains).toList();
  final extras = existing.where((key) => !canonical.contains(key)).toList()..sort();
  return <String>[...canonical, ...extras];
}

List<String> normalizedGenderKeys(dynamic value) {
  if (!isPlainCatalogObject(value)) {
    return const <String>[];
  }
  final map = Map<String, dynamic>.from(value as Map);
  final existing = map.keys.toList();
  final canonical = catalogGenderKeys.where(existing.contains).toList();
  final extras = existing.where((key) => !canonical.contains(key)).toList()..sort();
  return <String>[...canonical, ...extras];
}

CatalogEditorMode detectCatalogShape(dynamic value) {
  if (!isPlainCatalogObject(value)) {
    return CatalogEditorMode.plain;
  }
  final map = Map<String, dynamic>.from(value as Map);
  if (map.isEmpty) {
    return CatalogEditorMode.raw;
  }

  final keys = map.keys.toList();
  final isGender = keys.every(catalogGenderKeys.contains) && keys.every((key) => isPrimitiveCatalogLeaf(map[key]));
  if (isGender) {
    return CatalogEditorMode.gender;
  }

  final isPlural = keys.every(catalogPluralKeys.contains) && keys.every((key) => isPrimitiveCatalogLeaf(map[key]));
  if (isPlural) {
    return CatalogEditorMode.plural;
  }

  final isPluralGender = keys.every(catalogPluralKeys.contains) &&
      keys.every((key) => isPlainCatalogObject(map[key])) &&
      keys.every((key) => Map<String, dynamic>.from(map[key] as Map).keys.every(catalogGenderKeys.contains)) &&
      keys.every(
        (key) => Map<String, dynamic>.from(map[key] as Map).keys.every(
              (nestedKey) => isPrimitiveCatalogLeaf(map[key][nestedKey]),
            ),
      );
  if (isPluralGender) {
    return CatalogEditorMode.pluralGender;
  }

  return CatalogEditorMode.raw;
}

CatalogEditorMode detectEditorMode({
  required dynamic serverValue,
  required dynamic sourceValue,
  required bool rawPinned,
}) {
  if (rawPinned) {
    return CatalogEditorMode.raw;
  }
  final candidate = !isCatalogValueEmpty(serverValue) ? serverValue : sourceValue;
  final mode = detectCatalogShape(candidate);
  return mode == CatalogEditorMode.raw ? CatalogEditorMode.raw : mode;
}

dynamic buildInitialCatalogValue({
  required dynamic serverValue,
  required dynamic sourceValue,
  required CatalogEditorMode editorMode,
}) {
  if (!isCatalogValueEmpty(serverValue)) {
    return cloneCatalogValue(serverValue);
  }
  switch (editorMode) {
    case CatalogEditorMode.gender:
      final result = <String, dynamic>{};
      for (final key in normalizedGenderKeys(sourceValue)) {
        result[key] = '';
      }
      return result;
    case CatalogEditorMode.plural:
      final result = <String, dynamic>{};
      for (final key in normalizedPluralKeys(sourceValue)) {
        result[key] = '';
      }
      return result;
    case CatalogEditorMode.pluralGender:
      final result = <String, dynamic>{};
      for (final pluralKey in normalizedPluralKeys(sourceValue)) {
        final nested = <String, dynamic>{};
        for (final genderKey in normalizedGenderKeys((sourceValue as Map)[pluralKey])) {
          nested[genderKey] = '';
        }
        result[pluralKey] = nested;
      }
      return result;
    case CatalogEditorMode.raw:
    case CatalogEditorMode.plain:
      if (serverValue is num || serverValue is bool) {
        return serverValue;
      }
      return serverValue is String ? serverValue : '';
  }
}

Set<String> collectCatalogPlaceholders(dynamic value, [Set<String>? output]) {
  final result = output ?? <String>{};
  if (value is String) {
    for (final match in RegExp(r'\{([a-zA-Z0-9_]+)\}').allMatches(value)) {
      final placeholder = match.group(1);
      if (placeholder != null) {
        result.add(placeholder);
      }
    }
    return result;
  }
  if (value is List) {
    for (final item in value) {
      collectCatalogPlaceholders(item, result);
    }
    return result;
  }
  if (value is Map) {
    for (final item in value.values) {
      collectCatalogPlaceholders(item, result);
    }
  }
  return result;
}

dynamic readCatalogPath(dynamic value, List<String> path) {
  if (path.isEmpty) {
    return value;
  }
  dynamic current = value;
  for (final key in path) {
    if (current is! Map || !current.containsKey(key)) {
      return '';
    }
    current = current[key];
  }
  return current;
}

dynamic setCatalogPathValue(dynamic root, List<String> path, dynamic value) {
  if (path.isEmpty) {
    return value;
  }
  final next =
      isPlainCatalogObject(root) ? Map<String, dynamic>.from(cloneCatalogValue(root) as Map) : <String, dynamic>{};
  Map<String, dynamic> current = next;
  for (var index = 0; index < path.length - 1; index += 1) {
    final key = path[index];
    final nested = current[key];
    if (nested is Map<String, dynamic>) {
      current = nested;
      continue;
    }
    final replacement = <String, dynamic>{};
    current[key] = replacement;
    current = replacement;
  }
  current[path.last] = value;
  return next;
}

List<List<String>> requiredCatalogPaths({
  required dynamic sourceValue,
  required dynamic currentValue,
  required CatalogEditorMode editorMode,
}) {
  final basis = !isCatalogValueEmpty(sourceValue) ? sourceValue : currentValue;
  switch (editorMode) {
    case CatalogEditorMode.gender:
      return normalizedGenderKeys(basis).map((key) => <String>[key]).toList();
    case CatalogEditorMode.plural:
      return normalizedPluralKeys(basis).map((key) => <String>[key]).toList();
    case CatalogEditorMode.pluralGender:
      return normalizedPluralKeys(basis).expand((pluralKey) {
        final nestedBasis = basis is Map ? basis[pluralKey] : const <String, dynamic>{};
        return normalizedGenderKeys(nestedBasis).map((genderKey) => <String>[pluralKey, genderKey]);
      }).toList();
    case CatalogEditorMode.raw:
    case CatalogEditorMode.plain:
      return const <List<String>>[
        <String>[],
      ];
  }
}

String canonicalizeForDraft(dynamic value) {
  return canonicalizeCatalogValue(value);
}
