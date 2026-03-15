import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../client/catalog_client.dart';
import '../../domain/entities/catalog_models.dart';
import '../../domain/services/catalog_flatten.dart';
import '../controllers/catalog_ui_logic.dart' show CatalogDraftSyncState, cloneCatalogValue, prettyCatalogJson;
import '../screens/catalog_flutter_app.dart' show CatalogApp;
import '../screens/catalog_preferences_controller.dart';
import '../screens/catalog_ui_enums.dart';
import '../screens/catalog_workspace_controllers.dart';

@Preview(
  group: 'Catalog',
  name: 'Desktop review',
  size: Size(1440, 960),
)
Widget catalogDesktopReviewPreview() {
  return const _CatalogPreviewHost(
    scenario: _CatalogPreviewScenario.desktopReview,
  );
}

@Preview(
  group: 'Catalog',
  name: 'Desktop dark RTL',
  size: Size(1440, 960),
)
Widget catalogDesktopDarkRtlPreview() {
  return const _CatalogPreviewHost(
    scenario: _CatalogPreviewScenario.desktopDarkRtl,
  );
}

@Preview(
  group: 'Catalog',
  name: 'Mobile missing',
  size: Size(430, 932),
)
Widget catalogMobileMissingPreview() {
  return const _CatalogPreviewHost(
    scenario: _CatalogPreviewScenario.mobileMissing,
  );
}

enum _CatalogPreviewScenario {
  desktopReview,
  desktopDarkRtl,
  mobileMissing,
}

class _CatalogPreviewHost extends StatefulWidget {
  const _CatalogPreviewHost({
    required this.scenario,
  });

  final _CatalogPreviewScenario scenario;

  @override
  State<_CatalogPreviewHost> createState() => _CatalogPreviewHostState();
}

class _CatalogPreviewHostState extends State<_CatalogPreviewHost> {
  late final _CatalogPreviewSeed _seed = _CatalogPreviewSeed.forScenario(widget.scenario);
  late final CatalogWorkspaceController _workspaceController = _seed.buildWorkspaceController();
  late final CatalogPreferencesController _preferencesController = _CatalogPreviewPreferencesController(
    displayLanguage: _seed.displayLanguage,
    themeMode: _seed.themeMode,
  );

  @override
  void dispose() {
    _workspaceController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CatalogApp(
      workspaceController: _workspaceController,
      preferencesController: _preferencesController,
    );
  }
}

class _CatalogPreviewPreferencesController extends CatalogPreferencesController {
  _CatalogPreviewPreferencesController({
    required CatalogThemeMode themeMode,
    required CatalogDisplayLanguage displayLanguage,
  })  : _previewThemeMode = themeMode,
        _previewDisplayLanguage = displayLanguage;

  CatalogThemeMode _previewThemeMode;
  CatalogDisplayLanguage _previewDisplayLanguage;

  @override
  CatalogThemeMode get themeMode => _previewThemeMode;

  @override
  CatalogDisplayLanguage get displayLanguage => _previewDisplayLanguage;

  @override
  bool get loaded => true;

  @override
  Future<void> load() async {}

  @override
  Future<void> setDisplayLanguage(CatalogDisplayLanguage language) async {
    _previewDisplayLanguage = language;
    notifyListeners();
  }

  @override
  Future<void> setThemeMode(CatalogThemeMode mode) async {
    _previewThemeMode = mode;
    notifyListeners();
  }
}

class _CatalogPreviewSeed {
  const _CatalogPreviewSeed({
    required this.themeMode,
    required this.displayLanguage,
    required this.selectedKey,
    required this.selectedLocale,
    required this.selectionExplicit,
    required this.rows,
    required this.activitiesByKey,
    required this.sortMode,
    this.collapsedSections = const <CatalogQueueSection>{},
  });

