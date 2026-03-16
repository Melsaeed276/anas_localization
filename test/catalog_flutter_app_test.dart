import 'package:anas_localization/src/catalog/catalog_client.dart';
import 'package:anas_localization/src/catalog/catalog_flutter_app.dart';
import 'package:anas_localization/src/catalog/catalog_models.dart';
import 'package:anas_localization/src/features/catalog/presentation/screens/catalog_preferences_controller.dart';
import 'package:anas_localization/src/features/catalog/presentation/screens/catalog_workspace_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('compact layout opens detail only after tapping a row', (tester) async {
    await _pumpCatalogApp(
      tester,
      size: const Size(500, 900),
    );

    expect(find.byKey(const ValueKey<String>('catalog-search-field')), findsOneWidget);
    expect(find.text('Overview'), findsNothing);

    await _openQueueRow(tester, 'home.title');

    expect(find.text('Overview'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await _settleCatalogUi(tester);

    expect(find.text('Overview'), findsNothing);
    expect(find.byKey(const ValueKey<String>('catalog-search-field')), findsOneWidget);
  });

  testWidgets('expanded layout supports theme and display-language switching', (tester) async {
    await _pumpCatalogApp(tester);

    expect(find.text('Theme: System'), findsOneWidget);
    expect(find.text('Catalog Language: EN'), findsOneWidget);

    await tester.tap(find.text('Theme: System'));
    await _settleCatalogUi(tester);
    await tester.tap(find.text('Dark').last);
    await _settleCatalogUi(tester);

    final appAfterTheme = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(appAfterTheme.themeMode, ThemeMode.dark);
    expect(find.text('Theme: Dark'), findsOneWidget);

    await tester.tap(find.text('Catalog Language: EN'));
    await _settleCatalogUi(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('AR'),
      ),
    );
    await _settleCatalogUi(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Confirm'),
      ),
    );
    await _settleCatalogUi(tester);

    expect(find.text('فهرس أنس'), findsOneWidget);
    expect(find.text('لغة الفهرس: AR'), findsOneWidget);

    final directionality = tester.widget<Directionality>(find.byType(Directionality).first);
    expect(directionality.textDirection, TextDirection.rtl);
  });

  testWidgets('expanded layout opens the inspector side sheet sections', (tester) async {
    await _pumpCatalogApp(tester);

    expect(find.text('Translation Queue'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('queue-section-missing')), findsOneWidget);
    expect(find.text('Review pending locales'), findsOneWidget);

    // Select a row first to enable the inspector button
    await _openQueueRow(tester, 'home.title');
    await _settleCatalogUi(tester);

    expect(find.byKey(const ValueKey<String>('inspector-sheet-trigger-details')), findsOneWidget);
    expect(find.text('Key created'), findsNothing);

    // Scroll to make the button visible
    await tester.ensureVisible(find.byKey(const ValueKey<String>('inspector-sheet-trigger-details')));
    await _settleCatalogUi(tester);

    await tester.tap(find.byKey(const ValueKey<String>('inspector-sheet-trigger-details')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('catalog-inspector-sheet')), findsOneWidget);
    expect(find.text('Placeholders'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey<String>('inspector-sheet-tab-activity')));
    await tester.tap(find.byKey(const ValueKey<String>('inspector-sheet-tab-activity')));
    await tester.pumpAndSettle();
    expect(find.text('Key created'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey<String>('inspector-sheet-tab-catalog-context')));
    await tester.tap(find.byKey(const ValueKey<String>('inspector-sheet-tab-catalog-context')));
    await tester.pumpAndSettle();
    expect(find.text('State file'), findsOneWidget);
  });

  testWidgets('review pending locales triggers bulk review for the selected key', (tester) async {
    final client = _FakeCatalogApiClient();
    await _pumpCatalogApp(
      tester,
      client: client,
    );

    // Select a row with pending locales first
    await _openQueueRow(tester, 'home.title');
    await _settleCatalogUi(tester);

    // Scroll to make the button visible and click it
    await tester.ensureVisible(find.text('Review pending locales'));
    await _settleCatalogUi(tester);

    await tester.tap(find.text('Review pending locales'));
    await _settleCatalogUi(tester);

    expect(client.bulkReviewCalls, hasLength(1));
    expect(
      client.bulkReviewCalls.single.map((item) => '${item.keyPath}:${item.locale}'),
      unorderedEquals(<String>[
        'home.title:tr',
        'home.title:ar',
      ]),
    );
  });

  testWidgets('editor direction follows locale even when catalog chrome is Arabic', (tester) async {
    await _pumpCatalogApp(
      tester,
      language: CatalogDisplayLanguage.ar,
    );

    expect(find.text('فهرس أنس'), findsOneWidget);
    await _revealInInspector(tester, find.textContaining('TR ·'));
    await tester.tap(find.textContaining('TR ·').first);
    await _settleCatalogUi(tester);
    await _revealInInspector(tester, find.byKey(const ValueKey<String>('plain-home.title-tr')));

    EditableText trEditor() => tester.widget<EditableText>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('plain-home.title-tr')),
            matching: find.byType(EditableText),
          ),
        );

    expect(trEditor().textDirection, TextDirection.ltr);

    await _revealInInspector(tester, find.textContaining('AR ·'));
    await tester.tap(find.textContaining('AR ·'));
    await _settleCatalogUi(tester);
    await _revealInInspector(tester, find.byKey(const ValueKey<String>('plain-home.title-ar')));

    final arEditor = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('plain-home.title-ar')),
        matching: find.byType(EditableText),
      ),
    );
    expect(arEditor.textDirection, TextDirection.rtl);
  });

  testWidgets('editing a note autosaves through the API client', (tester) async {
    final client = _FakeCatalogApiClient();
    await _pumpCatalogApp(
      tester,
      client: client,
    );

    await _revealInInspector(tester, find.byKey(const ValueKey<String>('note-home.title')));
    await tester.enterText(
      find.byKey(const ValueKey<String>('note-home.title')),
      'Shown on the storefront hero',
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(client.noteUpdates, <String>['Shown on the storefront hero']);
    expect(find.byIcon(Icons.sticky_note_2_outlined), findsWidgets);

    await tester.pump(const Duration(milliseconds: 1300));
  });

  testWidgets('new string dialog sends the optional note and adds the row', (tester) async {
    final client = _FakeCatalogApiClient();
    await _pumpCatalogApp(
      tester,
      client: client,
    );

    await tester.tap(find.text('New String'));
    await _settleCatalogUi(tester);

    final dialog = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.widgetWithText(TextField, 'Key path')),
      'checkout.summary.title',
    );
    await tester.enterText(
      find.descendant(of: dialog, matching: find.widgetWithText(TextField, 'Key note')),
      'Shown in checkout summary',
    );
    await tester.enterText(
      find.descendant(of: dialog, matching: find.widgetWithText(TextField, 'EN · Source')),
      'Summary',
    );
    await tester.enterText(
      find.descendant(of: dialog, matching: find.widgetWithText(TextField, 'TR')),
      'Ozet',
    );
    await tester.enterText(
      find.descendant(of: dialog, matching: find.widgetWithText(TextField, 'AR')),
      'الملخص',
    );

    await tester.tap(find.text('Create'));
    await _settleCatalogUi(tester);

    expect(client.addedNotes, <String>['Shown in checkout summary']);
    expect(find.text('checkout.summary.title'), findsWidgets);
  });
}

