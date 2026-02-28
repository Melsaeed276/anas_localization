library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

enum CatalogFileFormat {
  json,
  yaml,
  csv,
  arb,
}

CatalogFileFormat catalogFileFormatFromString(String value) {
  switch (value.trim().toLowerCase()) {
    case 'json':
      return CatalogFileFormat.json;
    case 'yaml':
    case 'yml':
      return CatalogFileFormat.yaml;
    case 'csv':
      return CatalogFileFormat.csv;
    case 'arb':
      return CatalogFileFormat.arb;
    default:
      throw FormatException('Unsupported catalog format "$value".');
  }
}

String catalogFileFormatToString(CatalogFileFormat format) {
  switch (format) {
    case CatalogFileFormat.json:
      return 'json';
    case CatalogFileFormat.yaml:
      return 'yaml';
    case CatalogFileFormat.csv:
      return 'csv';
    case CatalogFileFormat.arb:
      return 'arb';
  }
}

class CatalogConfig {
  const CatalogConfig({
    required this.version,
    required this.langDir,
    required this.format,
    required this.fallbackLocale,
    required this.sourceLocale,
    required this.stateFile,
    required this.uiPort,
    required this.apiPort,
    required this.openBrowser,
    required this.arbFilePrefix,
  });

  static const String defaultConfigPath = 'anas_catalog.yaml';

  final int version;
  final String langDir;
  final CatalogFileFormat format;
  final String fallbackLocale;
  final String? sourceLocale;
  final String stateFile;
  final int uiPort;
  final int apiPort;
  final bool openBrowser;
  final String arbFilePrefix;

  String get effectiveSourceLocale {
    final source = sourceLocale?.trim();
    if (source == null || source.isEmpty) {
      return fallbackLocale;
    }
    return source;
  }

  String resolveLangDirectory(String projectRootPath) {
    if (p.isAbsolute(langDir)) {
      return p.normalize(langDir);
    }
    return p.normalize(p.join(projectRootPath, langDir));
  }

  String resolveStateFilePath(String projectRootPath) {
    if (p.isAbsolute(stateFile)) {
      return p.normalize(stateFile);
    }
    return p.normalize(p.join(projectRootPath, stateFile));
  }

  CatalogConfig copyWith({
    int? version,
    String? langDir,
    CatalogFileFormat? format,
    String? fallbackLocale,
    String? sourceLocale,
    bool clearSourceLocale = false,
    String? stateFile,
    int? uiPort,
    int? apiPort,
    bool? openBrowser,
    String? arbFilePrefix,
  }) {
    return CatalogConfig(
      version: version ?? this.version,
      langDir: langDir ?? this.langDir,
      format: format ?? this.format,
      fallbackLocale: fallbackLocale ?? this.fallbackLocale,
      sourceLocale: clearSourceLocale ? null : (sourceLocale ?? this.sourceLocale),
      stateFile: stateFile ?? this.stateFile,
      uiPort: uiPort ?? this.uiPort,
      apiPort: apiPort ?? this.apiPort,
      openBrowser: openBrowser ?? this.openBrowser,
      arbFilePrefix: arbFilePrefix ?? this.arbFilePrefix,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'lang_dir': langDir,
      'format': catalogFileFormatToString(format),
      'fallback_locale': fallbackLocale,
      'source_locale': sourceLocale,
      'state_file': stateFile,
      'ui_port': uiPort,
      'api_port': apiPort,
      'open_browser': openBrowser,
      'arb_file_prefix': arbFilePrefix,
    };
  }

  String toYamlString() {
    final sourceLine = sourceLocale ?? 'null';
    return '''
version: $version
lang_dir: $langDir
format: ${catalogFileFormatToString(format)}
fallback_locale: $fallbackLocale
source_locale: $sourceLine
state_file: $stateFile
ui_port: $uiPort
api_port: $apiPort
open_browser: $openBrowser
arb_file_prefix: $arbFilePrefix
''';
  }

  static CatalogConfig defaults() {
    return const CatalogConfig(
      version: 1,
      langDir: 'assets/lang',
      format: CatalogFileFormat.json,
      fallbackLocale: 'en',
      sourceLocale: null,
      stateFile: '.anas_localization/catalog_state.json',
      uiPort: 4466,
      apiPort: 4467,
      openBrowser: true,
      arbFilePrefix: 'app',
    );
  }

  static Future<CatalogConfig> load({
    String path = defaultConfigPath,
  }) async {
    final file = File(path);
    if (!file.existsSync()) {
      return CatalogConfig.defaults();
    }

    final content = await file.readAsString();
    final parsed = loadYaml(content);
    if (parsed is! YamlMap) {
      throw const FormatException('anas_catalog.yaml must be a YAML object.');
    }

    final formatRaw = parsed['format']?.toString() ?? 'json';
    final sourceRaw = parsed['source_locale']?.toString();

    return CatalogConfig(
      version: int.tryParse(parsed['version']?.toString() ?? '') ?? 1,
      langDir: parsed['lang_dir']?.toString() ?? 'assets/lang',
      format: catalogFileFormatFromString(formatRaw),
      fallbackLocale: parsed['fallback_locale']?.toString() ?? 'en',
      sourceLocale: (sourceRaw == null || sourceRaw == 'null' || sourceRaw.trim().isEmpty) ? null : sourceRaw,
      stateFile: parsed['state_file']?.toString() ?? '.anas_localization/catalog_state.json',
      uiPort: int.tryParse(parsed['ui_port']?.toString() ?? '') ?? 4466,
      apiPort: int.tryParse(parsed['api_port']?.toString() ?? '') ?? 4467,
      openBrowser: _parseBool(parsed['open_browser'], fallback: true),
      arbFilePrefix: parsed['arb_file_prefix']?.toString() ?? 'app',
    );
  }

  static Future<void> writeDefault({
    String path = defaultConfigPath,
  }) async {
    final file = File(path);
    if (file.existsSync()) {
      return;
    }

    await file.create(recursive: true);
    await file.writeAsString(CatalogConfig.defaults().toYamlString());
  }
}

bool _parseBool(dynamic value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }
  if (value == null) {
    return fallback;
  }

  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true') return true;
  if (normalized == 'false') return false;
  return fallback;
}
