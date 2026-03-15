import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/utils/translation_validator.dart';
import '../../client/catalog_client.dart';
import '../../domain/entities/catalog_models.dart';
import '../../domain/services/catalog_flatten.dart';
import '../../l10n/l10n/generated/catalog_localizations.dart';
import '../controllers/catalog_ui_logic.dart';
import 'catalog_ui_enums.dart';

const String _catalogQueueSortModeStorageKey = 'anasCatalog.queueSortMode';
const String _catalogCollapsedSectionsStorageKey = 'anasCatalog.collapsedSections';
const String _catalogLastSelectedLocaleStorageKey = 'anasCatalog.lastSelectedLocale';

class CatalogWorkspacePreferencesController extends ChangeNotifier {
  CatalogQueueSortMode _sortMode = CatalogQueueSortMode.alphabetical;
  Set<CatalogQueueSection> _collapsedSections = <CatalogQueueSection>{};
  String? _lastSelectedLocale;
  bool _loaded = false;

  CatalogQueueSortMode get sortMode => _sortMode;
  Set<CatalogQueueSection> get collapsedSections => _collapsedSections;
  String? get lastSelectedLocale => _lastSelectedLocale;
  bool get loaded => _loaded;

  Future<void> load() async {
    final storage = await SharedPreferences.getInstance();
    _sortMode = switch (storage.getString(_catalogQueueSortModeStorageKey)) {
      'namespace' => CatalogQueueSortMode.namespace,
      _ => CatalogQueueSortMode.alphabetical,
    };
    _collapsedSections = storage
            .getStringList(_catalogCollapsedSectionsStorageKey)
            ?.map(_queueSectionFromStorage)
            .whereType<CatalogQueueSection>()
            .toSet() ??
        <CatalogQueueSection>{};
    final storedLocale = storage.getString(_catalogLastSelectedLocaleStorageKey);
    _lastSelectedLocale = storedLocale == null || storedLocale.trim().isEmpty ? null : storedLocale.trim();
    _loaded = true;
    notifyListeners();
  }

  bool isSectionCollapsed(CatalogQueueSection section) => _collapsedSections.contains(section);

  Future<void> setSortMode(CatalogQueueSortMode mode) async {
    if (_sortMode == mode) {
      return;
    }
    _sortMode = mode;
    notifyListeners();
    final storage = await SharedPreferences.getInstance();
    await storage.setString(
      _catalogQueueSortModeStorageKey,
      switch (mode) {
        CatalogQueueSortMode.alphabetical => 'alphabetical',
        CatalogQueueSortMode.namespace => 'namespace',
      },
    );
  }

  Future<void> setSectionCollapsed(CatalogQueueSection section, bool collapsed) async {
    final next = Set<CatalogQueueSection>.from(_collapsedSections);
    if (collapsed) {
      next.add(section);
    } else {
      next.remove(section);
    }
    if (next.length == _collapsedSections.length && next.containsAll(_collapsedSections)) {
      return;
    }
    _collapsedSections = next;
    notifyListeners();
    final storage = await SharedPreferences.getInstance();
    await storage.setStringList(
      _catalogCollapsedSectionsStorageKey,
      _collapsedSections.map((item) => item.storageValue).toList()..sort(),
    );
  }

  Future<void> setLastSelectedLocale(String? locale) async {
    final normalized = locale?.trim();
    final next = (normalized == null || normalized.isEmpty) ? null : normalized;
    if (_lastSelectedLocale == next) {
      return;
    }
    _lastSelectedLocale = next;
    notifyListeners();
    final storage = await SharedPreferences.getInstance();
    if (next == null) {
      await storage.remove(_catalogLastSelectedLocaleStorageKey);
    } else {
      await storage.setString(_catalogLastSelectedLocaleStorageKey, next);
    }
  }
}

class CatalogQueueController extends ChangeNotifier {
  CatalogQueueController({
    required CatalogApiClient client,
    required CatalogWorkspacePreferencesController preferences,
  })  : _client = client,
        _preferences = preferences {
    _preferences.addListener(_handlePreferencesChanged);
  }

  final CatalogApiClient _client;
  final CatalogWorkspacePreferencesController _preferences;

  CatalogMeta? _meta;
  CatalogSummary? _summary;
  List<CatalogRow> _rows = <CatalogRow>[];
  String _search = '';
  CatalogRowStatusFilter _statusFilter = CatalogRowStatusFilter.all;
  String? _error;
  bool _loading = false;
  bool _initialized = false;
  Timer? _searchTimer;
  int _requestGeneration = 0;