  factory _CatalogPreviewSeed.forScenario(_CatalogPreviewScenario scenario) {
    return switch (scenario) {
      _CatalogPreviewScenario.desktopReview => _CatalogPreviewSeed(
          themeMode: CatalogThemeMode.light,
          displayLanguage: CatalogDisplayLanguage.en,
          selectedKey: 'checkout.items_count',
          selectedLocale: 'tr',
          selectionExplicit: true,
          rows: _buildPreviewRows(),
          activitiesByKey: _buildPreviewActivities(),
          sortMode: CatalogQueueSortMode.alphabetical,
        ),
      _CatalogPreviewScenario.desktopDarkRtl => _CatalogPreviewSeed(
          themeMode: CatalogThemeMode.dark,
          displayLanguage: CatalogDisplayLanguage.ar,
          selectedKey: 'home.welcome',
          selectedLocale: 'ar',
          selectionExplicit: true,
          rows: _buildPreviewRows(),
          activitiesByKey: _buildPreviewActivities(),
          sortMode: CatalogQueueSortMode.namespace,
        ),
      _CatalogPreviewScenario.mobileMissing => _CatalogPreviewSeed(
          themeMode: CatalogThemeMode.light,
          displayLanguage: CatalogDisplayLanguage.en,
          selectedKey: 'settings.delete_account',
          selectedLocale: 'ar',
          selectionExplicit: true,
          rows: _buildPreviewRows(),
          activitiesByKey: _buildPreviewActivities(),
          sortMode: CatalogQueueSortMode.alphabetical,
          collapsedSections: const <CatalogQueueSection>{
            CatalogQueueSection.ready,
          },
        ),
    };
  }

  final CatalogThemeMode themeMode;
  final CatalogDisplayLanguage displayLanguage;
  final String selectedKey;
  final String selectedLocale;
  final bool selectionExplicit;
  final CatalogQueueSortMode sortMode;
  final Set<CatalogQueueSection> collapsedSections;
  final List<CatalogRow> rows;
  final Map<String, List<CatalogActivityEvent>> activitiesByKey;

  CatalogWorkspaceController buildWorkspaceController() {
    final client = _CatalogPreviewApiClient(
      rows: rows,
      activitiesByKey: activitiesByKey,
    );
    final controller = CatalogWorkspaceController.forPreview(
      client: client,
      sortMode: sortMode,
      collapsedSections: collapsedSections,
      lastSelectedLocale: selectedLocale,
      meta: _CatalogPreviewApiClient.meta,
      summary: client.summary,
      rows: client.snapshotRows(),
      selectedKey: selectedKey,
      selectedLocale: selectedLocale,
      selectionExplicit: selectionExplicit,
      activityKeyPath: selectedKey,
      activityEvents: client.snapshotActivity(selectedKey),
    );

    // Apply draft states for the pre-selected key/locale in the preview.
    final selectedRow = controller.selectedRow;
    final locale = controller.selectedLocale;
    if (selectedRow != null && locale != null) {
      final valueDraft = controller.drafts.valueDraftFor(selectedRow, locale);
      if (selectedKey == 'checkout.items_count' && locale == 'tr') {
        valueDraft.syncState = CatalogDraftSyncState.saved;
      }
      final noteDraft = controller.drafts.noteDraftFor(selectedRow);
      if ((selectedRow.note ?? '').trim().isNotEmpty) {
        noteDraft.syncState = CatalogDraftSyncState.clean;
      }
    }

    return controller;
  }
}

class _CatalogPreviewApiClient extends CatalogApiClient {
  _CatalogPreviewApiClient({
    required List<CatalogRow> rows,
    required Map<String, List<CatalogActivityEvent>> activitiesByKey,
  })  : _rows = rows.map(_cloneCatalogRow).toList(),
        _activitiesByKey = <String, List<CatalogActivityEvent>>{
          for (final MapEntry<String, List<CatalogActivityEvent>> entry in activitiesByKey.entries)
            entry.key: entry.value.map(_cloneActivityEvent).toList(),
        },
        super(baseUri: Uri.parse('http://127.0.0.1:0'));