Future<_AppHarness> _pumpCatalogApp(
  WidgetTester tester, {
  Size size = const Size(1280, 900),
  CatalogDisplayLanguage language = CatalogDisplayLanguage.en,
  CatalogThemeMode themeMode = CatalogThemeMode.system,
  _FakeCatalogApiClient? client,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final apiClient = client ?? _FakeCatalogApiClient();
  final workspaceController = CatalogWorkspaceController(client: apiClient);
  final preferencesController = _TestPreferencesController(
    displayLanguage: language,
    themeMode: themeMode,
  );

  addTearDown(workspaceController.dispose);
  addTearDown(preferencesController.dispose);

  await workspaceController.initialize();

  await tester.pumpWidget(
    CatalogApp(
      workspaceController: workspaceController,
      preferencesController: preferencesController,
    ),
  );
  await _settleCatalogUi(tester);

  return _AppHarness(
    client: apiClient,
    workspaceController: workspaceController,
    preferencesController: preferencesController,
  );
}

Future<void> _settleCatalogUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _openQueueRow(WidgetTester tester, String keyPath) async {
  final finder = find.byKey(ValueKey<String>('queue-row-$keyPath'));
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
  await _settleCatalogUi(tester);
}

Future<void> _revealInInspector(WidgetTester tester, Finder finder) async {
  final scrollable = find.byKey(const ValueKey<String>('catalog-inspector-list'));
  for (var attempt = 0; attempt < 5 && finder.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -240));
    await _settleCatalogUi(tester);
  }
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder.first);
    await _settleCatalogUi(tester);
  }
}

class _AppHarness {
  _AppHarness({
    required this.client,
    required this.workspaceController,
    required this.preferencesController,
  });

  final _FakeCatalogApiClient client;
  final CatalogWorkspaceController workspaceController;
  final _TestPreferencesController preferencesController;
}

