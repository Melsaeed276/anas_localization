library;

import 'dart:convert';

import 'catalog_config.dart';
import 'catalog_flatten.dart';
import 'catalog_models.dart';
import 'catalog_repository.dart';
import 'catalog_state_store.dart';
import 'catalog_status_engine.dart';

class CatalogOperationException implements Exception {
  CatalogOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CatalogService {
  CatalogService({
    required this.config,
    required this.projectRootPath,
    CatalogRepository? repository,
    CatalogStateStore? stateStore,
    CatalogStatusEngine? statusEngine,
  })  : _repository = repository ??
            CatalogRepository(
              config: config,
              projectRootPath: projectRootPath,
            ),
        _stateStore = stateStore ?? const CatalogStateStore(),
        _statusEngine = statusEngine ?? const CatalogStatusEngine();

  final CatalogConfig config;
  final String projectRootPath;
  final CatalogRepository _repository;
  final CatalogStateStore _stateStore;
  final CatalogStatusEngine _statusEngine;

  Future<CatalogMeta> loadMeta() async {
    final dataset = await _repository.load();
    return CatalogMeta(
      locales: dataset.locales,
      sourceLocale: config.effectiveSourceLocale,
      fallbackLocale: config.fallbackLocale,
      langDirectory: config.resolveLangDirectory(projectRootPath),
      format: catalogFileFormatToString(config.format),
      stateFilePath: config.resolveStateFilePath(projectRootPath),
      uiPort: config.uiPort,
      apiPort: config.apiPort,
    );
  }

  Future<List<CatalogRow>> loadRows({
    String? search,
    CatalogCellStatus? status,
  }) async {
    final loaded = await _loadAndSyncState();
    final rows = loaded.rows.where((row) {
      if (search != null && search.trim().isNotEmpty) {
        final normalized = search.trim().toLowerCase();
        final keyMatch = row.keyPath.toLowerCase().contains(normalized);
        final valueMatch = row.valuesByLocale.values.any(
          (value) => (value?.toString().toLowerCase() ?? '').contains(normalized),
        );
        if (!keyMatch && !valueMatch) {
          return false;
        }
      }

      if (status != null) {
        final hasStatus = row.cellStates.values.any((cell) => cell.status == status);
        if (!hasStatus) {
          return false;
        }
      }

      return true;
    }).toList();

    rows.sort((a, b) => a.keyPath.compareTo(b.keyPath));
    return rows;
  }

  Future<CatalogSummary> loadSummary() async {
    final rows = await loadRows();
    var greenCount = 0;
    var warningCount = 0;
    var redCount = 0;
    for (final row in rows) {
      for (final cell in row.cellStates.values) {
        switch (cell.status) {
          case CatalogCellStatus.green:
            greenCount++;
            break;
          case CatalogCellStatus.warning:
            warningCount++;
            break;
          case CatalogCellStatus.red:
            redCount++;
            break;
        }
      }
    }
    return CatalogSummary(
      totalKeys: rows.length,
      greenCount: greenCount,
      warningCount: warningCount,
      redCount: redCount,
    );
  }

  Future<CatalogRow> addKey({
    required String keyPath,
    required Map<String, dynamic> valuesByLocale,
    bool markGreenIfComplete = true,
  }) async {
    if (!isValidCatalogKeyPath(keyPath)) {
      throw CatalogOperationException(
        'Invalid key path "$keyPath". Use dot-separated segments with letters, numbers, and underscores.',
      );
    }

    final dataset = await _repository.load();
    final locales = dataset.locales;
    if (locales.isEmpty) {
      throw CatalogOperationException(
        'No locale files found in ${config.resolveLangDirectory(projectRootPath)}.',
      );
    }

    for (final locale in locales) {
      if (catalogHasPath(dataset.translationsByLocale[locale] ?? const <String, dynamic>{}, keyPath)) {
        throw CatalogOperationException('Key "$keyPath" already exists in locale "$locale".');
      }
    }

    for (final locale in locales) {
      final localeMap = dataset.translationsByLocale.putIfAbsent(locale, () => <String, dynamic>{});
      final value = valuesByLocale.containsKey(locale) ? valuesByLocale[locale] : '';
      catalogSetValueByPath(localeMap, keyPath, value ?? '');
    }

    final state = await _stateStore.load(
      config: config,
      projectRootPath: projectRootPath,
    );

    final sourceValue = valuesByLocale[config.effectiveSourceLocale] ?? '';
    final sourceHash = _statusEngine.hashSourceValue(sourceValue);
    final allLocalesFilled =
        markGreenIfComplete && locales.every((locale) => !isCatalogValueEmpty(valuesByLocale[locale] ?? ''));

    state.keys[keyPath] = _statusEngine.newKeyState(
      locales: locales,
      sourceLocale: config.effectiveSourceLocale,
      sourceHash: sourceHash,
      allLocalesFilled: allLocalesFilled,
      now: DateTime.now().toUtc(),
    );

    await _repository.save(dataset);
    await _stateStore.save(
      config: config,
      projectRootPath: projectRootPath,
      state: state,
    );

    return _buildRowForKey(
      keyPath: keyPath,
      locales: locales,
      translationsByLocale: dataset.translationsByLocale,
      state: state,
      now: DateTime.now().toUtc(),
    );
  }

  Future<CatalogRow> updateCell({
    required String keyPath,
    required String locale,
    required dynamic value,
  }) async {
    final loaded = await _loadAndSyncState();
    if (!loaded.locales.contains(locale)) {
      throw CatalogOperationException('Locale "$locale" is not configured.');
    }
    if (!loaded.keyPaths.contains(keyPath)) {
      throw CatalogOperationException('Key "$keyPath" does not exist.');
    }

    final localeMap = loaded.dataset.translationsByLocale[locale]!;
    catalogSetValueByPath(localeMap, keyPath, value);

    final now = DateTime.now().toUtc();
    final sourceLocale = config.effectiveSourceLocale;
    final sourceMap = loaded.dataset.translationsByLocale[sourceLocale] ?? const <String, dynamic>{};
    final sourceValue = catalogGetValueByPath(sourceMap, keyPath);

    final keyState = loaded.state.keys.putIfAbsent(
      keyPath,
      () => CatalogKeyState(sourceHash: '', cells: <String, CatalogCellState>{}),
    );

    if (locale == sourceLocale) {
      keyState.sourceHash = _statusEngine.hashSourceValue(sourceValue);
      keyState.cells[sourceLocale] = _statusEngine.markGreen(
        current: keyState.cells[sourceLocale],
        sourceHash: keyState.sourceHash,
        now: now,
      );
      for (final targetLocale in loaded.locales) {
        if (targetLocale == sourceLocale) {
          continue;
        }
        final targetValue = catalogGetValueByPath(
          loaded.dataset.translationsByLocale[targetLocale] ?? const <String, dynamic>{},
          keyPath,
        );
        keyState.cells[targetLocale] = isCatalogValueEmpty(targetValue)
            ? _statusEngine.markRed(
                current: keyState.cells[targetLocale],
                reason: CatalogStatusReasons.targetMissing,
                now: now,
              )
            : _statusEngine.markWarning(
                current: keyState.cells[targetLocale],
                reason: CatalogStatusReasons.sourceChanged,
                now: now,
              );
      }
    } else {
      if (isCatalogValueEmpty(value)) {
        keyState.cells[locale] = _statusEngine.markRed(
          current: keyState.cells[locale],
          reason: CatalogStatusReasons.targetMissing,
          now: now,
        );
      } else {
        keyState.cells[locale] = _statusEngine.markWarning(
          current: keyState.cells[locale],
          reason: CatalogStatusReasons.targetUpdatedNeedsReview,
          now: now,
        );
      }
    }

    await _repository.save(loaded.dataset);
    await _stateStore.save(
      config: config,
      projectRootPath: projectRootPath,
      state: loaded.state,
    );

    return _buildRowForKey(
      keyPath: keyPath,
      locales: loaded.locales,
      translationsByLocale: loaded.dataset.translationsByLocale,
      state: loaded.state,
      now: now,
    );
  }

  Future<CatalogRow> deleteCell({
    required String keyPath,
    required String locale,
  }) async {
    final loaded = await _loadAndSyncState();
    if (!loaded.locales.contains(locale)) {
      throw CatalogOperationException('Locale "$locale" is not configured.');
    }
    if (!loaded.keyPaths.contains(keyPath)) {
      throw CatalogOperationException('Key "$keyPath" does not exist.');
    }

    final localeMap = loaded.dataset.translationsByLocale[locale]!;
    final removed = catalogRemoveValueByPath(localeMap, keyPath);
    if (!removed) {
      throw CatalogOperationException('Key "$keyPath" does not exist in locale "$locale".');
    }

    final now = DateTime.now().toUtc();
    final sourceLocale = config.effectiveSourceLocale;
    final sourceMap = loaded.dataset.translationsByLocale[sourceLocale] ?? const <String, dynamic>{};
    final sourceValue = catalogGetValueByPath(sourceMap, keyPath);

    final keyState = loaded.state.keys.putIfAbsent(
      keyPath,
      () => CatalogKeyState(sourceHash: '', cells: <String, CatalogCellState>{}),
    );

    if (locale == sourceLocale) {
      keyState.sourceHash = '';
      keyState.cells[sourceLocale] = _statusEngine.markWarning(
        current: keyState.cells[sourceLocale],
        reason: CatalogStatusReasons.sourceDeleted,
        now: now,
      );
      for (final targetLocale in loaded.locales) {
        if (targetLocale == sourceLocale) {
          continue;
        }
        keyState.cells[targetLocale] = _statusEngine.markWarning(
          current: keyState.cells[targetLocale],
          reason: CatalogStatusReasons.sourceDeletedReviewRequired,
          now: now,
        );
      }
    } else {
      keyState.cells[locale] = _statusEngine.markRed(
        current: keyState.cells[locale],
        reason:
            sourceValue == null ? CatalogStatusReasons.sourceDeletedReviewRequired : CatalogStatusReasons.targetMissing,
        now: now,
      );
    }

    await _repository.save(loaded.dataset);
    await _stateStore.save(
      config: config,
      projectRootPath: projectRootPath,
      state: loaded.state,
    );

    return _buildRowForKey(
      keyPath: keyPath,
      locales: loaded.locales,
      translationsByLocale: loaded.dataset.translationsByLocale,
      state: loaded.state,
      now: now,
    );
  }

  Future<void> deleteKey(String keyPath) async {
    final loaded = await _loadAndSyncState();
    for (final locale in loaded.locales) {
      final map = loaded.dataset.translationsByLocale[locale]!;
      catalogRemoveValueByPath(map, keyPath);
    }
    loaded.state.keys.remove(keyPath);

    await _repository.save(loaded.dataset);
    await _stateStore.save(
      config: config,
      projectRootPath: projectRootPath,
      state: loaded.state,
    );
  }

  Future<void> markReviewed({
    required String keyPath,
    required String locale,
  }) async {
    final loaded = await _loadAndSyncState();
    if (!loaded.locales.contains(locale)) {
      throw CatalogOperationException('Locale "$locale" is not configured.');
    }
    if (!loaded.keyPaths.contains(keyPath)) {
      throw CatalogOperationException('Key "$keyPath" does not exist.');
    }

    final value = catalogGetValueByPath(
      loaded.dataset.translationsByLocale[locale] ?? const <String, dynamic>{},
      keyPath,
    );
    if (isCatalogValueEmpty(value)) {
      throw CatalogOperationException(
        'Cannot mark "$keyPath" for "$locale" as reviewed because value is missing.',
      );
    }

    final sourceLocale = config.effectiveSourceLocale;
    final sourceValue = catalogGetValueByPath(
      loaded.dataset.translationsByLocale[sourceLocale] ?? const <String, dynamic>{},
      keyPath,
    );
    final sourceHash = _statusEngine.hashSourceValue(sourceValue);

    final keyState = loaded.state.keys.putIfAbsent(
      keyPath,
      () => CatalogKeyState(sourceHash: sourceHash, cells: <String, CatalogCellState>{}),
    );
    keyState.sourceHash = sourceHash;
    keyState.cells[locale] = _statusEngine.markGreen(
      current: keyState.cells[locale],
      sourceHash: sourceHash,
      now: DateTime.now().toUtc(),
    );

    await _stateStore.save(
      config: config,
      projectRootPath: projectRootPath,
      state: loaded.state,
    );
  }

  Future<_LoadedCatalog> _loadAndSyncState() async {
    final dataset = await _repository.load();
    final state = await _stateStore.load(
      config: config,
      projectRootPath: projectRootPath,
    );
    final locales = dataset.locales;
    final sourceLocale = config.effectiveSourceLocale;
    if (!locales.contains(sourceLocale)) {
      throw CatalogOperationException(
        'Source locale "$sourceLocale" is not found. Update anas_catalog.yaml or locale files.',
      );
    }

    final flatByLocale = <String, Map<String, dynamic>>{};
    for (final locale in locales) {
      flatByLocale[locale] = flattenTranslationMap(dataset.translationsByLocale[locale] ?? const <String, dynamic>{});
    }

    final keyPaths = <String>{};
    for (final map in flatByLocale.values) {
      keyPaths.addAll(map.keys);
    }
    final sortedKeys = keyPaths.toList()..sort();

    var dirty = false;
    final rows = <CatalogRow>[];
    final now = DateTime.now().toUtc();
    for (final keyPath in sortedKeys) {
      final before = jsonEncode(state.keys[keyPath]?.toJson());
      final row = _buildRowForKey(
        keyPath: keyPath,
        locales: locales,
        translationsByLocale: dataset.translationsByLocale,
        state: state,
        now: now,
      );
      final after = jsonEncode(state.keys[keyPath]?.toJson());
      if (before != after) {
        dirty = true;
      }
      rows.add(row);
    }

    final existingKeys = state.keys.keys.toSet();
    for (final stateKey in existingKeys) {
      if (!keyPaths.contains(stateKey)) {
        state.keys.remove(stateKey);
        dirty = true;
      }
    }

    if (dirty) {
      await _stateStore.save(
        config: config,
        projectRootPath: projectRootPath,
        state: state,
      );
    }

    return _LoadedCatalog(
      dataset: dataset,
      state: state,
      locales: locales,
      keyPaths: keyPaths,
      rows: rows,
    );
  }

  CatalogRow _buildRowForKey({
    required String keyPath,
    required List<String> locales,
    required Map<String, Map<String, dynamic>> translationsByLocale,
    required CatalogState state,
    required DateTime now,
  }) {
    final sourceLocale = config.effectiveSourceLocale;
    final valuesByLocale = <String, dynamic>{};
    for (final locale in locales) {
      valuesByLocale[locale] = catalogGetValueByPath(
        translationsByLocale[locale] ?? const <String, dynamic>{},
        keyPath,
      );
    }

    final sourceValue = valuesByLocale[sourceLocale];
    final sourceExists = sourceValue != null;
    final sourceHash = sourceExists ? _statusEngine.hashSourceValue(sourceValue) : '';

    final keyState = state.keys.putIfAbsent(
      keyPath,
      () => CatalogKeyState(
        sourceHash: sourceHash,
        cells: <String, CatalogCellState>{},
      ),
    );

    if (keyState.sourceHash != sourceHash) {
      if (sourceExists) {
        final previousSourceHash = keyState.sourceHash;
        keyState.sourceHash = sourceHash;
        for (final locale in locales) {
          if (locale == sourceLocale) {
            keyState.cells[locale] = _statusEngine.markGreen(
              current: keyState.cells[locale],
              sourceHash: sourceHash,
              now: now,
            );
            continue;
          }
          if (isCatalogValueEmpty(valuesByLocale[locale])) {
            keyState.cells[locale] = _statusEngine.markRed(
              current: keyState.cells[locale],
              reason: CatalogStatusReasons.targetMissing,
              now: now,
            );
            continue;
          }
          keyState.cells[locale] = _statusEngine.markWarning(
            current: keyState.cells[locale],
            reason: previousSourceHash.isEmpty ? CatalogStatusReasons.sourceAdded : CatalogStatusReasons.sourceChanged,
            now: now,
          );
        }
      } else {
        keyState.sourceHash = '';
        for (final locale in locales) {
          keyState.cells[locale] = _statusEngine.markWarning(
            current: keyState.cells[locale],
            reason: locale == sourceLocale
                ? CatalogStatusReasons.sourceDeleted
                : CatalogStatusReasons.sourceDeletedReviewRequired,
            now: now,
          );
        }
      }
    }

    for (final locale in locales) {
      final current = keyState.cells[locale];
      final localeValue = valuesByLocale[locale];
      if (locale != sourceLocale && sourceExists && isCatalogValueEmpty(localeValue)) {
        if (current != null &&
            current.status == CatalogCellStatus.warning &&
            current.reason == CatalogStatusReasons.newKeyNeedsTranslationReview) {
          continue;
        }
        keyState.cells[locale] = _statusEngine.markRed(
          current: current,
          reason: CatalogStatusReasons.targetMissing,
          now: now,
        );
        continue;
      }

      if (current == null) {
        keyState.cells[locale] = locale == sourceLocale
            ? _statusEngine.markGreen(
                current: null,
                sourceHash: sourceHash,
                now: now,
              )
            : _statusEngine.markGreen(
                current: null,
                sourceHash: sourceHash,
                now: now,
              );
      }
    }

    return CatalogRow(
      keyPath: keyPath,
      valuesByLocale: valuesByLocale,
      cellStates: Map<String, CatalogCellState>.from(keyState.cells),
    );
  }
}

class _LoadedCatalog {
  _LoadedCatalog({
    required this.dataset,
    required this.state,
    required this.locales,
    required this.keyPaths,
    required this.rows,
  });

  final CatalogDataset dataset;
  final CatalogState state;
  final List<String> locales;
  final Set<String> keyPaths;
  final List<CatalogRow> rows;
}
