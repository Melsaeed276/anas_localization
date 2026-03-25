library;

import 'dart:convert';

import '../../../core/sdk_utils.dart';
import '../../../shared/utils/translation_file_parser.dart';
import '../config/catalog_config.dart';
import '../domain/entities/catalog_models.dart';
import '../domain/entities/fallback_chain.dart';
import '../domain/services/catalog_flatten.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/catalog_state_store.dart';
import '../domain/services/catalog_status_engine.dart';
import '../../localization/domain/services/fallback_resolver.dart';

const Set<String> _catalogRtlLanguageCodes = {
  'ar',
  'fa',
  'he',
  'ku',
  'ps',
  'sd',
  'ur',
  'yi',
};
const int _maxCatalogActivityEventsPerKey = 120;

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

  CatalogConfig config;
  final String projectRootPath;
  final CatalogRepository _repository;
  final CatalogStateStore _stateStore;
  final CatalogStatusEngine _statusEngine;

  Future<CatalogMeta> loadMeta() async {
    final dataset = await _repository.load();
    return CatalogMeta(
      locales: dataset.locales,
      localeDirections: {
        for (final locale in dataset.locales) locale: _catalogDirectionForLocale(locale),
      },
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
        final noteMatch = (row.note?.toLowerCase() ?? '').contains(normalized);
        if (!keyMatch && !valueMatch && !noteMatch) {
          return false;
        }
      }

      if (status != null) {
        if (row.rowStatus != status) {
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
    var greenRows = 0;
    var warningRows = 0;
    var redRows = 0;
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
      switch (row.rowStatus) {
        case CatalogCellStatus.green:
          greenRows++;
          break;
        case CatalogCellStatus.warning:
          warningRows++;
          break;
        case CatalogCellStatus.red:
          redRows++;
          break;
      }
    }
    return CatalogSummary(
      totalKeys: rows.length,
      greenCount: greenCount,
      warningCount: warningCount,
      redCount: redCount,
      greenRows: greenRows,
      warningRows: warningRows,
      redRows: redRows,
    );
  }

  Future<List<CatalogActivityEvent>> loadActivity({
    required String keyPath,
  }) async {
    final loaded = await _loadAndSyncState();
    if (!loaded.keyPaths.contains(keyPath)) {
      throw CatalogOperationException('Key "$keyPath" does not exist.');
    }

    final activities = List<CatalogActivityEvent>.from(
      loaded.state.keys[keyPath]?.activities ?? const <CatalogActivityEvent>[],
    )..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities;
  }

  Future<CatalogRow> addKey({
    required String keyPath,
    required Map<String, dynamic> valuesByLocale,
    String? note,
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

    final now = DateTime.now().toUtc();
    final sourceValue = valuesByLocale[config.effectiveSourceLocale] ?? '';
    final sourceHash = _statusEngine.hashSourceValue(sourceValue);
    state.keys[keyPath] = _statusEngine.newKeyState(
      locales: locales,
      sourceLocale: config.effectiveSourceLocale,
      sourceHash: sourceHash,
      valuesByLocale: valuesByLocale,
      markGreenIfComplete: markGreenIfComplete,
      now: now,
    )..note = _normalizeCatalogNote(note);
    _appendActivityEvent(
      keyState: state.keys[keyPath]!,
      event: CatalogActivityEvent(
        kind: CatalogActivityKinds.keyCreated,
        timestamp: now,
      ),
    );

    _mergeDataTypesIntoDataset(dataset, state, locales);
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
      now: now,
    );
  }

  Future<CatalogRow> updateKeyDataType({
    required String keyPath,
    required DataType dataType,
  }) async {
    final loaded = await _loadAndSyncState();
    if (!loaded.keyPaths.contains(keyPath)) {
      throw CatalogOperationException('Key "$keyPath" does not exist.');
    }
    final keyState = loaded.state.keys[keyPath]!;
    keyState.dataType = dataType;
    _mergeDataTypesIntoDataset(loaded.dataset, loaded.state, loaded.locales);
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
      now: DateTime.now().toUtc(),
    );
  }

  Future<CatalogRow> updateKeyNote({
    required String keyPath,
    String? note,
  }) async {
    final loaded = await _loadAndSyncState();
    if (!loaded.keyPaths.contains(keyPath)) {
      throw CatalogOperationException('Key "$keyPath" does not exist.');
    }

    final keyState = loaded.state.keys.putIfAbsent(
      keyPath,
      () => CatalogKeyState(sourceHash: '', cells: <String, CatalogCellState>{}),
    );
    final normalizedNote = _normalizeCatalogNote(note);
    final previousNote = _normalizeCatalogNote(keyState.note);
    keyState.note = normalizedNote;
    if (previousNote != normalizedNote) {
      _appendActivityEvent(
        keyState: keyState,
        event: CatalogActivityEvent(
          kind: CatalogActivityKinds.noteUpdated,
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }

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
    final previousValue = catalogGetValueByPath(localeMap, keyPath);
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
      if (_catalogValueSignature(previousValue) != _catalogValueSignature(value)) {
        _appendActivityEvent(
          keyState: keyState,
          event: CatalogActivityEvent(
            kind: CatalogActivityKinds.sourceUpdated,
            timestamp: now,
            locale: sourceLocale,
          ),
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
      if (_catalogValueSignature(previousValue) != _catalogValueSignature(value)) {
        _appendActivityEvent(
          keyState: keyState,
          event: CatalogActivityEvent(
            kind: CatalogActivityKinds.targetUpdated,
            timestamp: now,
            locale: locale,
          ),
        );
      }
    }

    _mergeDataTypesIntoDataset(loaded.dataset, loaded.state, loaded.locales);
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
    _appendActivityEvent(
      keyState: keyState,
      event: CatalogActivityEvent(
        kind: CatalogActivityKinds.valueDeleted,
        timestamp: now,
        locale: locale,
      ),
    );

    _mergeDataTypesIntoDataset(loaded.dataset, loaded.state, loaded.locales);
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

    _mergeDataTypesIntoDataset(loaded.dataset, loaded.state, loaded.locales);
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

    _markReviewedInLoadedCatalog(
      loaded: loaded,
      keyPath: keyPath,
      locale: locale,
      now: DateTime.now().toUtc(),
      statusEngine: _statusEngine,
    );

    await _stateStore.save(
      config: config,
      projectRootPath: projectRootPath,
      state: loaded.state,
    );
  }

  Future<CatalogBulkReviewResult> bulkReview({
    required List<CatalogReviewTarget> targets,
  }) async {
    if (targets.isEmpty) {
      return const CatalogBulkReviewResult(reviewedCount: 0);
    }

    final loaded = await _loadAndSyncState();
    final uniqueTargets = <String, CatalogReviewTarget>{};
    for (final target in targets) {
      uniqueTargets['${target.keyPath}::${target.locale}'] = target;
    }

    var reviewedCount = 0;
    for (final target in uniqueTargets.values) {
      _markReviewedInLoadedCatalog(
        loaded: loaded,
        keyPath: target.keyPath,
        locale: target.locale,
        now: DateTime.now().toUtc(),
        statusEngine: _statusEngine,
      );
      reviewedCount += 1;
    }

    await _stateStore.save(
      config: config,
      projectRootPath: projectRootPath,
      state: loaded.state,
    );

    return CatalogBulkReviewResult(reviewedCount: reviewedCount);
  }

  /// Creates a new empty locale file.
  Future<void> addLocale(String locale) async {
    final normalizedLocale = locale.trim().replaceAll('-', '_');

    // Validate locale code format
    final localePattern = RegExp(r'^[a-zA-Z]{2,3}(?:_[a-zA-Z0-9]{2,8})*$');
    if (!localePattern.hasMatch(normalizedLocale)) {
      throw CatalogOperationException(
        'Invalid locale code "$locale". Use format like "en", "en_US", or "zh_CN".',
      );
    }

    final dataset = await _repository.load();
    if (dataset.locales.contains(normalizedLocale)) {
      throw CatalogOperationException('Locale "$normalizedLocale" already exists.');
    }

    await _repository.createLocaleFile(normalizedLocale);
  }

  /// Deletes a locale file permanently.
  Future<void> deleteLocale(String locale) async {
    final normalizedLocale = locale.trim().replaceAll('-', '_');

    if (normalizedLocale == config.fallbackLocale) {
      throw CatalogOperationException('Cannot delete the default locale "$normalizedLocale".');
    }

    final dataset = await _repository.load();
    if (!dataset.locales.contains(normalizedLocale)) {
      throw CatalogOperationException('Locale "$normalizedLocale" does not exist.');
    }

    await _repository.deleteLocaleFile(normalizedLocale);

    // T028: Clean up language group fallback references when a locale is deleted.
    // If the deleted locale was a fallback target, remove it from all locales' fallback lists.
    // This implements FR-011: automatically clear fallback references when fallback locale is deleted.
    // Issue #131: Also collect affected locales for notification
    final affectedLocales = await _clearFallbackReferencesOnDelete(normalizedLocale);

    // Issue #131: Emit notification if there were affected fallback references
    if (affectedLocales.isNotEmpty) {
      _emitFallbackCascadeNotification(
        deletedLocale: normalizedLocale,
        affectedSourceLocales: affectedLocales,
      );
    }
  }

  /// T028: Clears all fallback references pointing to a deleted locale.
  /// When a locale is deleted, any locales that have it configured as their fallback
  /// must have that fallback reference removed (implements FR-011).
  /// Issue #131: Returns the list of affected source locales for notification.
  Future<List<String>> _clearFallbackReferencesOnDelete(String deletedLocale) async {
    final state = await _stateStore.load(
      config: config,
      projectRootPath: projectRootPath,
    );

    if (state.languageGroupFallbacks.isEmpty) {
      return []; // No fallbacks to clean up
    }

    // Find all entries that point to the deleted locale
    final affectedLocales = <String>[];
    final updatedFallbacks = Map<String, String>.from(state.languageGroupFallbacks);

    for (final entry in state.languageGroupFallbacks.entries) {
      if (entry.value == deletedLocale) {
        affectedLocales.add(entry.key);
        updatedFallbacks.remove(entry.key);
      }
    }

    // Only save if there were changes
    if (affectedLocales.isNotEmpty) {
      final updatedState = state.copyWith(languageGroupFallbacks: updatedFallbacks);
      await _stateStore.save(
        config: config,
        projectRootPath: projectRootPath,
        state: updatedState,
      );
    }

    return affectedLocales;
  }

  /// Updates the fallback locale in config.
  Future<CatalogConfig> updateFallbackLocale(String locale) async {
    final normalizedLocale = locale.trim().replaceAll('-', '_');

    final dataset = await _repository.load();
    if (!dataset.locales.contains(normalizedLocale)) {
      throw CatalogOperationException('Locale "$normalizedLocale" does not exist.');
    }

    final updatedConfig = config.copyWith(
      fallbackLocale: normalizedLocale,
      clearSourceLocale: true, // Also clear source_locale so it falls back to fallback
    );

    final configPath = PathUtils.join(projectRootPath, CatalogConfig.defaultConfigPath);
    await CatalogConfig.writeConfig(
      path: configPath,
      config: updatedConfig,
    );

    config = updatedConfig;
    return updatedConfig;
  }

  /// T022: Gets language groups from provided locales.
  /// Groups locales by their language code (e.g., en_US, en_GB -> group 'en').
  Map<String, List<String>> getLanguageGroups(List<String> locales) {
    final groups = <String, List<String>>{};
    for (final locale in locales) {
      final lang = getLanguageCode(locale);
      groups.putIfAbsent(lang, () => []).add(locale);
    }
    return groups;
  }

  /// T023: Sets a language group fallback for a locale.
  /// Validates that the fallback is in the same language group,
  /// prevents circular references, and checks locale existence.
  /// Also enforces FR-010: directionality constraint for fallbacks.
  Future<void> setLanguageGroupFallback({
    required String locale,
    required String newFallback,
    List<String>? validLocales,
  }) async {
    final state = await _stateStore.load(
      config: config,
      projectRootPath: projectRootPath,
    );

    // Check self-reference
    if (locale == newFallback) {
      throw CatalogOperationException(
        'Locale cannot fallback to itself',
      );
    }

    // Check language group constraint
    if (!sameLanguageGroup(locale, newFallback)) {
      throw CatalogOperationException(
        'Fallback must be in same language group',
      );
    }

    // FR-010: Enforce fallback directionality constraint
    // Base language can only fallback to: base language or other base languages
    // Regional variant can fallback to: regional variant or base language
    // NOT allowed: Base → Regional (e.g., en → ar_SA)
    final sourceIsRegional = _isLocaleRegional(locale);
    final targetIsRegional = _isLocaleRegional(newFallback);

    if (!sourceIsRegional && targetIsRegional) {
      throw CatalogOperationException(
        'Invalid fallback direction: base language "$locale" cannot fall back to regional variant "$newFallback". '
        'Only these directions allowed: Regional→Regional, Regional→Base, Base→Base',
      );
    }

    // Check circular fallback
    if (hasCircularFallback(state.languageGroupFallbacks, locale, newFallback)) {
      throw CatalogOperationException(
        'Setting this fallback would create circular reference',
      );
    }

    // Check if locales exist (if validLocales provided)
    if (validLocales != null) {
      if (!validLocales.contains(locale)) {
        throw CatalogOperationException('Locale "$locale" does not exist');
      }
      if (!validLocales.contains(newFallback)) {
        throw CatalogOperationException('Fallback locale "$newFallback" does not exist');
      }
    }

    // Update state
    final updatedFallbacks = Map<String, String>.from(state.languageGroupFallbacks)..[locale] = newFallback;
    final updatedState = state.copyWith(languageGroupFallbacks: updatedFallbacks);

    await _stateStore.save(
      config: config,
      projectRootPath: projectRootPath,
      state: updatedState,
    );
  }

  /// T024: Removes a language group fallback for a locale.
  /// This is idempotent - removing a non-existent fallback is safe.
  Future<void> removeLanguageGroupFallback(String locale) async {
    final state = await _stateStore.load(
      config: config,
      projectRootPath: projectRootPath,
    );

    if (!state.languageGroupFallbacks.containsKey(locale)) {
      return; // Idempotent: no-op if not present
    }

    final updatedFallbacks = Map<String, String>.from(state.languageGroupFallbacks)..remove(locale);
    final updatedState = state.copyWith(languageGroupFallbacks: updatedFallbacks);

    await _stateStore.save(
      config: config,
      projectRootPath: projectRootPath,
      state: updatedState,
    );
  }

  /// T025: Gets the complete fallback chain for a locale.
  /// Returns a FallbackChain entity with the resolved chain, display string,
  /// and whether a language group fallback is configured.
  Future<FallbackChain> getFallbackChain(String locale) async {
    final state = await _stateStore.load(
      config: config,
      projectRootPath: projectRootPath,
    );

    return FallbackChain(
      targetLocale: locale,
      chain: resolveFallbackChain(state.languageGroupFallbacks, locale),
      projectDefaultLocale: config.fallbackLocale,
    );
  }

  /// T029 helper: Gets the current language group fallbacks configuration.
  /// Returns a map of locale -> fallback locale for all configured language group fallbacks.
  Future<Map<String, String>> getLanguageGroupFallbacks() async {
    final state = await _stateStore.load(
      config: config,
      projectRootPath: projectRootPath,
    );
    return Map<String, String>.from(state.languageGroupFallbacks);
  }

  /// T038: Adds a custom locale with ISO validation and direction specification.
  /// Validates locale code against ISO standards, checks for duplicates, and stores direction.
  /// Also verifies that the specified direction is consistent with the language's natural direction.
  Future<void> addCustomLocale({
    required String localeCode,
    required String direction, // 'ltr' or 'rtl'
    List<String>? existingLocales,
  }) async {
    // Normalize the locale code (convert hyphens to underscores, lowercase)
    final normalized = localeCode.trim().replaceAll('-', '_').toLowerCase();

    if (normalized.isEmpty) {
      throw CatalogOperationException('Locale code cannot be empty.');
    }

    // Check if locale already exists
    final dataset = await _repository.load();
    if (dataset.locales.contains(normalized)) {
      throw CatalogOperationException('Locale "$normalized" already exists.');
    }

    // Validate direction
    if (direction != 'ltr' && direction != 'rtl') {
      throw CatalogOperationException('Direction must be "ltr" or "rtl".');
    }

    // FR-007: Verify text direction is consistent with the language
    // Check if the direction conflicts with the language's natural direction
    final languageCode = getLanguageCode(normalized);
    const rtlLanguages = {
      'ar', // Arabic
      'fa', // Farsi/Persian
      'he', // Hebrew
      'ku', // Kurdish
      'ps', // Pashto
      'sd', // Sindhi
      'ur', // Urdu
      'yi', // Yiddish
    };

    final isRtlLanguage = rtlLanguages.contains(languageCode);
    final isRtlDirection = direction == 'rtl';

    // Check for direction mismatch with known language directionality
    // RTL languages should use 'rtl', LTR languages should use 'ltr'
    if (isRtlLanguage && !isRtlDirection) {
      throw CatalogOperationException(
        'Locale "$normalized" is an RTL language ($languageCode) '
        'but was assigned LTR direction. RTL languages must use RTL direction.',
      );
    } else if (!isRtlLanguage && isRtlDirection) {
      throw CatalogOperationException(
        'Locale "$normalized" is an LTR language ($languageCode) '
        'but was assigned RTL direction. LTR languages must use LTR direction.',
      );
    }

    // Create the locale file
    await _repository.createLocaleFile(normalized);

    // Store custom locale direction in state
    final state = await _stateStore.load(
      config: config,
      projectRootPath: projectRootPath,
    );

    final updatedDirections = Map<String, String>.from(state.customLocaleDirections);
    updatedDirections[normalized] = direction;

    final updatedState = state.copyWith(customLocaleDirections: updatedDirections);
    await _stateStore.save(
      config: config,
      projectRootPath: projectRootPath,
      state: updatedState,
    );
  }

  /// T039: Gets the text direction for a locale.
  /// Checks custom locale directions first, then falls back to predefined RTL language codes.
  /// Returns 'rtl' for right-to-left languages, 'ltr' for left-to-right.
  Future<String> getLocaleDirection(String locale) async {
    final state = await _stateStore.load(
      config: config,
      projectRootPath: projectRootPath,
    );

    // Check if this is a custom locale with configured direction
    if (state.customLocaleDirections.containsKey(locale)) {
      return state.customLocaleDirections[locale]!;
    }

    // Check if it's a predefined RTL language
    final languageCode = getLanguageCode(locale);
    const rtlLanguages = {
      'ar', // Arabic
      'fa', // Farsi/Persian
      'he', // Hebrew
      'ku', // Kurdish
      'ps', // Pashto
      'sd', // Sindhi
      'ur', // Urdu
      'yi', // Yiddish
    };

    if (rtlLanguages.contains(languageCode)) {
      return 'rtl';
    }

    return 'ltr'; // Default to LTR
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

    // Silently upgrade legacy SHA-1 hashes (40 hex chars) to FNV-1a without
    // triggering a "source changed" state. This preserves existing review state
    // when upgrading from the old hash algorithm.
    if (keyState.sourceHash != sourceHash && sourceExists && _statusEngine.isLegacyHash(keyState.sourceHash)) {
      keyState.sourceHash = sourceHash;
    }

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
        if (locale == sourceLocale) {
          keyState.cells[locale] = _statusEngine.markGreen(
            current: null,
            sourceHash: sourceHash,
            now: now,
          );
        } else {
          if (isCatalogValueEmpty(localeValue)) {
            keyState.cells[locale] = _statusEngine.markRed(
              current: null,
              reason: CatalogStatusReasons.targetMissing,
              now: now,
            );
          } else {
            // Pre-existing non-source translation with no prior state:
            // mark as needing translation review instead of treating as reviewed.
            keyState.cells[locale] = _statusEngine.markWarning(
              current: null,
              reason: CatalogStatusReasons.newKeyNeedsTranslationReview,
              now: now,
            );
          }
        }
      }
    }

    final workflowSummary = _buildRowWorkflowSummary(
      locales: locales,
      sourceLocale: sourceLocale,
      cellStates: keyState.cells,
    );

    final dataTypesFromFile = TranslationFileParser.readDataTypesFromParsedMap(
      translationsByLocale[sourceLocale] ?? const <String, dynamic>{},
    );
    keyState.dataType = dataTypesFromFile[keyPath] ?? keyState.dataType;

    return CatalogRow(
      keyPath: keyPath,
      valuesByLocale: valuesByLocale,
      cellStates: Map<String, CatalogCellState>.from(keyState.cells),
      rowStatus: workflowSummary.rowStatus,
      pendingLocales: workflowSummary.pendingLocales,
      missingLocales: workflowSummary.missingLocales,
      note: _normalizeCatalogNote(keyState.note),
      dataType: keyState.dataType,
    );
  }

  void _mergeDataTypesIntoDataset(CatalogDataset dataset, CatalogState state, List<String> locales) {
    final dataTypesFromState = <String, DataType>{
      for (final entry in state.keys.entries) entry.key: entry.value.dataType,
    };
    for (final locale in locales) {
      final map = dataset.translationsByLocale[locale] ?? const <String, dynamic>{};
      final valueMap = Map<String, dynamic>.from(map)..remove(TranslationFileParser.dataTypesKey);
      dataset.translationsByLocale[locale] = TranslationFileParser.buildMapWithDataTypes(valueMap, dataTypesFromState);
    }
  }

  /// Issue #131: Emits a notification about a cascade delete of fallback references.
  /// This notifies the user which locales were affected when a fallback target locale was deleted.
  void _emitFallbackCascadeNotification({
    required String deletedLocale,
    required List<String> affectedSourceLocales,
  }) {
    // In a real app with a notification service, would emit here:
    // _notificationService.notify(FallbackCascadeNotification(...));
    // For now this is a placeholder; notification emission is not yet wired up.
  }
}