class _TestPreferencesController extends CatalogPreferencesController {
  _TestPreferencesController({
    CatalogThemeMode themeMode = CatalogThemeMode.system,
    CatalogDisplayLanguage displayLanguage = CatalogDisplayLanguage.en,
  })  : _themeMode = themeMode,
        _displayLanguage = displayLanguage;

  CatalogThemeMode _themeMode;
  CatalogDisplayLanguage _displayLanguage;

  @override
  CatalogThemeMode get themeMode => _themeMode;

  @override
  CatalogDisplayLanguage get displayLanguage => _displayLanguage;

  @override
  bool get loaded => true;

  @override
  Future<void> load() async {}

  @override
  Future<void> setDisplayLanguage(CatalogDisplayLanguage language) async {
    _displayLanguage = language;
    notifyListeners();
  }

  @override
  Future<void> setThemeMode(CatalogThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
  }
}

class _FakeCatalogApiClient extends CatalogApiClient {
  _FakeCatalogApiClient() : super(baseUri: Uri.parse('http://127.0.0.1:0'));

  final List<String> noteUpdates = <String>[];
  final List<String> addedNotes = <String>[];
  final List<List<CatalogReviewTarget>> bulkReviewCalls = <List<CatalogReviewTarget>>[];
  final List<CatalogRow> _rows = <CatalogRow>[
    const CatalogRow(
      keyPath: 'profile.ready',
      valuesByLocale: <String, dynamic>{
        'en': 'Ready',
        'tr': 'Hazir',
        'ar': 'جاهز',
      },
      cellStates: <String, CatalogCellState>{
        'en': CatalogCellState(status: CatalogCellStatus.green),
        'tr': CatalogCellState(status: CatalogCellStatus.green),
        'ar': CatalogCellState(status: CatalogCellStatus.green),
      },
      rowStatus: CatalogCellStatus.green,
      pendingLocales: <String>[],
      missingLocales: <String>[],
      note: 'Shown in compact confirmations',
    ),
    const CatalogRow(
      keyPath: 'home.title',
      valuesByLocale: <String, dynamic>{
        'en': 'Home',
        'tr': 'Ana Sayfa',
        'ar': 'الرئيسية',
      },
      cellStates: <String, CatalogCellState>{
        'en': CatalogCellState(status: CatalogCellStatus.green),
        'tr': CatalogCellState(status: CatalogCellStatus.warning),
        'ar': CatalogCellState(status: CatalogCellStatus.warning),
      },
      rowStatus: CatalogCellStatus.warning,
      pendingLocales: <String>['tr', 'ar'],
      missingLocales: <String>[],
    ),
    const CatalogRow(
      keyPath: 'settings.body',
      valuesByLocale: <String, dynamic>{
        'en': 'Continue',
        'tr': 'Devam et',
        'ar': '',
      },
      cellStates: <String, CatalogCellState>{
        'en': CatalogCellState(status: CatalogCellStatus.green),
        'tr': CatalogCellState(status: CatalogCellStatus.green),
        'ar': CatalogCellState(status: CatalogCellStatus.red),
      },
      rowStatus: CatalogCellStatus.red,
      pendingLocales: <String>[],
      missingLocales: <String>['ar'],
    ),
  ];
  final Map<String, List<CatalogActivityEvent>> _activityByKey = <String, List<CatalogActivityEvent>>{
    'profile.ready': <CatalogActivityEvent>[
      CatalogActivityEvent(
        kind: CatalogActivityKinds.keyCreated,
        timestamp: DateTime.utc(2026, 3, 10, 10),
      ),
      CatalogActivityEvent(
        kind: CatalogActivityKinds.localeReviewed,
        timestamp: DateTime.utc(2026, 3, 10, 10, 30),
        locale: 'tr',
      ),
    ],
    'home.title': <CatalogActivityEvent>[
      CatalogActivityEvent(
        kind: CatalogActivityKinds.keyCreated,
        timestamp: DateTime.utc(2026, 3, 10, 11),
      ),
      CatalogActivityEvent(
        kind: CatalogActivityKinds.targetUpdated,
        timestamp: DateTime.utc(2026, 3, 10, 11, 5),
        locale: 'tr',
      ),
    ],
    'settings.body': <CatalogActivityEvent>[
      CatalogActivityEvent(
        kind: CatalogActivityKinds.keyCreated,
        timestamp: DateTime.utc(2026, 3, 10, 9),
      ),
      CatalogActivityEvent(
        kind: CatalogActivityKinds.targetUpdated,
        timestamp: DateTime.utc(2026, 3, 10, 9, 15),
        locale: 'tr',
      ),
    ],
  };