  static const CatalogMeta meta = CatalogMeta(
    locales: <String>['en', 'tr', 'ar'],
    localeDirections: <String, String>{
      'en': 'ltr',
      'tr': 'ltr',
      'ar': 'rtl',
    },
    sourceLocale: 'en',
    fallbackLocale: 'en',
    langDirectory: '/preview/lang',
    format: 'json',
    stateFilePath: '/preview/catalog_state.json',
    uiPort: 0,
    apiPort: 0,
  );

  final List<CatalogRow> _rows;
  final Map<String, List<CatalogActivityEvent>> _activitiesByKey;

  CatalogSummary get summary => _computeSummary(_rows);

  List<CatalogRow> snapshotRows() => _rows.map(_cloneCatalogRow).toList();

  List<CatalogActivityEvent> snapshotActivity(String? keyPath) {
    return List<CatalogActivityEvent>.from(
      _activitiesByKey[keyPath] ?? const <CatalogActivityEvent>[],
    );
  }

  @override
  Future<CatalogMeta> loadMeta() async => meta;

  @override
  Future<List<CatalogRow>> loadRows({
    String search = '',
    String status = '',
  }) async {
    final query = search.trim().toLowerCase();
    return _rows
        .where((row) {
          final matchesStatus = status.isEmpty || row.rowStatus.name == status;
          if (!matchesStatus) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          final haystack = <String>[
            row.keyPath,
            row.note ?? '',
            ...row.valuesByLocale.values.map((value) => prettyCatalogJson(value)),
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .map(_cloneCatalogRow)
        .toList();
  }

  @override
  Future<CatalogSummary> loadSummary() async => summary;

  @override
  Future<List<CatalogActivityEvent>> loadActivity({
    required String keyPath,
  }) async {
    return snapshotActivity(keyPath);
  }

  @override
  Future<CatalogRow> addKey({
    required String keyPath,
    required Map<String, dynamic> valuesByLocale,
    String? note,
    bool markGreenIfComplete = true,
  }) async {
    final row = _recalculateRow(
      CatalogRow(
        keyPath: keyPath,
        valuesByLocale: <String, dynamic>{
          for (final locale in meta.locales) locale: cloneCatalogValue(valuesByLocale[locale] ?? ''),
        },
        cellStates: <String, CatalogCellState>{
          for (final locale in meta.locales) locale: const CatalogCellState(status: CatalogCellStatus.red),
        },
        rowStatus: CatalogCellStatus.red,
        pendingLocales: const <String>[],
        missingLocales: const <String>[],
        note: note,
      ),
    );
    _rows.add(row);
    _activitiesByKey[keyPath] = <CatalogActivityEvent>[
      CatalogActivityEvent(
        kind: CatalogActivityKinds.keyCreated,
        timestamp: DateTime.utc(2026, 3, 11, 10, 0),
      ),
    ];
    return _cloneCatalogRow(row);
  }

  @override
  Future<CatalogRow> updateCell({
    required String keyPath,
    required String locale,
    required dynamic value,
  }) async {
    final row = _rowByKey(keyPath);
    final updated = _recalculateRow(
      CatalogRow(
        keyPath: row.keyPath,
        valuesByLocale: <String, dynamic>{
          ...row.valuesByLocale,
          locale: cloneCatalogValue(value),
        },
        cellStates: row.cellStates,
        rowStatus: row.rowStatus,
        pendingLocales: row.pendingLocales,
        missingLocales: row.missingLocales,
        note: row.note,
      ),
    );
    _replaceRow(updated);
    _appendActivity(
      keyPath,
      CatalogActivityEvent(
        kind: locale == meta.sourceLocale ? CatalogActivityKinds.sourceUpdated : CatalogActivityKinds.targetUpdated,
        timestamp: DateTime.utc(2026, 3, 11, 10, 5),
        locale: locale == meta.sourceLocale ? null : locale,
      ),
    );
    return _cloneCatalogRow(updated);
  }

  @override
  Future<CatalogRow> updateKeyNote({
    required String keyPath,
    String? note,
  }) async {
    final row = _rowByKey(keyPath);
    final updated = CatalogRow(
      keyPath: row.keyPath,
      valuesByLocale: Map<String, dynamic>.from(row.valuesByLocale),
      cellStates: Map<String, CatalogCellState>.from(row.cellStates),
      rowStatus: row.rowStatus,
      pendingLocales: List<String>.from(row.pendingLocales),
      missingLocales: List<String>.from(row.missingLocales),
      note: note,
    );
    _replaceRow(updated);
    _appendActivity(
      keyPath,
      CatalogActivityEvent(
        kind: CatalogActivityKinds.noteUpdated,
        timestamp: DateTime.utc(2026, 3, 11, 10, 10),
      ),
    );
    return _cloneCatalogRow(updated);
  }

  @override
  Future<void> markReviewed({
    required String keyPath,
    required String locale,
  }) async {
    final row = _rowByKey(keyPath);
    final states = Map<String, CatalogCellState>.from(row.cellStates);
    states[locale] = (states[locale] ?? const CatalogCellState(status: CatalogCellStatus.warning)).copyWith(
      status: CatalogCellStatus.green,
      lastReviewedAt: DateTime.utc(2026, 3, 11, 10, 12),
      clearReason: true,
    );
    final updated = _recalculateRow(
      CatalogRow(
        keyPath: row.keyPath,
        valuesByLocale: Map<String, dynamic>.from(row.valuesByLocale),
        cellStates: states,
        rowStatus: row.rowStatus,
        pendingLocales: row.pendingLocales.where((item) => item != locale).toList(),
        missingLocales: row.missingLocales.where((item) => item != locale).toList(),
        note: row.note,
      ),
    );
    _replaceRow(updated);
    _appendActivity(
      keyPath,
      CatalogActivityEvent(
        kind: CatalogActivityKinds.localeReviewed,
        timestamp: DateTime.utc(2026, 3, 11, 10, 12),
        locale: locale,
      ),
    );
  }

  @override
  Future<CatalogBulkReviewResult> bulkReview({
    required List<CatalogReviewTarget> targets,
  }) async {
    for (final target in targets) {
      await markReviewed(
        keyPath: target.keyPath,
        locale: target.locale,
      );
    }
    return CatalogBulkReviewResult(reviewedCount: targets.length);
  }

  @override
  Future<CatalogRow> deleteCell({
    required String keyPath,
    required String locale,
  }) async {
    final row = _rowByKey(keyPath);
    final updated = _recalculateRow(
      CatalogRow(
        keyPath: row.keyPath,
        valuesByLocale: <String, dynamic>{
          ...row.valuesByLocale,
          locale: '',
        },
        cellStates: row.cellStates,
        rowStatus: row.rowStatus,
        pendingLocales: row.pendingLocales,
        missingLocales: row.missingLocales,
        note: row.note,
      ),
    );
    _replaceRow(updated);
    _appendActivity(
      keyPath,
      CatalogActivityEvent(
        kind: CatalogActivityKinds.valueDeleted,
        timestamp: DateTime.utc(2026, 3, 11, 10, 15),
        locale: locale,
      ),
    );
    return _cloneCatalogRow(updated);
  }

  @override
  Future<void> deleteKey({
    required String keyPath,
  }) async {
    _rows.removeWhere((row) => row.keyPath == keyPath);
    _activitiesByKey.remove(keyPath);
  }

  CatalogRow _rowByKey(String keyPath) {
    return _rows.firstWhere((row) => row.keyPath == keyPath);
  }

  void _replaceRow(CatalogRow row) {
    final index = _rows.indexWhere((item) => item.keyPath == row.keyPath);
    if (index >= 0) {
      _rows[index] = row;
    }
  }

  void _appendActivity(String keyPath, CatalogActivityEvent event) {
    final events = _activitiesByKey.putIfAbsent(keyPath, () => <CatalogActivityEvent>[]);
    events.insert(0, event);
  }
}

CatalogSummary _computeSummary(List<CatalogRow> rows) {
  var greenRows = 0;
  var warningRows = 0;
  var redRows = 0;
  var greenCount = 0;
  var warningCount = 0;
  var redCount = 0;

  for (final row in rows) {
    switch (row.rowStatus) {
      case CatalogCellStatus.green:
        greenRows += 1;
      case CatalogCellStatus.warning:
        warningRows += 1;
      case CatalogCellStatus.red:
        redRows += 1;
    }

    for (final cell in row.cellStates.values) {
      switch (cell.status) {
        case CatalogCellStatus.green:
          greenCount += 1;
        case CatalogCellStatus.warning:
          warningCount += 1;
        case CatalogCellStatus.red:
          redCount += 1;
      }
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

CatalogRow _recalculateRow(CatalogRow row) {
  final cellStates = <String, CatalogCellState>{};
  final pendingLocales = <String>[];
  final missingLocales = <String>[];

  for (final locale in _CatalogPreviewApiClient.meta.locales) {
    final existing = row.cellStates[locale] ?? const CatalogCellState(status: CatalogCellStatus.warning);
    if (locale == _CatalogPreviewApiClient.meta.sourceLocale) {
      cellStates[locale] = existing.copyWith(
        status: CatalogCellStatus.green,
        reason: null,
        clearReason: true,
      );
      continue;
    }

    final value = row.valuesByLocale[locale];
    if (isCatalogValueEmpty(value)) {
      cellStates[locale] = existing.copyWith(
        status: CatalogCellStatus.red,
        reason: 'target_missing',
      );
      missingLocales.add(locale);
      continue;
    }

    cellStates[locale] = existing.copyWith(
      status: CatalogCellStatus.warning,
      reason: 'target_updated_needs_review',
      lastEditedAt: DateTime.utc(2026, 3, 11, 9, 45),
    );
    pendingLocales.add(locale);
  }

  final rowStatus = missingLocales.isNotEmpty
      ? CatalogCellStatus.red
      : pendingLocales.isNotEmpty
          ? CatalogCellStatus.warning
          : CatalogCellStatus.green;

  return CatalogRow(
    keyPath: row.keyPath,
    valuesByLocale: <String, dynamic>{
      for (final entry in row.valuesByLocale.entries) entry.key: cloneCatalogValue(entry.value),
    },
    cellStates: cellStates,
    rowStatus: rowStatus,
    pendingLocales: pendingLocales,
    missingLocales: missingLocales,
    note: row.note,
  );
}

CatalogRow _cloneCatalogRow(CatalogRow row) {
  return CatalogRow(
    keyPath: row.keyPath,
    valuesByLocale: <String, dynamic>{
      for (final entry in row.valuesByLocale.entries) entry.key: cloneCatalogValue(entry.value),
    },
    cellStates: <String, CatalogCellState>{
      for (final entry in row.cellStates.entries)
        entry.key: entry.value.copyWith(
          status: entry.value.status,
          reason: entry.value.reason,
          lastReviewedSourceHash: entry.value.lastReviewedSourceHash,
          lastReviewedAt: entry.value.lastReviewedAt,
          lastEditedAt: entry.value.lastEditedAt,
        ),
    },
    rowStatus: row.rowStatus,
    pendingLocales: List<String>.from(row.pendingLocales),
    missingLocales: List<String>.from(row.missingLocales),
    note: row.note,
  );
}

CatalogActivityEvent _cloneActivityEvent(CatalogActivityEvent event) {
  return CatalogActivityEvent(
    kind: event.kind,
    timestamp: event.timestamp,
    locale: event.locale,
  );
}

List<CatalogRow> _buildPreviewRows() {
  return <CatalogRow>[
    _recalculateRow(
      const CatalogRow(
        keyPath: 'home.welcome',
        valuesByLocale: <String, dynamic>{
          'en': 'Welcome back, {name}',
          'tr': 'Tekrar hos geldin, {name}',
          'ar': 'مرحبا بعودتك، {name}',
        },
        cellStates: <String, CatalogCellState>{},
        rowStatus: CatalogCellStatus.warning,
        pendingLocales: <String>[],
        missingLocales: <String>[],
        note: 'Shown on the dashboard header.',
      ),
    ),
    _recalculateRow(
      const CatalogRow(
        keyPath: 'checkout.items_count',
        valuesByLocale: <String, dynamic>{
          'en': <String, dynamic>{
            'one': 'You have one item',
            'other': 'You have {count} items',
          },
          'tr': <String, dynamic>{
            'one': 'Bir urunun var',
            'other': '{count} urunun var',
          },
          'ar': <String, dynamic>{
            'one': 'لديك عنصر واحد',
            'other': '',
          },
        },
        cellStates: <String, CatalogCellState>{},
        rowStatus: CatalogCellStatus.warning,
        pendingLocales: <String>[],
        missingLocales: <String>[],
        note: 'Pluralized count shown in checkout summary.',
      ),
    ),
    _recalculateRow(
      const CatalogRow(
        keyPath: 'settings.delete_account',
        valuesByLocale: <String, dynamic>{
          'en': 'Delete account',
          'tr': 'Hesabi sil',
          'ar': '',
        },
        cellStates: <String, CatalogCellState>{},
        rowStatus: CatalogCellStatus.red,
        pendingLocales: <String>[],
        missingLocales: <String>[],
      ),
    ),
    _recalculateRow(
      const CatalogRow(
        keyPath: 'profile.member_since',
        valuesByLocale: <String, dynamic>{
          'en': 'Member since {date}',
          'tr': '{date} tarihinden beri uye',
          'ar': 'عضو منذ {date}',
        },
        cellStates: <String, CatalogCellState>{
          'en': CatalogCellState(status: CatalogCellStatus.green),
          'tr': CatalogCellState(status: CatalogCellStatus.green),
          'ar': CatalogCellState(status: CatalogCellStatus.green),
        },
        rowStatus: CatalogCellStatus.green,
        pendingLocales: <String>[],
        missingLocales: <String>[],
      ),
    ),
  ];
}

Map<String, List<CatalogActivityEvent>> _buildPreviewActivities() {
  return <String, List<CatalogActivityEvent>>{
    'home.welcome': <CatalogActivityEvent>[
      CatalogActivityEvent(
        kind: CatalogActivityKinds.targetUpdated,
        timestamp: DateTime.utc(2026, 3, 11, 9, 50),
        locale: 'ar',
      ),
      CatalogActivityEvent(
        kind: CatalogActivityKinds.noteUpdated,
        timestamp: DateTime.utc(2026, 3, 11, 9, 45),
      ),
      CatalogActivityEvent(
        kind: CatalogActivityKinds.keyCreated,
        timestamp: DateTime.utc(2026, 3, 10, 16, 30),
      ),
    ],
    'checkout.items_count': <CatalogActivityEvent>[
      CatalogActivityEvent(
        kind: CatalogActivityKinds.targetUpdated,
        timestamp: DateTime.utc(2026, 3, 11, 9, 55),
        locale: 'tr',
      ),
      CatalogActivityEvent(
        kind: CatalogActivityKinds.sourceUpdated,
        timestamp: DateTime.utc(2026, 3, 11, 9, 40),
      ),
      CatalogActivityEvent(
        kind: CatalogActivityKinds.keyCreated,
        timestamp: DateTime.utc(2026, 3, 10, 12, 0),
      ),
    ],
    'settings.delete_account': <CatalogActivityEvent>[
      CatalogActivityEvent(
        kind: CatalogActivityKinds.valueDeleted,
        timestamp: DateTime.utc(2026, 3, 11, 8, 45),
        locale: 'ar',
      ),
      CatalogActivityEvent(
        kind: CatalogActivityKinds.sourceUpdated,
        timestamp: DateTime.utc(2026, 3, 11, 8, 30),
      ),
    ],
    'profile.member_since': <CatalogActivityEvent>[
      CatalogActivityEvent(
        kind: CatalogActivityKinds.localeReviewed,
        timestamp: DateTime.utc(2026, 3, 10, 18, 20),
        locale: 'tr',
      ),
      CatalogActivityEvent(
        kind: CatalogActivityKinds.keyCreated,
        timestamp: DateTime.utc(2026, 3, 10, 14, 0),
      ),
    ],
  };
}
