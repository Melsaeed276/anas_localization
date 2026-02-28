library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'catalog_config.dart';
import 'catalog_models.dart';

class CatalogStateStore {
  const CatalogStateStore();

  Future<CatalogState> load({
    required CatalogConfig config,
    required String projectRootPath,
  }) async {
    final statePath = config.resolveStateFilePath(projectRootPath);
    final file = File(statePath);
    if (!file.existsSync()) {
      return CatalogState.empty(
        sourceLocale: config.effectiveSourceLocale,
        format: catalogFileFormatToString(config.format),
      );
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return CatalogState.empty(
          sourceLocale: config.effectiveSourceLocale,
          format: catalogFileFormatToString(config.format),
        );
      }

      final parsed = CatalogState.fromJson(Map<String, dynamic>.from(decoded));
      parsed.sourceLocale = config.effectiveSourceLocale;
      parsed.format = catalogFileFormatToString(config.format);
      return parsed;
    } catch (_) {
      return CatalogState.empty(
        sourceLocale: config.effectiveSourceLocale,
        format: catalogFileFormatToString(config.format),
      );
    }
  }

  Future<void> save({
    required CatalogConfig config,
    required String projectRootPath,
    required CatalogState state,
  }) async {
    final statePath = config.resolveStateFilePath(projectRootPath);
    final file = File(statePath);
    final directory = Directory(p.dirname(file.path));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    state.sourceLocale = config.effectiveSourceLocale;
    state.format = catalogFileFormatToString(config.format);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(state.toJson()),
    );
  }
}