  CatalogMeta? get meta => _meta;
  CatalogSummary? get summary => _summary;
  List<CatalogRow> get rows => _rows;
  String get search => _search;
  CatalogRowStatusFilter get statusFilter => _statusFilter;
  CatalogQueueSortMode get sortMode => _preferences.sortMode;
  String? get error => _error;
  bool get loading => _loading;
  bool get initialized => _initialized;
  bool get hasAnyKeys => (_summary?.totalKeys ?? 0) > 0 || _rows.isNotEmpty;
  bool get hasQuery => _search.trim().isNotEmpty || _statusFilter != CatalogRowStatusFilter.all;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await refresh();
    _initialized = true;
    notifyListeners();
  }

  Future<void> refresh({bool reloadMeta = false}) async {
    final requestGeneration = ++_requestGeneration;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (_meta == null || reloadMeta) {
        _meta = await _client.loadMeta();
      }
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _client.loadRows(
          search: _search,
          status: _statusFilter.apiValue,
        ),
        _client.loadSummary(),
      ]);
      if (requestGeneration != _requestGeneration) {
        return;
      }
      _rows = List<CatalogRow>.from(results[0] as List<CatalogRow>);
      _summary = results[1] as CatalogSummary;
      _sortRows();
      _error = null;
    } catch (error) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      _error = error.toString();
    } finally {
      if (requestGeneration == _requestGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void updateSearch(String value) {
    _search = value;
    notifyListeners();
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 250), () {
      refresh();
    });
  }

  Future<void> updateStatusFilter(CatalogRowStatusFilter filter) async {
    if (_statusFilter == filter) {
      return;
    }
    _statusFilter = filter;
    notifyListeners();
    await refresh();
  }

  Future<void> updateSortMode(CatalogQueueSortMode mode) async {
    await _preferences.setSortMode(mode);
    _sortRows();
    notifyListeners();
  }

  Future<void> setSectionCollapsed(CatalogQueueSection section, bool collapsed) async {
    await _preferences.setSectionCollapsed(section, collapsed);
  }

  bool isSectionCollapsed(CatalogQueueSection section) => _preferences.isSectionCollapsed(section);

  CatalogRow? rowByKey(String keyPath) {
    for (final row in _rows) {
      if (row.keyPath == keyPath) {
        return row;
      }
    }
    return null;
  }

  List<CatalogQueueSection> get visibleSections {
    final sections = <CatalogQueueSection>[];
    for (final section in CatalogQueueSection.values) {
      if (_statusFilter != CatalogRowStatusFilter.all && section != _queueSectionForStatusFilter(_statusFilter)) {
        continue;
      }
      sections.add(section);
    }
    return sections;
  }

  List<CatalogRow> rowsForSection(CatalogQueueSection section) {
    final rows = _rows.where((row) => _sectionForRow(row) == section).toList();
    _sortRows(rows);
    return rows;
  }

  int sectionCount(CatalogQueueSection section) => rowsForSection(section).length;

  String namespaceForKey(String keyPath) {
    final segments = keyPath.split('.');
    return segments.isEmpty ? keyPath : segments.first;
  }

  void upsertRow(CatalogRow row) {
    final index = _rows.indexWhere((item) => item.keyPath == row.keyPath);
    if (index >= 0) {
      _rows[index] = row;
    } else {
      _rows.add(row);
    }
    _sortRows();
    notifyListeners();
  }

  void removeKey(String keyPath) {
    _rows.removeWhere((row) => row.keyPath == keyPath);
    notifyListeners();
  }

  Future<void> refreshSummary() async {
    _summary = await _client.loadSummary();
    notifyListeners();
  }

  CatalogQueueSection _sectionForRow(CatalogRow row) {
    return switch (row.rowStatus) {
      CatalogCellStatus.red => CatalogQueueSection.missing,
      CatalogCellStatus.warning => CatalogQueueSection.needsReview,
      CatalogCellStatus.green => CatalogQueueSection.ready,
    };
  }

  void _sortRows([List<CatalogRow>? rows]) {
    final target = rows ?? _rows;
    target.sort((a, b) {
      switch (_preferences.sortMode) {
        case CatalogQueueSortMode.alphabetical:
          return a.keyPath.compareTo(b.keyPath);
        case CatalogQueueSortMode.namespace:
          final namespaceCompare = namespaceForKey(a.keyPath).compareTo(namespaceForKey(b.keyPath));
          if (namespaceCompare != 0) {
            return namespaceCompare;
          }
          return a.keyPath.compareTo(b.keyPath);
      }
    });
  }

  void _handlePreferencesChanged() {
    _sortRows();
    notifyListeners();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _preferences.removeListener(_handlePreferencesChanged);
    super.dispose();
  }
}

class CatalogSelectionController extends ChangeNotifier {
  CatalogSelectionController({
    required CatalogWorkspacePreferencesController preferences,
  }) : _preferences = preferences;

  final CatalogWorkspacePreferencesController _preferences;

  String? _selectedKey;
  String? _selectedLocale;
  bool _selectionExplicit = false;

  String? get selectedKey => _selectedKey;
  String? get selectedLocale => _selectedLocale;
  bool get compactDetailOpen => _selectionExplicit && _selectedKey != null;

  CatalogRow? selectedRow(List<CatalogRow> rows) {
    final key = _selectedKey;
    if (key == null) {
      return null;
    }
    for (final row in rows) {
      if (row.keyPath == key) {
        return row;
      }
    }
    return null;
  }

  String defaultEditorLocale(CatalogMeta? meta) {
    if (meta == null) {
      return '';
    }
    final preferred = _preferences.lastSelectedLocale;
    if (preferred != null && meta.locales.contains(preferred)) {
      return preferred;
    }
    return meta.locales.firstWhere(
      (locale) => locale != meta.sourceLocale,
      orElse: () => meta.sourceLocale,
    );
  }