  @override
  Future<CatalogMeta> loadMeta() async {
    return const CatalogMeta(
      locales: <String>['en', 'tr', 'ar'],
      localeDirections: <String, String>{
        'en': 'ltr',
        'tr': 'ltr',
        'ar': 'rtl',
      },
      sourceLocale: 'en',
      fallbackLocale: 'en',
      langDirectory: '/tmp/lang',
      format: 'json',
      stateFilePath: '/tmp/catalog_state.json',
      uiPort: 0,
      apiPort: 0,
    );
  }

  @override
  Future<List<CatalogRow>> loadRows({
    String search = '',
    String status = '',
  }) async {
    return _rows.where((row) {
      final matchesStatus = status.isEmpty || row.rowStatus.name == status;
      final haystack = <String>[
        row.keyPath,
        row.note ?? '',
        ...row.valuesByLocale.values.map((value) => value?.toString() ?? ''),
      ].join(' ').toLowerCase();
      final matchesSearch = search.trim().isEmpty || haystack.contains(search.trim().toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Future<CatalogSummary> loadSummary() async {
    var greenRows = 0;
    var warningRows = 0;
    var redRows = 0;
    var greenCount = 0;
    var warningCount = 0;
    var redCount = 0;
    for (final row in _rows) {
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
      totalKeys: _rows.length,
      greenCount: greenCount,
      warningCount: warningCount,
      redCount: redCount,
      greenRows: greenRows,
      warningRows: warningRows,
      redRows: redRows,
    );
  }

  @override
  Future<List<CatalogActivityEvent>> loadActivity({
    required String keyPath,
  }) async {
    return List<CatalogActivityEvent>.from(_activityByKey[keyPath] ?? const <CatalogActivityEvent>[]);
  }

  @override
  Future<CatalogRow> addKey({
    required String keyPath,
    required Map<String, dynamic> valuesByLocale,
    String? note,
    bool markGreenIfComplete = true,
  }) async {
    addedNotes.add(note ?? '');
    final sourceValue = valuesByLocale['en']?.toString() ?? '';
    final trValue = valuesByLocale['tr']?.toString() ?? '';
    final arValue = valuesByLocale['ar']?.toString() ?? '';
    final row = CatalogRow(
      keyPath: keyPath,
      valuesByLocale: <String, dynamic>{
        'en': sourceValue,
        'tr': trValue,
        'ar': arValue,
      },
      cellStates: <String, CatalogCellState>{
        'en': const CatalogCellState(status: CatalogCellStatus.green),
        'tr': CatalogCellState(
          status: trValue.isEmpty ? CatalogCellStatus.red : CatalogCellStatus.warning,
        ),
        'ar': CatalogCellState(
          status: arValue.isEmpty ? CatalogCellStatus.red : CatalogCellStatus.warning,
        ),
      },
      rowStatus: trValue.isEmpty || arValue.isEmpty ? CatalogCellStatus.red : CatalogCellStatus.warning,
      pendingLocales: <String>[
        if (trValue.isNotEmpty) 'tr',
        if (arValue.isNotEmpty) 'ar',
      ],
      missingLocales: <String>[
        if (trValue.isEmpty) 'tr',
        if (arValue.isEmpty) 'ar',
      ],
      note: note,
    );
    _rows.add(row);
    _rows.sort((a, b) => a.keyPath.compareTo(b.keyPath));
    _activityByKey[keyPath] = <CatalogActivityEvent>[
      CatalogActivityEvent(
        kind: CatalogActivityKinds.keyCreated,
        timestamp: DateTime.utc(2026, 3, 10, 12),
      ),
    ];
    return row;
  }

  @override
  Future<CatalogRow> updateKeyNote({
    required String keyPath,
    String? note,
  }) async {
    noteUpdates.add(note ?? '');
    final index = _rows.indexWhere((row) => row.keyPath == keyPath);
    final current = _rows[index];
    final updated = CatalogRow(
      keyPath: current.keyPath,
      valuesByLocale: current.valuesByLocale,
      cellStates: current.cellStates,
      rowStatus: current.rowStatus,
      pendingLocales: current.pendingLocales,
      missingLocales: current.missingLocales,
      note: note,
    );
    _rows[index] = updated;
    _activityByKey.putIfAbsent(keyPath, () => <CatalogActivityEvent>[]).insert(
          0,
          CatalogActivityEvent(
            kind: CatalogActivityKinds.noteUpdated,
            timestamp: DateTime.utc(2026, 3, 10, 12, 5),
          ),
        );
    return updated;
  }

  @override
  Future<CatalogBulkReviewResult> bulkReview({
    required List<CatalogReviewTarget> targets,
  }) async {
    bulkReviewCalls.add(List<CatalogReviewTarget>.from(targets));
    return CatalogBulkReviewResult(
      reviewedCount: targets.length,
    );
  }
}