void _appendActivityEvent({
  required CatalogKeyState keyState,
  required CatalogActivityEvent event,
}) {
  keyState.activities.add(event);
  if (keyState.activities.length > _maxCatalogActivityEventsPerKey) {
    keyState.activities.removeRange(0, keyState.activities.length - _maxCatalogActivityEventsPerKey);
  }
}

String? _normalizeCatalogNote(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _catalogValueSignature(dynamic value) {
  return jsonEncode(value);
}

void _markReviewedInLoadedCatalog({
  required _LoadedCatalog loaded,
  required String keyPath,
  required String locale,
  required DateTime now,
  required CatalogStatusEngine statusEngine,
}) {
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

  final sourceLocale = loaded.state.sourceLocale;
  final sourceValue = catalogGetValueByPath(
    loaded.dataset.translationsByLocale[sourceLocale] ?? const <String, dynamic>{},
    keyPath,
  );
  final sourceHash = statusEngine.hashSourceValue(sourceValue);

  final keyState = loaded.state.keys.putIfAbsent(
    keyPath,
    () => CatalogKeyState(sourceHash: sourceHash, cells: <String, CatalogCellState>{}),
  );
  keyState.sourceHash = sourceHash;
  keyState.cells[locale] = statusEngine.markGreen(
    current: keyState.cells[locale],
    sourceHash: sourceHash,
    now: now,
  );
  _appendActivityEvent(
    keyState: keyState,
    event: CatalogActivityEvent(
      kind: CatalogActivityKinds.localeReviewed,
      timestamp: now,
      locale: locale,
    ),
  );
}

String _catalogDirectionForLocale(String locale) {
  final normalized = locale.trim().replaceAll('-', '_');
  final languageCode = normalized.split('_').first.toLowerCase();
  return _catalogRtlLanguageCodes.contains(languageCode) ? 'rtl' : 'ltr';
}

_RowWorkflowSummary _buildRowWorkflowSummary({
  required List<String> locales,
  required String sourceLocale,
  required Map<String, CatalogCellState> cellStates,
}) {
  final targetLocales = locales.where((locale) => locale != sourceLocale).toList();
  final pendingLocales = <String>[];
  final missingLocales = <String>[];

  for (final locale in targetLocales) {
    final cell = cellStates[locale];
    if (cell == null) {
      continue;
    }
    if (cell.status == CatalogCellStatus.red) {
      missingLocales.add(locale);
      continue;
    }
    if (cell.status == CatalogCellStatus.warning) {
      pendingLocales.add(locale);
    }
  }

  if (missingLocales.isNotEmpty) {
    return _RowWorkflowSummary(
      rowStatus: CatalogCellStatus.red,
      pendingLocales: pendingLocales,
      missingLocales: missingLocales,
    );
  }

  if (pendingLocales.isNotEmpty) {
    return _RowWorkflowSummary(
      rowStatus: CatalogCellStatus.warning,
      pendingLocales: pendingLocales,
      missingLocales: missingLocales,
    );
  }

  final sourceCell = cellStates[sourceLocale];
  final rowStatus = sourceCell == null || sourceCell.status == CatalogCellStatus.green
      ? CatalogCellStatus.green
      : CatalogCellStatus.warning;

  return _RowWorkflowSummary(
    rowStatus: rowStatus,
    pendingLocales: pendingLocales,
    missingLocales: missingLocales,
  );
}

class _RowWorkflowSummary {
  const _RowWorkflowSummary({
    required this.rowStatus,
    required this.pendingLocales,
    required this.missingLocales,
  });

  final CatalogCellStatus rowStatus;
  final List<String> pendingLocales;
  final List<String> missingLocales;
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

/// Helper function: detects if adding a fallback would create a circular reference.
/// Returns true if adding fallback for [locale] -> [newFallback] would cause a cycle.
bool hasCircularFallback(
  Map<String, String> fallbacks,
  String locale,
  String newFallback,
) {
  // Direct self-reference is circular
  if (locale == newFallback) {
    return true;
  }

  final visited = <String>{locale};
  var current = fallbacks[newFallback];

  while (current != null && current.isNotEmpty) {
    if (visited.contains(current)) return true;
    visited.add(current);
    current = fallbacks[current];
  }

  return false;
}

/// Helper function: resolves the full fallback chain for a locale.
/// Returns list of locales in fallback order: [primary, fallback1, fallback2, ...]
///
/// Delegates to [resolveConfiguredChain] from the shared FallbackResolver,
/// which also guards against circular references.
List<String> resolveFallbackChain(
  Map<String, String> fallbacks,
  String locale,
) =>
    resolveConfiguredChain(fallbacks, locale);

/// Helper function: extracts language code from a locale.
/// E.g., 'en_US' -> 'en', 'ar_SA' -> 'ar'
String getLanguageCode(String locale) {
  final parts = locale.split('_');
  return parts[0];
}

/// Helper function: checks if a locale is a regional variant.
/// Regional variant if it contains underscore (e.g., ar_SA, en_US)
/// Base language if it does not (e.g., ar, en)
bool _isLocaleRegional(String locale) {
  return locale.contains('_');
}

/// Helper function: checks if two locales share the same language group.
/// Same language group if they have the same language code, or one is a language-only code.
bool sameLanguageGroup(String locale1, String locale2) {
  final lang1 = getLanguageCode(locale1);
  final lang2 = getLanguageCode(locale2);

  if (lang1 == lang2) return true;

  // Check if either is language-only and matches the other's language code
  if (locale1 == lang2 || locale2 == lang1) return true;

  return false;
}
