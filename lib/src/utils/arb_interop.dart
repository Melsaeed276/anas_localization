library;

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

class ArbLocaleDocument {
  const ArbLocaleDocument({
    required this.locale,
    required this.translations,
    required this.metadata,
  });

  final String locale;
  final Map<String, dynamic> translations;
  final Map<String, dynamic> metadata;
}

class L10nYamlConfig {
  const L10nYamlConfig({
    required this.arbDir,
    required this.templateArbFile,
    required this.preferredSupportedLocales,
  });

  final String arbDir;
  final String templateArbFile;
  final List<String> preferredSupportedLocales;
}

class ArbInterop {
  static ArbLocaleDocument parseArb(
    String content, {
    String? fileName,
  }) {
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      throw const FormatException('ARB content must decode to a JSON object.');
    }

    final map = Map<String, dynamic>.from(decoded);
    final locale = _extractLocaleFromArb(map, fileName);
    final metadata = <String, dynamic>{};
    final translations = <String, dynamic>{};

    for (final entry in map.entries) {
      if (entry.key.startsWith('@')) {
        if (entry.key != '@@locale') {
          metadata[entry.key] = entry.value;
        }
        continue;
      }
      translations[entry.key] = entry.value;
    }

    return ArbLocaleDocument(
      locale: locale,
      translations: translations,
      metadata: metadata,
    );
  }

  static String toArbString(
    ArbLocaleDocument document, {
    bool pretty = true,
    bool includeGeneratedMetadata = true,
  }) {
    final map = <String, dynamic>{
      '@@locale': document.locale,
      ...document.translations,
      ...document.metadata,
    };

    if (includeGeneratedMetadata) {
      for (final entry in document.translations.entries) {
        final metadataKey = '@${entry.key}';
        if (map.containsKey(metadataKey)) {
          continue;
        }
        final generated = _generatePlaceholderMetadata(entry.value);
        if (generated != null) {
          map[metadataKey] = generated;
        }
      }
    }

    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return jsonEncode(map);
  }

  static Future<Map<String, ArbLocaleDocument>> readArbDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      throw FileSystemException('ARB directory not found', directoryPath);
    }

    final documents = <String, ArbLocaleDocument>{};
    final files = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.arb'))
        .toList()
      ..sort((left, right) => left.path.compareTo(right.path));

    for (final file in files) {
      final content = await file.readAsString();
      final document = parseArb(
        content,
        fileName: file.uri.pathSegments.last,
      );
      documents[document.locale] = document;
    }

    return documents;
  }

  static Future<Map<String, Map<String, dynamic>>> importArbDirectory(String directoryPath) async {
    final documents = await readArbDirectory(directoryPath);
    return <String, Map<String, dynamic>>{
      for (final entry in documents.entries) entry.key: entry.value.translations,
    };
  }

  static Future<void> exportArbDirectory({
    required Map<String, Map<String, dynamic>> localeData,
    required String outputDirectory,
    String filePrefix = 'app',
    Map<String, Map<String, dynamic>>? metadataByLocale,
  }) async {
    final directory = Directory(outputDirectory);
    await directory.create(recursive: true);

    final locales = localeData.keys.toList()..sort();
    for (final locale in locales) {
      final document = ArbLocaleDocument(
        locale: locale,
        translations: localeData[locale]!,
        metadata: metadataByLocale?[locale] ?? const <String, dynamic>{},
      );
      final file = File('${directory.path}/${filePrefix}_$locale.arb');
      await file.writeAsString(toArbString(document));
    }
  }

  static Future<L10nYamlConfig> parseL10nYaml(String l10nYamlPath) async {
    final file = File(l10nYamlPath);
    if (!file.existsSync()) {
      throw FileSystemException('l10n.yaml not found', l10nYamlPath);
    }

    final content = await file.readAsString();
    final parsed = loadYaml(content);
    if (parsed is! YamlMap) {
      throw const FormatException('l10n.yaml must be a YAML object.');
    }

    final arbDir = parsed['arb-dir']?.toString() ?? 'lib/l10n';
    final templateArbFile = parsed['template-arb-file']?.toString() ?? 'app_en.arb';

    final preferredSupportedLocales = <String>[];
    final rawLocales = parsed['preferred-supported-locales'];
    if (rawLocales is YamlList) {
      preferredSupportedLocales.addAll(rawLocales.map((value) => value.toString()));
    }

    return L10nYamlConfig(
      arbDir: arbDir,
      templateArbFile: templateArbFile,
      preferredSupportedLocales: preferredSupportedLocales,
    );
  }

  static Future<Map<String, Map<String, dynamic>>> importUsingL10nYaml(
    String l10nYamlPath,
  ) async {
    final config = await parseL10nYaml(l10nYamlPath);
    final configFile = File(l10nYamlPath);
    final arbDirectoryPath = configFile.parent.uri.resolve(config.arbDir).toFilePath();
    final imported = await importArbDirectory(arbDirectoryPath);

    if (config.preferredSupportedLocales.isEmpty) {
      return imported;
    }

    return <String, Map<String, dynamic>>{
      for (final locale in config.preferredSupportedLocales)
        if (imported.containsKey(locale)) locale: imported[locale]!,
    };
  }

  static String _sanitizeLocale(String candidate) {
    var trimmed = candidate.trim();
    if (trimmed.isEmpty) {
      return 'en';
    }

    // Reject obvious path traversal and path separator patterns.
    if (trimmed.contains('..') || trimmed.contains('/') || trimmed.contains('\\')) {
      return 'en';
    }

    // Allow only letters, digits, underscore, and hyphen.
    final allowedPattern = RegExp(r'^[A-Za-z0-9_-]+$');
    if (allowedPattern.hasMatch(trimmed)) {
      return trimmed;
    }

    // Strip any disallowed characters; fall back to 'en' if nothing remains.
    trimmed = trimmed.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    if (trimmed.isEmpty) {
      return 'en';
    }

    return trimmed;
  }

  static String _extractLocaleFromArb(Map<String, dynamic> map, String? fileName) {
    final localeFromField = map['@@locale']?.toString();
    if (localeFromField != null && localeFromField.trim().isNotEmpty) {
      return _sanitizeLocale(localeFromField);
    }

    if (fileName == null || fileName.isEmpty) {
      return 'en';
    }

    final normalized = fileName.toLowerCase().endsWith('.arb')
        ? fileName.substring(0, fileName.length - 4)
        : fileName;

    if (normalized.contains('_')) {
      final fromFile = normalized.split('_').last;
      return _sanitizeLocale(fromFile);
    }

    return _sanitizeLocale(normalized);
  }
}

Map<String, dynamic>? _generatePlaceholderMetadata(dynamic value) {
  if (value is! String) {
    return null;
  }

  final placeholderRegExp = RegExp(r'\{([a-zA-Z0-9_]+)(?:[!?])?[\}, ]');
  final placeholders = <String>{};
  for (final match in placeholderRegExp.allMatches('$value ')) {
    final name = match.group(1);
    if (name != null && name.isNotEmpty) {
      placeholders.add(name);
    }
  }

  if (placeholders.isEmpty) {
    return null;
  }

  return {
    'placeholders': {
      for (final placeholder in placeholders) placeholder: {'type': 'Object'},
    },
  };
}