  void sync({
    required List<CatalogRow> rows,
    required CatalogMeta? meta,
  }) {
    var changed = false;
    if (rows.isEmpty) {
      if (_selectedKey != null) {
        _selectedKey = null;
        changed = true;
      }
      if (_selectionExplicit) {
        _selectionExplicit = false;
        changed = true;
      }
      final fallbackLocale = defaultEditorLocale(meta);
      if (_selectedLocale != fallbackLocale) {
        _selectedLocale = fallbackLocale;
        changed = true;
      }
      if (changed) {
        notifyListeners();
      }
      return;
    }

    final currentKey = _selectedKey;
    if (currentKey == null || !rows.any((row) => row.keyPath == currentKey)) {
      _selectedKey = rows.first.keyPath;
      _selectionExplicit = false;
      changed = true;
    }

    final locales = meta?.locales ?? const <String>[];
    if (_selectedLocale == null || !locales.contains(_selectedLocale)) {
      _selectedLocale = defaultEditorLocale(meta);
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void openRow(String keyPath) {
    if (_selectedKey == keyPath) {
      if (!_selectionExplicit) {
        _selectionExplicit = true;
        notifyListeners();
      }
      return;
    }
    _selectedKey = keyPath;
    _selectionExplicit = true;
    notifyListeners();
  }

  void clearCompactDetail() {
    if (!_selectionExplicit) {
      return;
    }
    _selectionExplicit = false;
    notifyListeners();
  }

  Future<void> selectLocale(String locale) async {
    if (_selectedLocale == locale) {
      return;
    }
    _selectedLocale = locale;
    notifyListeners();
    await _preferences.setLastSelectedLocale(locale);
  }

  void revealSelection() {
    if (_selectedKey != null && !_selectionExplicit) {
      _selectionExplicit = true;
      notifyListeners();
    }
  }
}

class CatalogActivityController extends ChangeNotifier {
  CatalogActivityController({
    required CatalogApiClient client,
  }) : _client = client;

  final CatalogApiClient _client;

  String? _keyPath;
  List<CatalogActivityEvent> _events = <CatalogActivityEvent>[];
  bool _loading = false;
  String? _error;
  int _requestGeneration = 0;

  String? get keyPath => _keyPath;
  List<CatalogActivityEvent> get events => _events;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> showKey(String? keyPath) async {
    if (_keyPath == keyPath) {
      return;
    }
    _keyPath = keyPath;
    _events = <CatalogActivityEvent>[];
    _error = null;
    if (keyPath == null || keyPath.isEmpty) {
      _loading = false;
      notifyListeners();
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    final keyPath = _keyPath;
    if (keyPath == null || keyPath.isEmpty) {
      _events = <CatalogActivityEvent>[];
      _error = null;
      _loading = false;
      notifyListeners();
      return;
    }

    final requestGeneration = ++_requestGeneration;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final events = await _client.loadActivity(keyPath: keyPath);
      if (requestGeneration != _requestGeneration) {
        return;
      }
      _events = events;
    } catch (error) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      _error = error.toString();
    } finally {
      if (requestGeneration == _requestGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }
}

abstract class CatalogDraftBase {
  CatalogDraftSyncState syncState = CatalogDraftSyncState.clean;
  String? errorMessage;
  bool touched = false;
  Timer? timer;
  Timer? savedResetTimer;
}

class CatalogValueDraft extends CatalogDraftBase {
  CatalogValueDraft({
    required this.keyPath,
    required this.locale,
    required this.baseValue,
    required this.value,
    required this.editorMode,
    required this.rawPinned,
    required this.rawText,
  });

  final String keyPath;
  final String locale;
  dynamic baseValue;
  dynamic value;
  CatalogEditorMode editorMode;
  bool rawPinned;
  String rawText;
  String? rawError;
}

class CatalogNoteDraft extends CatalogDraftBase {
  CatalogNoteDraft({
    required this.keyPath,
    required this.baseNote,
    required this.note,
  });

  final String keyPath;
  String baseNote;
  String note;
}

class CatalogDraftController extends ChangeNotifier {
  CatalogDraftController({
    required CatalogApiClient client,
    required CatalogQueueController queue,
  })  : _client = client,
        _queue = queue;

  final CatalogApiClient _client;
  final CatalogQueueController _queue;
  final Map<String, CatalogValueDraft> _valueDrafts = <String, CatalogValueDraft>{};
  final Map<String, CatalogNoteDraft> _noteDrafts = <String, CatalogNoteDraft>{};

  CatalogValueDraft valueDraftFor(CatalogRow row, String locale) {
    final key = _draftKey(row.keyPath, locale);
    final existing = _valueDrafts[key];
    final sourceValue = row.valuesByLocale[_queue.meta?.sourceLocale];
    final editorMode = detectEditorMode(
      serverValue: row.valuesByLocale[locale],
      sourceValue: sourceValue,
      rawPinned: existing?.rawPinned ?? false,
    );
    final initialValue = buildInitialCatalogValue(
      serverValue: row.valuesByLocale[locale],
      sourceValue: sourceValue,
      editorMode: editorMode,
    );
    if (existing == null) {
      final draft = CatalogValueDraft(
        keyPath: row.keyPath,
        locale: locale,
        baseValue: cloneCatalogValue(row.valuesByLocale[locale]),
        value: cloneCatalogValue(initialValue),
        editorMode: editorMode,
        rawPinned: editorMode == CatalogEditorMode.raw,
        rawText: prettyCatalogJson(initialValue),
      );
      _valueDrafts[key] = draft;
      return draft;
    }

    if (existing.syncState == CatalogDraftSyncState.clean || existing.syncState == CatalogDraftSyncState.saved) {
      existing.baseValue = cloneCatalogValue(row.valuesByLocale[locale]);
      existing.value = cloneCatalogValue(initialValue);
      existing.editorMode = editorMode;
      existing.rawPinned = editorMode == CatalogEditorMode.raw;
      existing.rawText = prettyCatalogJson(initialValue);
      existing.rawError = null;
      existing.errorMessage = null;
      existing.touched = false;
    }
    return existing;
  }

  CatalogNoteDraft noteDraftFor(CatalogRow row) {
    final existing = _noteDrafts[row.keyPath];
    if (existing == null) {
      final draft = CatalogNoteDraft(
        keyPath: row.keyPath,
        baseNote: row.note ?? '',
        note: row.note ?? '',
      );
      _noteDrafts[row.keyPath] = draft;
      return draft;
    }
    if (existing.syncState == CatalogDraftSyncState.clean || existing.syncState == CatalogDraftSyncState.saved) {
      existing.baseNote = row.note ?? '';
      existing.note = row.note ?? '';
      existing.errorMessage = null;
      existing.touched = false;
    }
    return existing;
  }

  void updatePlainDraft({
    required CatalogRow row,
    required String locale,
    required String text,
  }) {
    final draft = valueDraftFor(row, locale);
    draft.value = _parsePlainValue(text, draft.baseValue);
    draft.rawText = prettyCatalogJson(draft.value);
    draft.rawError = null;
    draft.touched = true;
    _scheduleValueDraftSave(draft);
  }

  void updateBranchDraft({
    required CatalogRow row,
    required String locale,
    required List<String> path,
    required String text,
  }) {
    final draft = valueDraftFor(row, locale);
    draft.value = setCatalogPathValue(draft.value, path, text);
    draft.rawText = prettyCatalogJson(draft.value);
    draft.rawError = null;
    draft.touched = true;
    _scheduleValueDraftSave(draft);
  }

  void updateAdvancedJsonDraft({
    required CatalogRow row,
    required String locale,
    required String text,
  }) {
    final draft = valueDraftFor(row, locale);
    draft.rawText = text;
    draft.touched = true;
    try {
      final parsed = text.trim().isEmpty ? '' : jsonDecode(text);
      draft.value = parsed;
      draft.rawError = null;
      draft.rawPinned = detectCatalogShape(parsed) == CatalogEditorMode.raw;
      _scheduleValueDraftSave(draft);
    } catch (_) {
      draft.rawError = 'invalid_json';
      draft.syncState = CatalogDraftSyncState.dirty;
      notifyListeners();
    }
  }

  void addPluralBranch({
    required CatalogRow row,
    required String locale,
    required String category,
  }) {
    final draft = valueDraftFor(row, locale);
    final nextValue = cloneCatalogValue(draft.value) ?? <String, dynamic>{};
    if (draft.editorMode == CatalogEditorMode.pluralGender) {
      final sourceBranch = readCatalogPath(row.valuesByLocale[_queue.meta?.sourceLocale], <String>[category]);
      final nextBranch = <String, dynamic>{};
      final keys = detectCatalogShape(sourceBranch) == CatalogEditorMode.gender
          ? normalizedGenderKeys(sourceBranch)
          : catalogGenderKeys;
      for (final key in keys) {
        nextBranch[key] = '';
      }
      nextValue[category] = nextBranch;
    } else {
      nextValue[category] = '';
    }
    draft.value = nextValue;
    draft.rawText = prettyCatalogJson(draft.value);
    draft.touched = true;
    _scheduleValueDraftSave(draft);
  }

  void addGenderBranch({
    required CatalogRow row,
    required String locale,
    required String? category,
    required String gender,
  }) {
    final draft = valueDraftFor(row, locale);
    final nextValue = cloneCatalogValue(draft.value) ?? <String, dynamic>{};
    if (category != null && category.isNotEmpty) {
      final map = nextValue[category];
      if (map is! Map<String, dynamic>) {
        nextValue[category] = <String, dynamic>{};
      }
      (nextValue[category] as Map<String, dynamic>)[gender] = '';
    } else {
      nextValue[gender] = '';
    }
    draft.value = nextValue;
    draft.rawText = prettyCatalogJson(draft.value);
    draft.touched = true;
    _scheduleValueDraftSave(draft);
  }

  void updateNoteDraft(CatalogRow row, String value) {
    final draft = noteDraftFor(row);
    draft.note = value;
    draft.touched = true;
    _scheduleNoteSave(draft);
  }

  List<String> validateDoneBlockers(CatalogRow row, String locale, CatalogLocalizations l10n) {
    final sourceLocale = _queue.meta?.sourceLocale;
    if (sourceLocale == null) {
      return const <String>[];
    }
    final draft = valueDraftFor(row, locale);
    final blockers = <String>[];
    if (locale == sourceLocale) {
      return blockers;
    }
    if (draft.rawError != null) {
      blockers.add(l10n.advancedJsonHelp);
      return blockers;
    }
    if (draft.syncState == CatalogDraftSyncState.dirty ||
        draft.syncState == CatalogDraftSyncState.saving ||
        draft.syncState == CatalogDraftSyncState.saveError) {
      blockers.add(l10n.blockerWaitAutosave);
    }
    if (isCatalogValueEmpty(draft.value)) {
      blockers.add(l10n.blockerTranslationEmpty);
    }
    final requiredPaths = requiredCatalogPaths(
      sourceValue: row.valuesByLocale[sourceLocale],
      currentValue: draft.value,
      editorMode: draft.editorMode,
    );
    final missingBranches = requiredPaths.where((path) {
      final value = readCatalogPath(draft.value, path);
      if (value is String) {
        return value.trim().isEmpty;
      }
      return value == null;
    }).toList();
    if (missingBranches.isNotEmpty && draft.editorMode != CatalogEditorMode.raw) {
      blockers.add(l10n.blockerFillBranches);
    }
    final sourcePlaceholders = collectCatalogPlaceholders(row.valuesByLocale[sourceLocale]);
    final targetPlaceholders = collectCatalogPlaceholders(draft.value);
    final missingPlaceholders = sourcePlaceholders.where((item) => !targetPlaceholders.contains(item)).toList();
    if (missingPlaceholders.isNotEmpty) {
      blockers.add('${l10n.blockerMissingPlaceholders}: ${missingPlaceholders.map((item) => '{$item}').join(', ')}');
    }
    return blockers;
  }

  /// Optional type warnings (e.g. key has _type "plural" but missing required forms). Shown in Catalog UI; do not block Done.
  List<String> listOptionalTypeWarnings(CatalogRow row, String locale) {
    final draft = valueDraftFor(row, locale);
    final value = draft.value ?? row.valuesByLocale[locale];
    return TranslationValidator.getOptionalTypeWarningsForValue(row.keyPath, locale, value);
  }

  CatalogDraftSyncState rowSyncState(String keyPath) {
    final relatedDrafts = <CatalogDraftBase>[
      ..._valueDrafts.values.where((draft) => draft.keyPath == keyPath),
      if (_noteDrafts.containsKey(keyPath)) _noteDrafts[keyPath]!,
    ];
    if (relatedDrafts.any((draft) => draft.syncState == CatalogDraftSyncState.saveError)) {
      return CatalogDraftSyncState.saveError;
    }
    if (relatedDrafts.any((draft) => draft.syncState == CatalogDraftSyncState.saving)) {
      return CatalogDraftSyncState.saving;
    }
    if (relatedDrafts.any((draft) => draft.syncState == CatalogDraftSyncState.dirty)) {
      return CatalogDraftSyncState.dirty;
    }
    if (relatedDrafts.any((draft) => draft.syncState == CatalogDraftSyncState.saved)) {
      return CatalogDraftSyncState.saved;
    }
    return CatalogDraftSyncState.clean;
  }

  Future<void> markReviewed({
    required CatalogRow row,
    required String locale,
  }) async {
    await _client.markReviewed(
      keyPath: row.keyPath,
      locale: locale,
    );
    await _queue.refresh();
  }

  Future<void> bulkReviewTargets(List<CatalogReviewTarget> targets) async {
    if (targets.isEmpty) {
      return;
    }
    await _client.bulkReview(targets: targets);
    await _queue.refresh();
  }

  Future<void> deleteValue({
    required CatalogRow row,
    required String locale,
  }) async {
    final updated = await _client.deleteCell(
      keyPath: row.keyPath,
      locale: locale,
    );
    _valueDrafts.remove(_draftKey(row.keyPath, locale));
    _queue.upsertRow(updated);
    await _queue.refreshSummary();
  }

  Future<void> deleteKey(CatalogRow row) async {
    await _client.deleteKey(keyPath: row.keyPath);
    _queue.removeKey(row.keyPath);
    _valueDrafts.removeWhere((key, draft) => draft.keyPath == row.keyPath);
    _noteDrafts.remove(row.keyPath);
    await _queue.refreshSummary();
  }

  Future<CatalogRow> createKey({
    required String keyPath,
    required Map<String, dynamic> valuesByLocale,
    String? note,
  }) async {
    final row = await _client.addKey(
      keyPath: keyPath,
      valuesByLocale: valuesByLocale,
      note: note,
      markGreenIfComplete: true,
    );
    _queue.upsertRow(row);
    await _queue.refreshSummary();
    return row;
  }

  Future<void> flushValueDraft(CatalogRow row, String locale) async {
    final key = _draftKey(row.keyPath, locale);
    final draft = _valueDrafts[key];
    if (draft == null) {
      return;
    }
    draft.timer?.cancel();
    if (!_isValueDraftDirty(draft) || draft.rawError != null) {
      notifyListeners();
      return;
    }
    draft.syncState = CatalogDraftSyncState.saving;
    notifyListeners();
    try {
      final updatedRow = await _client.updateCell(
        keyPath: row.keyPath,
        locale: locale,
        value: draft.value,
      );
      draft.baseValue = cloneCatalogValue(updatedRow.valuesByLocale[locale]);
      final sourceValue = updatedRow.valuesByLocale[_queue.meta?.sourceLocale];
      draft.editorMode = detectEditorMode(
        serverValue: updatedRow.valuesByLocale[locale],
        sourceValue: sourceValue,
        rawPinned: draft.rawPinned,
      );
      draft.value = buildInitialCatalogValue(
        serverValue: updatedRow.valuesByLocale[locale],
        sourceValue: sourceValue,
        editorMode: draft.editorMode,
      );
      draft.rawText = prettyCatalogJson(draft.value);
      draft.rawError = null;
      draft.touched = false;
      draft.syncState = CatalogDraftSyncState.saved;
      draft.errorMessage = null;
      _queue.upsertRow(updatedRow);
      await _queue.refreshSummary();
      _scheduleSavedReset(draft);
      notifyListeners();
    } catch (error) {
      draft.syncState = CatalogDraftSyncState.saveError;
      draft.errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> flushNoteDraft(CatalogRow row) async {
    final draft = _noteDrafts[row.keyPath];
    if (draft == null) {
      return;
    }
    draft.timer?.cancel();
    if (!_isNoteDraftDirty(draft)) {
      notifyListeners();
      return;
    }
    draft.syncState = CatalogDraftSyncState.saving;
    notifyListeners();
    try {
      final updatedRow = await _client.updateKeyNote(
        keyPath: row.keyPath,
        note: draft.note,
      );
      draft.baseNote = updatedRow.note ?? '';
      draft.note = updatedRow.note ?? '';
      draft.touched = false;
      draft.syncState = CatalogDraftSyncState.saved;
      draft.errorMessage = null;
      _queue.upsertRow(updatedRow);
      _scheduleSavedReset(draft);
      notifyListeners();
    } catch (error) {
      draft.syncState = CatalogDraftSyncState.saveError;
      draft.errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> updateKeyDataType(CatalogRow row, DataType dataType) async {
    try {
      final updatedRow = await _client.updateKeyDataType(
        keyPath: row.keyPath,
        dataType: dataTypeToString(dataType),
      );
      _queue.upsertRow(updatedRow);
      notifyListeners();
    } catch (_) {
      notifyListeners();
    }
  }

  CatalogRow? rowByKey(String keyPath) => _queue.rowByKey(keyPath);

  @override
  void dispose() {
    for (final draft in _valueDrafts.values) {
      draft.timer?.cancel();
      draft.savedResetTimer?.cancel();
    }
    for (final draft in _noteDrafts.values) {
      draft.timer?.cancel();
      draft.savedResetTimer?.cancel();
    }
    super.dispose();
  }

  void _scheduleValueDraftSave(CatalogValueDraft draft) {
    draft.syncState = CatalogDraftSyncState.dirty;
    draft.errorMessage = null;
    draft.timer?.cancel();
    draft.timer = Timer(const Duration(milliseconds: 700), () {
      final row = rowByKey(draft.keyPath);
      if (row != null) {
        flushValueDraft(row, draft.locale);
      }
    });
    notifyListeners();
  }

  void _scheduleNoteSave(CatalogNoteDraft draft) {
    draft.syncState = CatalogDraftSyncState.dirty;
    draft.errorMessage = null;
    draft.timer?.cancel();
    draft.timer = Timer(const Duration(milliseconds: 700), () {
      final row = rowByKey(draft.keyPath);
      if (row != null) {
        flushNoteDraft(row);
      }
    });
    notifyListeners();
  }

  bool _isValueDraftDirty(CatalogValueDraft draft) {
    return canonicalizeForDraft(draft.value) != canonicalizeForDraft(draft.baseValue);
  }

  bool _isNoteDraftDirty(CatalogNoteDraft draft) {
    return draft.note.trim() != draft.baseNote.trim();
  }

  dynamic _parsePlainValue(String text, dynamic baseValue) {
    if (baseValue is num) {
      return num.tryParse(text) ?? text;
    }
    if (baseValue is bool) {
      if (text.trim() == 'true') {
        return true;
      }
      if (text.trim() == 'false') {
        return false;
      }
    }
    return text;
  }

  void _scheduleSavedReset(CatalogDraftBase draft) {
    draft.savedResetTimer?.cancel();
    draft.savedResetTimer = Timer(const Duration(milliseconds: 1200), () {
      if (draft.syncState == CatalogDraftSyncState.saved) {
        draft.syncState = CatalogDraftSyncState.clean;
        notifyListeners();
      }
    });
  }

  String _draftKey(String keyPath, String locale) => '$keyPath::$locale';
}

class CatalogWorkspaceController extends ChangeNotifier {
  CatalogWorkspaceController({
    required CatalogApiClient client,
  }) : _client = client {
    workspacePreferences = CatalogWorkspacePreferencesController();
    queue = CatalogQueueController(
      client: client,
      preferences: workspacePreferences,
    );
    selection = CatalogSelectionController(
      preferences: workspacePreferences,
    );
    drafts = CatalogDraftController(
      client: client,
      queue: queue,
    );
    activity = CatalogActivityController(
      client: client,
    );

    queue.addListener(_handleQueueChanged);
    selection.addListener(_handleSelectionChanged);
    workspacePreferences.addListener(_handleChildChanged);
    drafts.addListener(_handleChildChanged);
    activity.addListener(_handleChildChanged);
  }

  /// Named constructor for use in widget previews / tests only.
  ///
  /// Seeds all internal controllers with the provided values so that no async
  /// initialisation is required and the UI renders immediately.
  CatalogWorkspaceController.forPreview({
    required CatalogApiClient client,
    required CatalogQueueSortMode sortMode,
    required Set<CatalogQueueSection> collapsedSections,
    required String? lastSelectedLocale,
    required CatalogMeta meta,
    required CatalogSummary summary,
    required List<CatalogRow> rows,
    required String? selectedKey,
    required String? selectedLocale,
    required bool selectionExplicit,
    required String? activityKeyPath,
    required List<CatalogActivityEvent> activityEvents,
  }) : _client = client {
    workspacePreferences = CatalogWorkspacePreferencesController();
    workspacePreferences._sortMode = sortMode;
    workspacePreferences._collapsedSections = Set<CatalogQueueSection>.from(collapsedSections);
    workspacePreferences._lastSelectedLocale = lastSelectedLocale;
    workspacePreferences._loaded = true;

    queue = CatalogQueueController(
      client: client,
      preferences: workspacePreferences,
    );
    queue._meta = meta;
    queue._summary = summary;
    queue._rows = List<CatalogRow>.from(rows);
    queue._initialized = true;
    queue._loading = false;
    queue._error = null;

    selection = CatalogSelectionController(
      preferences: workspacePreferences,
    );
    selection._selectedKey = selectedKey;
    selection._selectedLocale = selectedLocale;
    selection._selectionExplicit = selectionExplicit;

    drafts = CatalogDraftController(
      client: client,
      queue: queue,
    );

    activity = CatalogActivityController(
      client: client,
    );
    activity._keyPath = activityKeyPath;
    activity._events = List<CatalogActivityEvent>.from(activityEvents);
    activity._loading = false;
    activity._error = null;

    _initialized = true;

    queue.addListener(_handleQueueChanged);
    selection.addListener(_handleSelectionChanged);
    workspacePreferences.addListener(_handleChildChanged);
    drafts.addListener(_handleChildChanged);
    activity.addListener(_handleChildChanged);
  }

  final CatalogApiClient _client;
  late final CatalogWorkspacePreferencesController workspacePreferences;
  late final CatalogQueueController queue;
  late final CatalogSelectionController selection;
  late final CatalogDraftController drafts;
  late final CatalogActivityController activity;
  bool _initialized = false;

  CatalogMeta? get meta => queue.meta;
  CatalogSummary? get summary => queue.summary;
  List<CatalogRow> get rows => queue.rows;
  String get search => queue.search;
  CatalogRowStatusFilter get statusFilter => queue.statusFilter;
  CatalogQueueSortMode get sortMode => queue.sortMode;
  String? get selectedKey => selection.selectedKey;
  String? get selectedLocale => selection.selectedLocale;
  bool get compactDetailOpen => selection.compactDetailOpen && selectedRow != null;
  String? get error => queue.error;
  bool get loading => queue.loading;
  bool get initialized => _initialized;
  List<CatalogActivityEvent> get activityEvents => activity.events;
  bool get activityLoading => activity.loading;
  String? get activityError => activity.error;
  bool get hasAnyKeys => queue.hasAnyKeys;

  CatalogRow? get selectedRow => selection.selectedRow(rows);

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await workspacePreferences.load();
    await queue.initialize();
    selection.sync(
      rows: queue.rows,
      meta: queue.meta,
    );
    await activity.showKey(selection.selectedKey);
    _initialized = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    await flushActiveDrafts();
    await queue.refresh();
    await activity.refresh();
  }

  void updateSearch(String value) {
    queue.updateSearch(value);
  }

  Future<void> updateStatusFilter(CatalogRowStatusFilter filter) {
    return queue.updateStatusFilter(filter);
  }

  Future<void> updateSortMode(CatalogQueueSortMode mode) {
    return queue.updateSortMode(mode);
  }

  List<CatalogQueueSection> get visibleSections => queue.visibleSections;

  List<CatalogRow> rowsForSection(CatalogQueueSection section) => queue.rowsForSection(section);

  int sectionCount(CatalogQueueSection section) => queue.sectionCount(section);

  bool isSectionCollapsed(CatalogQueueSection section) => queue.isSectionCollapsed(section);

  Future<void> setSectionCollapsed(CatalogQueueSection section, bool collapsed) {
    return queue.setSectionCollapsed(section, collapsed);
  }

  String namespaceForKey(String keyPath) => queue.namespaceForKey(keyPath);

  String get defaultEditorLocale => selection.defaultEditorLocale(meta);

  Future<void> selectRow(String keyPath) async {
    await flushActiveDrafts();
    selection.openRow(keyPath);
  }

  Future<void> clearSelection() async {
    await flushActiveDrafts();
    selection.clearCompactDetail();
  }

  Future<void> selectLocale(String locale) async {
    if (selectedLocale == locale) {
      return;
    }
    await flushActiveValueDraft();
    await selection.selectLocale(locale);
  }

  CatalogValueDraft valueDraftFor(CatalogRow row, String locale) => drafts.valueDraftFor(row, locale);

  CatalogNoteDraft noteDraftFor(CatalogRow row) => drafts.noteDraftFor(row);

  void updatePlainDraft({
    required CatalogRow row,
    required String locale,
    required String text,
  }) {
    drafts.updatePlainDraft(row: row, locale: locale, text: text);
  }

  void updateBranchDraft({
    required CatalogRow row,
    required String locale,
    required List<String> path,
    required String text,
  }) {
    drafts.updateBranchDraft(row: row, locale: locale, path: path, text: text);
  }

  void updateAdvancedJsonDraft({
    required CatalogRow row,
    required String locale,
    required String text,
  }) {
    drafts.updateAdvancedJsonDraft(row: row, locale: locale, text: text);
  }

  Future<void> updateKeyDataType(CatalogRow row, DataType dataType) {
    return drafts.updateKeyDataType(row, dataType);
  }

  void addPluralBranch({
    required CatalogRow row,
    required String locale,
    required String category,
  }) {
    drafts.addPluralBranch(row: row, locale: locale, category: category);
  }

  void addGenderBranch({
    required CatalogRow row,
    required String locale,
    required String? category,
    required String gender,
  }) {
    drafts.addGenderBranch(row: row, locale: locale, category: category, gender: gender);
  }

  void updateNoteDraft(CatalogRow row, String value) {
    drafts.updateNoteDraft(row, value);
  }

  List<String> validateDoneBlockers(CatalogRow row, String locale, CatalogLocalizations l10n) {
    return drafts.validateDoneBlockers(row, locale, l10n);
  }

  /// Optional type warnings for typed keys (e.g. _type "plural" with missing forms). Shown in Catalog UI; do not block Done.
  List<String> listOptionalTypeWarnings(CatalogRow row, String locale) {
    return drafts.listOptionalTypeWarnings(row, locale);
  }

  CatalogDraftSyncState rowSyncState(String keyPath) => drafts.rowSyncState(keyPath);

  Future<void> markReviewed({
    required CatalogRow row,
    required String locale,
  }) async {
    await drafts.markReviewed(row: row, locale: locale);
    await activity.refresh();
  }

  Future<void> bulkReviewTargets(List<CatalogReviewTarget> targets) async {
    await drafts.bulkReviewTargets(targets);
    await activity.refresh();
  }

  Future<void> deleteValue({
    required CatalogRow row,
    required String locale,
  }) async {
    await drafts.deleteValue(row: row, locale: locale);
    await activity.refresh();
  }

  Future<void> deleteKey(CatalogRow row) async {
    await drafts.deleteKey(row);
    await activity.showKey(selection.selectedKey);
  }

  Future<void> createKey({
    required String keyPath,
    required Map<String, dynamic> valuesByLocale,
    String? note,
  }) async {
    final row = await drafts.createKey(
      keyPath: keyPath,
      valuesByLocale: valuesByLocale,
      note: note,
    );
    selection.openRow(row.keyPath);
    await selection.selectLocale(defaultEditorLocale);
    await activity.showKey(row.keyPath);
  }

  Future<void> flushActiveDrafts() async {
    await flushActiveValueDraft();
    await flushActiveNoteDraft();
  }

  Future<void> flushActiveValueDraft() async {
    final row = selectedRow;
    final locale = selectedLocale;
    if (row == null || locale == null) {
      return;
    }
    await flushValueDraft(row, locale);
  }

  Future<void> flushActiveNoteDraft() async {
    final row = selectedRow;
    if (row == null) {
      return;
    }
    await flushNoteDraft(row);
  }

  Future<void> flushValueDraft(CatalogRow row, String locale) async {
    await drafts.flushValueDraft(row, locale);
    if (selectedKey == row.keyPath) {
      await activity.refresh();
    }
  }

  Future<void> flushNoteDraft(CatalogRow row) async {
    await drafts.flushNoteDraft(row);
    if (selectedKey == row.keyPath) {
      await activity.refresh();
    }
  }

  CatalogRow? rowByKey(String keyPath) => queue.rowByKey(keyPath);

  String formatTimestamp(DateTime? value, Locale locale) {
    if (value == null) {
      return '';
    }
    return DateFormat.yMd(locale.toLanguageTag()).add_jm().format(value.toLocal());
  }

  String localeDirection(String locale) {
    return meta?.localeDirections[locale] ?? 'ltr';
  }

  void _handleQueueChanged() {
    selection.sync(
      rows: queue.rows,
      meta: queue.meta,
    );
    notifyListeners();
  }

  void _handleSelectionChanged() {
    unawaited(activity.showKey(selection.selectedKey));
    notifyListeners();
  }

  void _handleChildChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    queue.removeListener(_handleQueueChanged);
    selection.removeListener(_handleSelectionChanged);
    workspacePreferences.removeListener(_handleChildChanged);
    drafts.removeListener(_handleChildChanged);
    activity.removeListener(_handleChildChanged);
    queue.dispose();
    drafts.dispose();
    activity.dispose();
    workspacePreferences.dispose();
    _client.close();
    super.dispose();
  }
}

CatalogQueueSection? _queueSectionFromStorage(String value) {
  for (final section in CatalogQueueSection.values) {
    if (section.storageValue == value) {
      return section;
    }
  }
  return null;
}

CatalogQueueSection _queueSectionForStatusFilter(CatalogRowStatusFilter filter) {
  return switch (filter) {
    CatalogRowStatusFilter.missing => CatalogQueueSection.missing,
    CatalogRowStatusFilter.needsReview => CatalogQueueSection.needsReview,
    CatalogRowStatusFilter.ready => CatalogQueueSection.ready,
    CatalogRowStatusFilter.all => CatalogQueueSection.needsReview,
  };
}
