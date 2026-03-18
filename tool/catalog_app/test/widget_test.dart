import 'dart:ui';

import 'package:anas_localization/catalog.dart';
import 'package:catalog_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('wrapper app boots the catalog shell', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = _TestPreferencesController();

    await tester.pumpWidget(
      CatalogWebAppRoot(
        bootstrapLoader: () async => const CatalogBootstrapConfig(
          apiUrl: 'http://127.0.0.1:0',
        ),
        clientFactory: (_) => _FakeCatalogApiClient(),
        preferencesController: preferences,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Anas Catalog'), findsOneWidget);
    expect(find.text('Translation Queue'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Catalog Language: EN'), findsOneWidget);
  });
}

class _TestPreferencesController extends CatalogPreferencesController {
  CatalogThemeMode _themeMode = CatalogThemeMode.system;
  CatalogDisplayLanguage _displayLanguage = CatalogDisplayLanguage.en;

  @override
  CatalogThemeMode get themeMode => _themeMode;

  @override
  CatalogDisplayLanguage get displayLanguage => _displayLanguage;

  @override
  bool get loaded => true;

  @override
  Future<void> load({String? fallbackLocale}) async {}

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
    return const <CatalogRow>[
      CatalogRow(
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
        note: 'Visible on the landing page',
      ),
    ];
  }

  @override
  Future<CatalogSummary> loadSummary() async {
    return const CatalogSummary(
      totalKeys: 1,
      greenCount: 1,
      warningCount: 2,
      redCount: 0,
      greenRows: 0,
      warningRows: 1,
      redRows: 0,
    );
  }

  @override
  Future<List<CatalogActivityEvent>> loadActivity({
    required String keyPath,
  }) async {
    return <CatalogActivityEvent>[
      CatalogActivityEvent(
        kind: CatalogActivityKinds.keyCreated,
        timestamp: DateTime.utc(2026, 3, 10, 10),
      ),
    ];
  }
}
