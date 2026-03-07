library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'codegen_utils.dart';
import 'translation_file_parser.dart';

enum LocalizationEntryKind {
  string,
  parameterizedString,
  plural,
}

class LocalizationEntry {
  const LocalizationEntry({
    required this.keyPath,
    required this.memberName,
    required this.kind,
    required this.placeholders,
    required this.typedAccessorDeterministic,
    required this.hasGender,
  });

  final String keyPath;
  final String memberName;
  final LocalizationEntryKind kind;
  final List<String> placeholders;
  final bool typedAccessorDeterministic;
  final bool hasGender;

  bool get hasPlaceholders => placeholders.isNotEmpty;
}

class LocalizationMetadataIndex {
  const LocalizationMetadataIndex({
    required this.referenceLocale,
    required this.entriesByKey,
    required this.entriesByMemberName,
  });

  final String referenceLocale;
  final Map<String, LocalizationEntry> entriesByKey;
  final Map<String, LocalizationEntry> entriesByMemberName;

  static Future<LocalizationMetadataIndex> load(String langDir) async {
    final directory = Directory(langDir);
    if (!directory.existsSync()) {
      throw FileSystemException('Localization directory not found', langDir);
    }

    final localeFiles = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.json'))
        .toList()
      ..sort((left, right) => left.path.compareTo(right.path));

    if (localeFiles.isEmpty) {
      throw FileSystemException('No localization JSON files found', langDir);
    }

    final localeMaps = <String, Map<String, dynamic>>{};
    for (final file in localeFiles) {
      final locale = p.basenameWithoutExtension(file.path);
      final content = await file.readAsString();
      localeMaps[locale] = TranslationFileParser.parseJsonContent(content);
    }

    final referenceLocale = localeMaps.containsKey('en') ? 'en' : localeMaps.keys.first;
    final referenceMap = localeMaps[referenceLocale]!;
    final flattened = _collectGeneratableEntries(referenceMap);
    final memberNameCounts = <String, int>{};
    for (final key in flattened.keys) {
      final memberName = sanitizeDartIdentifier(key);
      memberNameCounts.update(memberName, (value) => value + 1, ifAbsent: () => 1);
    }

    final entriesByKey = <String, LocalizationEntry>{};
    for (final entry in flattened.entries) {
      final keyPath = entry.key;
      final memberName = sanitizeDartIdentifier(keyPath);
      final value = entry.value;
      final kind = _kindFor(value);
      final placeholders = kind == LocalizationEntryKind.parameterizedString
          ? extractPlaceholders(value as String).toList()
          : const <String>[];
      final hasGender = kind == LocalizationEntryKind.plural && _hasGenderAwarePlural(localeMaps, keyPath);
      entriesByKey[keyPath] = LocalizationEntry(
        keyPath: keyPath,
        memberName: memberName,
        kind: kind,
        placeholders: placeholders,
        typedAccessorDeterministic: memberNameCounts[memberName] == 1,
        hasGender: hasGender,
      );
    }

    final entriesByMemberName = <String, LocalizationEntry>{};
    for (final entry in entriesByKey.values) {
      if (!entry.typedAccessorDeterministic) {
        continue;
      }
      entriesByMemberName[entry.memberName] = entry;
    }

    return LocalizationMetadataIndex(
      referenceLocale: referenceLocale,
      entriesByKey: entriesByKey,
      entriesByMemberName: entriesByMemberName,
    );
  }
}

Map<String, dynamic> _collectGeneratableEntries(
  Map<String, dynamic> source, [
  String prefix = '',
]) {
  final output = <String, dynamic>{};
  for (final entry in source.entries) {
    final path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;
    if (value is String) {
      output[path] = value;
      continue;
    }
    if (value is Map<String, dynamic>) {
      if (_isPluralizationMap(value)) {
        output[path] = value;
      } else {
        output.addAll(_collectGeneratableEntries(value, path));
      }
    }
  }
  return output;
}

LocalizationEntryKind _kindFor(dynamic value) {
  if (value is String) {
    return hasPlaceholders(value) ? LocalizationEntryKind.parameterizedString : LocalizationEntryKind.string;
  }
  return LocalizationEntryKind.plural;
}

bool _isPluralizationMap(Map<String, dynamic> value) {
  const pluralKeys = {'zero', 'one', 'two', 'few', 'many', 'other', 'more'};
  return value.keys.any(pluralKeys.contains);
}

bool _hasGenderAwarePlural(
  Map<String, Map<String, dynamic>> localeMaps,
  String keyPath,
) {
  const genderKeys = {'male', 'female', 'masculine', 'feminine'};
  for (final localeMap in localeMaps.values) {
    final value = _getValueByPath(localeMap, keyPath);
    if (value is! Map<String, dynamic>) {
      continue;
    }
    final hasGender = value.values.any((candidate) {
      return candidate is Map<String, dynamic> && candidate.keys.any((genderKey) => genderKeys.contains(genderKey));
    });
    if (hasGender) {
      return true;
    }
  }
  return false;
}

dynamic _getValueByPath(Map<String, dynamic> map, String path) {
  dynamic current = map;
  for (final segment in path.split('.')) {
    if (current is Map<String, dynamic> && current.containsKey(segment)) {
      current = current[segment];
    } else {
      return null;
    }
  }
  return current;
}
