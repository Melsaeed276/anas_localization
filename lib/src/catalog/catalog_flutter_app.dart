library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_client.dart';
import 'catalog_flatten.dart';
import 'catalog_models.dart';
import 'catalog_status_engine.dart';
import 'catalog_ui_logic.dart';
import 'l10n/generated/catalog_localizations.dart';

const String _catalogThemeModeStorageKey = 'anasCatalog.themeMode';
const String _catalogDisplayLanguageStorageKey = 'anasCatalog.displayLanguage';

enum CatalogThemeMode {
  system,
  light,
  dark,
}

enum CatalogDisplayLanguage {
  en('en', Locale('en')),
  ar('ar', Locale('ar')),
  tr('tr', Locale('tr')),
  es('es', Locale('es')),
  hi('hi', Locale('hi')),
  zhCn('zh-CN', Locale('zh', 'CN'));

  const CatalogDisplayLanguage(this.code, this.locale);

  final String code;
  final Locale locale;

  static CatalogDisplayLanguage fromCode(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized == 'zh-cn' || normalized == 'zh_cn' || normalized == 'zh') {
      return CatalogDisplayLanguage.zhCn;
    }
    for (final language in values) {
      if (normalized == language.code.toLowerCase()) {
        return language;
      }
    }
    return CatalogDisplayLanguage.en;
  }
}

class CatalogBootstrapApp extends StatefulWidget {
  const CatalogBootstrapApp({
    super.key,
    this.bootstrapLoader,
    this.clientFactory,
    this.preferencesController,
  });

  final Future<CatalogBootstrapConfig> Function()? bootstrapLoader;
  final CatalogApiClient Function(Uri baseUri)? clientFactory;
  final CatalogPreferencesController? preferencesController;

  @override
  State<CatalogBootstrapApp> createState() => _CatalogBootstrapAppState();
}

class _CatalogBootstrapAppState extends State<CatalogBootstrapApp> {
  CatalogWorkspaceController? _workspaceController;
  CatalogPreferencesController? _preferencesController;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _workspaceController?.dispose();
    if (widget.preferencesController == null) {
      _preferencesController?.dispose();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    final preferencesController = widget.preferencesController ?? CatalogPreferencesController();
    try {
      await preferencesController.load();
      final config = await (widget.bootstrapLoader ?? loadCatalogBootstrapConfig)();
      final client = (widget.clientFactory ?? _defaultCatalogClientFactory)(Uri.parse(config.apiUrl));
      final workspaceController = CatalogWorkspaceController(client: client);
      await workspaceController.initialize();
      if (!mounted) {
        workspaceController.dispose();
        if (widget.preferencesController == null) {
          preferencesController.dispose();
        }
        return;
      }
      setState(() {
        _preferencesController = preferencesController;
        _workspaceController = workspaceController;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _preferencesController = preferencesController;
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_error != null || _workspaceController == null || _preferencesController == null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error ?? 'Could not load catalog bootstrap.'),
            ),
          ),
        ),
      );
    }

    return CatalogApp(
      workspaceController: _workspaceController!,
      preferencesController: _preferencesController!,
    );
  }
}

CatalogApiClient _defaultCatalogClientFactory(Uri baseUri) {
  return CatalogApiClient(baseUri: baseUri);
}

Future<CatalogBootstrapConfig> loadCatalogBootstrapConfig() async {
  final bootstrapUri = Uri.base.resolve('catalog-bootstrap.json');
  final response = await http.get(bootstrapUri);
  final payload =
      response.body.trim().isEmpty ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw CatalogClientException(payload['error']?.toString() ?? 'Could not load catalog bootstrap.');
  }
  return CatalogBootstrapConfig.fromJson(payload);
}

class CatalogApp extends StatefulWidget {
  const CatalogApp({
    super.key,
    required this.workspaceController,
    required this.preferencesController,
  });

  final CatalogWorkspaceController workspaceController;
  final CatalogPreferencesController preferencesController;

  @override
  State<CatalogApp> createState() => _CatalogAppState();
}

class _CatalogAppState extends State<CatalogApp> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        widget.workspaceController,
        widget.preferencesController,
      ]),
      builder: (context, _) {
        final preferences = widget.preferencesController;
        return MaterialApp(
          locale: preferences.displayLanguage.locale,
          supportedLocales: CatalogLocalizations.supportedLocales,
          localizationsDelegates: CatalogLocalizations.localizationsDelegates,
          debugShowCheckedModeBanner: false,
          title: 'Anas Catalog',
          themeMode: preferences.themeMode.flutterThemeMode,
          theme: _buildCatalogTheme(Brightness.light),
          darkTheme: _buildCatalogTheme(Brightness.dark),
          home: _CatalogHome(
            workspaceController: widget.workspaceController,
            preferencesController: preferences,
          ),
        );
      },
    );
  }
}

ThemeData _buildCatalogTheme(Brightness brightness) {
  final seed = brightness == Brightness.light ? const Color(0xFF355D91) : const Color(0xFF97B7F4);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surfaceContainerLowest,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surfaceContainerLowest,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: scheme.outlineVariant,
        ),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll<Color>(scheme.surface),
      elevation: const WidgetStatePropertyAll<double>(0),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsets>(
        EdgeInsets.symmetric(horizontal: 16),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

class CatalogPreferencesController extends ChangeNotifier {
  CatalogThemeMode _themeMode = CatalogThemeMode.system;
  CatalogDisplayLanguage _displayLanguage = CatalogDisplayLanguage.en;
  bool _loaded = false;

  CatalogThemeMode get themeMode => _themeMode;
  CatalogDisplayLanguage get displayLanguage => _displayLanguage;
  bool get loaded => _loaded;

  Future<void> load() async {
    final storage = await SharedPreferences.getInstance();
    final storedTheme = storage.getString(_catalogThemeModeStorageKey);
    final storedLanguage = storage.getString(_catalogDisplayLanguageStorageKey);

    _themeMode = switch (storedTheme) {
      'light' => CatalogThemeMode.light,
      'dark' => CatalogThemeMode.dark,
      _ => CatalogThemeMode.system,
    };

    if (storedLanguage != null && storedLanguage.trim().isNotEmpty) {
      _displayLanguage = CatalogDisplayLanguage.fromCode(storedLanguage);
    } else {
      final platformLocale = PlatformDispatcher.instance.locale;
      _displayLanguage = CatalogDisplayLanguage.fromCode(
        platformLocale.countryCode == null || platformLocale.countryCode!.isEmpty
            ? platformLocale.languageCode
            : '${platformLocale.languageCode}-${platformLocale.countryCode}',
      );
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(CatalogThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    final storage = await SharedPreferences.getInstance();
    await storage.setString(_catalogThemeModeStorageKey, mode.storageValue);
  }

  Future<void> setDisplayLanguage(CatalogDisplayLanguage language) async {
    if (_displayLanguage == language) {
      return;
    }
    _displayLanguage = language;
    notifyListeners();
    final storage = await SharedPreferences.getInstance();
    await storage.setString(_catalogDisplayLanguageStorageKey, language.code);
  }
}

extension on CatalogThemeMode {
  ThemeMode get flutterThemeMode => switch (this) {
        CatalogThemeMode.system => ThemeMode.system,
        CatalogThemeMode.light => ThemeMode.light,
        CatalogThemeMode.dark => ThemeMode.dark,
      };

  String get storageValue => switch (this) {
        CatalogThemeMode.system => 'system',
        CatalogThemeMode.light => 'light',
        CatalogThemeMode.dark => 'dark',
      };
}

const String _catalogQueueSortModeStorageKey = 'anasCatalog.queueSortMode';
const String _catalogCollapsedSectionsStorageKey = 'anasCatalog.collapsedSections';
const String _catalogLastSelectedLocaleStorageKey = 'anasCatalog.lastSelectedLocale';

enum CatalogQueueSortMode {
  alphabetical,
  namespace,
}

enum CatalogQueueSection {
  missing('missing', CatalogCellStatus.red),
  needsReview('needsReview', CatalogCellStatus.warning),
  ready('ready', CatalogCellStatus.green);

  const CatalogQueueSection(this.storageValue, this.status);

  final String storageValue;
  final CatalogCellStatus status;
}

enum CatalogRowStatusFilter {
  all(''),
  ready('green'),
  needsReview('warning'),
  missing('red');

  const CatalogRowStatusFilter(this.apiValue);

  final String apiValue;
}

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

class _CatalogHome extends StatefulWidget {
  const _CatalogHome({
    required this.workspaceController,
    required this.preferencesController,
  });

  final CatalogWorkspaceController workspaceController;
  final CatalogPreferencesController preferencesController;

  @override
  State<_CatalogHome> createState() => _CatalogHomeState();
}

class _CatalogHomeState extends State<_CatalogHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  _CatalogInspectorSheetSection _activeInspectorSheetSection = _CatalogInspectorSheetSection.sourceContext;

  void _setInspectorSheetSection(_CatalogInspectorSheetSection section) {
    if (_activeInspectorSheetSection == section) {
      return;
    }
    setState(() {
      _activeInspectorSheetSection = section;
    });
  }

  void _openInspectorSheet() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final selectedRow = widget.workspaceController.selectedRow;
    final width = MediaQuery.sizeOf(context).width;
    final layout = width < 600
        ? _CatalogLayout.compact
        : width < 840
            ? _CatalogLayout.medium
            : _CatalogLayout.expanded;
    final showCompactDetail =
        layout == _CatalogLayout.compact && widget.workspaceController.compactDetailOpen && selectedRow != null;
    final selectedLocale = widget.workspaceController.selectedLocale ?? widget.workspaceController.defaultEditorLocale;

    return Scaffold(
      key: _scaffoldKey,
      endDrawerEnableOpenDragGesture: false,
      endDrawer: _CatalogInspectorSideSheet(
        controller: widget.workspaceController,
        row: selectedRow,
        locale: selectedLocale,
        selectedSection: _activeInspectorSheetSection,
        onSectionSelected: _setInspectorSheetSection,
      ),
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: false,
        leading: showCompactDetail
            ? IconButton(
                tooltip: l10n.backLabel,
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  widget.workspaceController.clearSelection();
                },
              )
            : null,
        actions: <Widget>[
          IconButton(
            tooltip: l10n.refresh,
            onPressed: widget.workspaceController.refresh,
            icon: const Icon(Icons.refresh),
          ),
          _ThemeMenu(
            preferencesController: widget.preferencesController,
            compact: layout != _CatalogLayout.expanded,
          ),
          _DisplayLanguageButton(
            preferencesController: widget.preferencesController,
            compact: layout != _CatalogLayout.expanded,
          ),
          if (layout == _CatalogLayout.expanded)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: FilledButton.icon(
                onPressed: () => _showCreateKeyDialog(context, widget.workspaceController),
                icon: const Icon(Icons.add),
                label: Text(l10n.newString),
              ),
            )
          else
            IconButton(
              tooltip: l10n.newString,
              onPressed: () => _showCreateKeyDialog(context, widget.workspaceController),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      bottomNavigationBar: showCompactDetail
          ? _CompactInspectorActionBar(
              controller: widget.workspaceController,
              row: selectedRow,
              locale: selectedLocale,
            )
          : null,
      body: widget.workspaceController.loading && widget.workspaceController.meta == null
          ? const Center(child: CircularProgressIndicator())
          : widget.workspaceController.error != null && widget.workspaceController.meta == null
              ? _ErrorPane(
                  message: widget.workspaceController.error!,
                  onRetry: widget.workspaceController.refresh,
                )
              : SafeArea(
                  child: _CatalogWorkspaceBody(
                    controller: widget.workspaceController,
                    layout: layout,
                    onOpenInspectorSheet: selectedRow == null ? null : _openInspectorSheet,
                  ),
                ),
    );
  }
}

enum _CatalogLayout {
  compact,
  medium,
  expanded,
}

enum _CatalogInspectorSheetSection {
  sourceContext('source-context', Icons.article_outlined),
  catalogContext('catalog-context', Icons.info_outline),
  activity('activity', Icons.history_outlined);

  const _CatalogInspectorSheetSection(this.keyValue, this.icon);

  final String keyValue;
  final IconData icon;
}

class _CatalogWorkspaceBody extends StatelessWidget {
  const _CatalogWorkspaceBody({
    required this.controller,
    required this.layout,
    required this.onOpenInspectorSheet,
  });

  final CatalogWorkspaceController controller;
  final _CatalogLayout layout;
  final VoidCallback? onOpenInspectorSheet;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final selectedRow = controller.selectedRow;
    final selectedLocale = controller.selectedLocale ?? controller.defaultEditorLocale;
    final showCompactDetail = layout == _CatalogLayout.compact && controller.compactDetailOpen && selectedRow != null;

    if (layout == _CatalogLayout.compact) {
      if (!showCompactDetail) {
        return _CatalogQueuePane(
          controller: controller,
          layout: layout,
        );
      }
      return _CatalogInspectorPane(
        controller: controller,
        row: selectedRow,
        locale: selectedLocale,
        layout: layout,
        onOpenInspectorSheet: onOpenInspectorSheet,
      );
    }

    if (layout == _CatalogLayout.medium) {
      return Row(
        children: <Widget>[
          SizedBox(
            width: 380,
            child: _CatalogQueuePane(
              controller: controller,
              layout: layout,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: selectedRow == null
                ? _CatalogSelectionPlaceholder(
                    title: l10n.selectionPlaceholderTitle,
                    message: l10n.selectionPlaceholderBody,
                  )
                : _CatalogInspectorPane(
                    controller: controller,
                    row: selectedRow,
                    locale: selectedLocale,
                    layout: layout,
                    onOpenInspectorSheet: onOpenInspectorSheet,
                  ),
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        SizedBox(
          width: 392,
          child: _CatalogQueuePane(
            controller: controller,
            layout: layout,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 5,
          child: selectedRow == null
              ? _CatalogSelectionPlaceholder(
                  title: l10n.selectionPlaceholderTitle,
                  message: l10n.selectionPlaceholderBody,
                )
              : _CatalogInspectorPane(
                  controller: controller,
                  row: selectedRow,
                  locale: selectedLocale,
                  layout: layout,
                  onOpenInspectorSheet: onOpenInspectorSheet,
                ),
        ),
      ],
    );
  }
}

class _CatalogQueuePane extends StatelessWidget {
  const _CatalogQueuePane({
    required this.controller,
    required this.layout,
  });

  final CatalogWorkspaceController controller;
  final _CatalogLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = controller.summary;
    final visibleSections = controller.visibleSections
        .where(
            (section) => controller.statusFilter != CatalogRowStatusFilter.all || controller.sectionCount(section) > 0)
        .toList();

    Widget content;
    if (controller.loading && controller.rows.isEmpty) {
      content = const _CatalogQueueSkeleton();
    } else if (!controller.hasAnyKeys) {
      content = _CatalogEmptyStateCard(
        icon: Icons.add_chart_outlined,
        title: l10n.noKeysTitle,
        message: l10n.noKeysBody,
      );
    } else if (controller.rows.isEmpty) {
      content = _CatalogEmptyStateCard(
        icon: Icons.search_off_outlined,
        title: l10n.noResultsTitle,
        message: l10n.noResultsBody,
      );
    } else {
      content = ListView(
        key: const ValueKey<String>('catalog-queue-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: visibleSections.map((section) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CatalogQueueSectionCard(
              controller: controller,
              section: section,
              rows: controller.rowsForSection(section),
              compact: layout == _CatalogLayout.compact,
            ),
          );
        }).toList(),
      );
    }

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.queueTitle,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  _queueHeadline(l10n, summary),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _CatalogSearchField(
                  value: controller.search,
                  onChanged: controller.updateSearch,
                ),
                const SizedBox(height: 12),
                _CatalogQueueToolbar(
                  controller: controller,
                ),
                if (summary != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _CatalogSummaryStrip(summary: summary),
                ],
                if (controller.error != null && controller.meta != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _ErrorBanner(
                    message: controller.error!,
                    onRetry: controller.refresh,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _CatalogQueueToolbar extends StatelessWidget {
  const _CatalogQueueToolbar({
    required this.controller,
  });

  final CatalogWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ...CatalogRowStatusFilter.values.map((filter) {
              return FilterChip(
                selected: controller.statusFilter == filter,
                label: Text(_statusFilterLabel(l10n, filter)),
                onSelected: (_) {
                  controller.updateStatusFilter(filter);
                },
              );
            }),
            _CatalogSortMenu(
              current: controller.sortMode,
              onSelected: controller.updateSortMode,
            ),
          ],
        ),
      ],
    );
  }
}

class _CatalogSortMenu extends StatelessWidget {
  const _CatalogSortMenu({
    required this.current,
    required this.onSelected,
  });

  final CatalogQueueSortMode current;
  final Future<void> Function(CatalogQueueSortMode mode) onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    return PopupMenuButton<CatalogQueueSortMode>(
      initialValue: current,
      tooltip: l10n.sortLabel,
      onSelected: onSelected,
      itemBuilder: (context) => <PopupMenuEntry<CatalogQueueSortMode>>[
        PopupMenuItem<CatalogQueueSortMode>(
          value: CatalogQueueSortMode.alphabetical,
          child: Text(l10n.sortAlphabetical),
        ),
        PopupMenuItem<CatalogQueueSortMode>(
          value: CatalogQueueSortMode.namespace,
          child: Text(l10n.sortNamespace),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.swap_vert, size: 18),
            const SizedBox(width: 8),
            Text(
              '${l10n.sortLabel}: ${switch (current) {
                CatalogQueueSortMode.alphabetical => l10n.sortAlphabetical,
                CatalogQueueSortMode.namespace => l10n.sortNamespace,
              }}',
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogSummaryStrip extends StatelessWidget {
  const _CatalogSummaryStrip({
    required this.summary,
  });

  final CatalogSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _CatalogMetricChip(
          icon: Icons.key_outlined,
          value: summary.totalKeys.toString(),
          label: l10n.keysLabel,
        ),
        _CatalogMetricChip(
          icon: Icons.check_circle_outline,
          value: summary.greenRows.toString(),
          label: l10n.readyRowsLabel,
        ),
        _CatalogMetricChip(
          icon: Icons.fact_check_outlined,
          value: summary.warningRows.toString(),
          label: l10n.reviewRowsLabel,
        ),
        _CatalogMetricChip(
          icon: Icons.error_outline,
          value: summary.redRows.toString(),
          label: l10n.missingRowsLabel,
        ),
      ],
    );
  }
}

class _CatalogMetricChip extends StatelessWidget {
  const _CatalogMetricChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogSearchField extends StatefulWidget {
  const _CatalogSearchField({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_CatalogSearchField> createState() => _CatalogSearchFieldState();
}

class _CatalogSearchFieldState extends State<_CatalogSearchField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _CatalogSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    return SearchBar(
      key: const ValueKey<String>('catalog-search-field'),
      controller: _controller,
      hintText: l10n.searchHint,
      leading: const Icon(Icons.search),
      onChanged: widget.onChanged,
      elevation: const WidgetStatePropertyAll<double>(0),
    );
  }
}

class _CatalogQueueSectionCard extends StatelessWidget {
  const _CatalogQueueSectionCard({
    required this.controller,
    required this.section,
    required this.rows,
    required this.compact,
  });

  final CatalogWorkspaceController controller;
  final CatalogQueueSection section;
  final List<CatalogRow> rows;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final collapsed = controller.isSectionCollapsed(section);
    final theme = Theme.of(context);
    final headerColor = _statusColor(theme.colorScheme, section.status);
    return Card(
      key: ValueKey<String>('queue-section-${section.storageValue}'),
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          InkWell(
            onTap: () => controller.setSectionCollapsed(section, !collapsed),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: headerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _queueSectionLabel(l10n, section),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      rows.length.toString(),
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(collapsed ? Icons.expand_more : Icons.expand_less),
                ],
              ),
            ),
          ),
          if (!collapsed) ...<Widget>[
            const Divider(height: 1),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.sectionEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: rows.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _CatalogQueueRowCard(
                    controller: controller,
                    row: rows[index],
                    compact: compact,
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _CatalogQueueRowCard extends StatelessWidget {
  const _CatalogQueueRowCard({
    required this.controller,
    required this.row,
    required this.compact,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow row;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final theme = Theme.of(context);
    final meta = controller.meta!;
    final selected = row.keyPath == controller.selectedKey;
    final rowSyncState = controller.rowSyncState(row.keyPath);
    final progress = _targetLocaleProgress(row, meta);
    final statusColor = _statusColor(theme.colorScheme, row.rowStatus);

    return Material(
      key: ValueKey<String>('queue-row-${row.keyPath}'),
      color: selected ? theme.colorScheme.secondaryContainer : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => controller.selectRow(row.keyPath),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? theme.colorScheme.primary.withOpacity(0.28) : theme.colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: selected ? theme.colorScheme.primary : statusColor,
                    borderRadius: const BorderRadiusDirectional.only(
                      topStart: Radius.circular(18),
                      bottomStart: Radius.circular(18),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                row.keyPath,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if ((row.note ?? '').trim().isNotEmpty)
                              Tooltip(
                                message: l10n.noteIndicator,
                                child: Icon(
                                  Icons.sticky_note_2_outlined,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            const SizedBox(width: 8),
                            _QueueSyncIndicator(state: rowSyncState),
                            if (compact) ...<Widget>[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _rowSummaryText(l10n, row),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            _StatusChip(
                              label: _statusLabel(l10n, row.rowStatus.name),
                              status: row.rowStatus.name,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${progress.ready}/${progress.total}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                l10n.localesSection,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            value: progress.total == 0 ? 0 : progress.ready / progress.total,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QueueSyncIndicator extends StatelessWidget {
  const _QueueSyncIndicator({
    required this.state,
  });

  final CatalogDraftSyncState state;

  @override
  Widget build(BuildContext context) {
    if (state == CatalogDraftSyncState.clean) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: switch (state) {
          CatalogDraftSyncState.saveError => theme.colorScheme.error,
          CatalogDraftSyncState.saving => theme.colorScheme.tertiary,
          CatalogDraftSyncState.saved => theme.colorScheme.primary,
          CatalogDraftSyncState.dirty => theme.colorScheme.secondary,
          CatalogDraftSyncState.clean => theme.colorScheme.outline,
        },
        shape: BoxShape.circle,
      ),
    );
  }
}

class _CatalogInspectorPane extends StatelessWidget {
  const _CatalogInspectorPane({
    required this.controller,
    required this.row,
    required this.locale,
    required this.layout,
    required this.onOpenInspectorSheet,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow row;
  final String locale;
  final _CatalogLayout layout;
  final VoidCallback? onOpenInspectorSheet;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = layout == _CatalogLayout.compact ? 112.0 : 24.0;
    return ListView(
      key: const ValueKey<String>('catalog-inspector-list'),
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      children: <Widget>[
        _CatalogLocalesSectionCard(
          controller: controller,
          row: row,
          locale: locale,
          compact: layout == _CatalogLayout.compact,
        ),
        const SizedBox(height: 16),
        _CatalogOverviewCard(
          controller: controller,
          row: row,
          locale: locale,
          compact: layout == _CatalogLayout.compact,
          onOpenInspectorSheet: onOpenInspectorSheet,
        ),
        const SizedBox(height: 16),
        _CatalogNotesSectionCard(
          controller: controller,
          row: row,
        ),
      ],
    );
  }
}

class _CatalogOverviewCard extends StatelessWidget {
  const _CatalogOverviewCard({
    required this.controller,
    required this.row,
    required this.locale,
    required this.compact,
    required this.onOpenInspectorSheet,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow row;
  final String locale;
  final bool compact;
  final VoidCallback? onOpenInspectorSheet;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final theme = Theme.of(context);
    final meta = controller.meta!;
    final namespace = controller.namespaceForKey(row.keyPath);
    final progress = _targetLocaleProgress(row, meta);
    final reviewableTargets = _reviewableTargetsForRow(controller, row, l10n);

    return _CatalogSectionCard(
      title: l10n.overviewSection,
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          _StatusChip(
            label: _statusLabel(l10n, row.rowStatus.name),
            status: row.rowStatus.name,
          ),
          _SyncChip(
            label: _syncLabel(l10n, controller.rowSyncState(row.keyPath)),
            state: controller.rowSyncState(row.keyPath),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SelectableText(
            row.keyPath,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _rowSummaryText(l10n, row),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (row.keyPath.contains('.'))
                _MetaPill(
                  icon: Icons.account_tree_outlined,
                  label: '${l10n.namespaceLabel}: $namespace',
                ),
              _MetaPill(
                icon: Icons.flag_outlined,
                label: l10n.localeProgress(progress.ready, progress.total),
              ),
              if ((row.note ?? '').trim().isNotEmpty)
                _MetaPill(
                  icon: Icons.sticky_note_2_outlined,
                  label: l10n.noteIndicator,
                ),
              _MetaPill(
                icon: Icons.language_outlined,
                label: '${l10n.sourceLocaleMeta}: ${formatCatalogLocale(meta.sourceLocale)}',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              if (reviewableTargets.isNotEmpty)
                FilledButton.tonalIcon(
                  onPressed: () => _handleBulkReviewForRow(
                    context,
                    controller,
                    row,
                    reviewableTargets,
                  ),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(l10n.reviewPendingLocales),
                ),
              OutlinedButton.icon(
                onPressed: () => _confirmDeleteKey(context, controller, row),
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.deleteKey),
              ),
              if (compact)
                FilledButton.icon(
                  onPressed: () {
                    final localeToOpen = row.missingLocales.isNotEmpty
                        ? row.missingLocales.first
                        : row.pendingLocales.isNotEmpty
                            ? row.pendingLocales.first
                            : locale;
                    controller.selectLocale(localeToOpen);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.localesSection),
                ),
              if (onOpenInspectorSheet != null)
                OutlinedButton.icon(
                  key: const ValueKey<String>('inspector-sheet-trigger-details'),
                  onPressed: onOpenInspectorSheet,
                  icon: const Icon(Icons.tune_outlined),
                  label: Text(l10n.detailsSection),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CatalogNotesSectionCard extends StatelessWidget {
  const _CatalogNotesSectionCard({
    required this.controller,
    required this.row,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final theme = Theme.of(context);
    final draft = controller.noteDraftFor(row);
    return _CatalogSectionCard(
      title: l10n.notesSection,
      subtitle: l10n.noteAutosave,
      trailing: _SyncChip(
        label: _syncLabel(l10n, draft.syncState),
        state: draft.syncState,
      ),
      contentPadding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            key: ValueKey<String>('note-${row.keyPath}'),
            initialValue: draft.note,
            maxLines: draft.note.trim().isEmpty ? 3 : 4,
            minLines: draft.note.trim().isEmpty ? 1 : 3,
            decoration: InputDecoration(
              labelText: l10n.noteLabel,
              hintText: l10n.noteHint,
            ),
            onChanged: (value) => controller.updateNoteDraft(row, value),
            onTapOutside: (_) => controller.flushNoteDraft(row),
          ),
          if (draft.errorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            _ErrorBanner(
              message: draft.errorMessage!,
              onRetry: () => controller.flushNoteDraft(row),
            ),
          ],
          if ((row.note ?? '').trim().isEmpty && draft.syncState == CatalogDraftSyncState.clean) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              l10n.noNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CatalogSourceContextCard extends StatelessWidget {
  const _CatalogSourceContextCard({
    required this.controller,
    required this.row,
    required this.locale,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow row;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final meta = controller.meta!;
    final theme = Theme.of(context);
    final sourceLocale = meta.sourceLocale;
    final sourceValue = row.valuesByLocale[sourceLocale];
    final placeholders = collectCatalogPlaceholders(sourceValue).toList()..sort();

    return _CatalogSectionCard(
      title: l10n.sourceContextSection,
      subtitle: '${l10n.sourcePreviewLabel} · ${formatCatalogLocale(sourceLocale)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (locale == sourceLocale) ...<Widget>[
            _BannerContainer(
              icon: Icons.info_outline,
              color: theme.colorScheme.tertiaryContainer,
              child: Text(l10n.sourceImpactBody),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: _SourcePreview(
              controller: controller,
              value: sourceValue,
              locale: sourceLocale,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.placeholdersLabel,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (placeholders.isEmpty)
            Text(
              l10n.noPlaceholders,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: placeholders.map((placeholder) {
                return _MetaPill(
                  icon: Icons.data_object_outlined,
                  label: '{$placeholder}',
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _CatalogLocalesSectionCard extends StatelessWidget {
  const _CatalogLocalesSectionCard({
    required this.controller,
    required this.row,
    required this.locale,
    required this.compact,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow row;
  final String locale;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final meta = controller.meta!;
    final theme = Theme.of(context);
    final draft = controller.valueDraftFor(row, locale);
    final blockers = controller.validateDoneBlockers(row, locale, l10n);
    final isSourceLocale = locale == meta.sourceLocale;

    return _CatalogSectionCard(
      title: l10n.localesSection,
      subtitle: '${l10n.editorLabel} · ${formatCatalogLocale(locale)}',
      highlighted: true,
      contentPadding: const EdgeInsets.all(24),
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (isSourceLocale)
            Chip(label: Text(l10n.sourceLabel))
          else if (!compact)
            FilledButton(
              onPressed: blockers.isEmpty ? () => _handleDone(context, controller, row, locale) : null,
              child: Text(l10n.done),
            ),
          _SyncChip(
            label: _syncLabel(l10n, draft.syncState),
            state: draft.syncState,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: meta.locales.map((item) {
              final status = row.cellStates[item]?.status.name ?? CatalogCellStatus.warning.name;
              return ChoiceChip(
                label: Text('${formatCatalogLocale(item)} · ${_statusLabel(l10n, status)}'),
                selected: item == locale,
                onSelected: (_) => controller.selectLocale(item),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _ReasonBanner(
            controller: controller,
            row: row,
            locale: locale,
          ),
          if (draft.errorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            _ErrorBanner(
              message: draft.errorMessage!,
              onRetry: () => controller.flushValueDraft(row, locale),
            ),
          ],
          if (blockers.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _BannerContainer(
              icon: Icons.warning_amber_outlined,
              color: theme.colorScheme.tertiaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: blockers.map(Text.new).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _CatalogInlineSourcePreviewCard(
            controller: controller,
            row: row,
          ),
          const SizedBox(height: 16),
          _ValueEditor(
            controller: controller,
            row: row,
            locale: locale,
            draft: draft,
          ),
          if (!compact) ...<Widget>[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                TextButton.icon(
                  onPressed: () => _confirmDeleteValue(context, controller, row, locale),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.deleteValue),
                ),
                if (!isSourceLocale)
                  FilledButton.tonalIcon(
                    onPressed: blockers.isEmpty ? () => _handleDone(context, controller, row, locale) : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(l10n.done),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CatalogInlineSourcePreviewCard extends StatelessWidget {
  const _CatalogInlineSourcePreviewCard({
    required this.controller,
    required this.row,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final meta = controller.meta!;
    final sourceLocale = meta.sourceLocale;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${l10n.sourcePreviewLabel} · ${formatCatalogLocale(sourceLocale)}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _SourcePreview(
            controller: controller,
            value: row.valuesByLocale[sourceLocale],
            locale: sourceLocale,
          ),
        ],
      ),
    );
  }
}

class _CatalogContextMetaCard extends StatelessWidget {
  const _CatalogContextMetaCard({
    required this.controller,
  });

  final CatalogWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final meta = controller.meta!;
    return _CatalogSectionCard(
      title: l10n.contextSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _MetaLine(
            label: l10n.sourceLocaleMeta,
            value: formatCatalogLocale(meta.sourceLocale),
          ),
          const SizedBox(height: 10),
          _MetaLine(
            label: l10n.fallbackLocaleMeta,
            value: formatCatalogLocale(meta.fallbackLocale),
          ),
          const SizedBox(height: 10),
          _MetaLine(
            label: l10n.formatMeta,
            value: meta.format.toUpperCase(),
          ),
          const SizedBox(height: 10),
          _MetaLine(
            label: l10n.stateFileMeta,
            value: meta.stateFilePath,
            selectable: true,
          ),
        ],
      ),
    );
  }
}

class _CatalogInspectorSideSheet extends StatelessWidget {
  const _CatalogInspectorSideSheet({
    required this.controller,
    required this.row,
    required this.locale,
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow? row;
  final String locale;
  final _CatalogInspectorSheetSection selectedSection;
  final ValueChanged<_CatalogInspectorSheetSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final sheetWidth = (MediaQuery.sizeOf(context).width * 0.92).clamp(320.0, 420.0).toDouble();

    return Drawer(
      key: const ValueKey<String>('catalog-inspector-sheet'),
      width: sheetWidth,
      child: SafeArea(
        child: row == null
            ? _CatalogSelectionPlaceholder(
                title: l10n.contextSection,
                message: l10n.selectionPlaceholderBody,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 8, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SelectableText(
                                row!.keyPath,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _inspectorSheetSectionLabel(l10n, selectedSection),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _CatalogInspectorSheetSection.values.map((section) {
                        return ChoiceChip(
                          key: ValueKey<String>('inspector-sheet-tab-${section.keyValue}'),
                          avatar: Icon(section.icon, size: 18),
                          label: Text(_inspectorSheetSectionLabel(l10n, section)),
                          selected: selectedSection == section,
                          onSelected: (_) => onSectionSelected(section),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: ListView(
                        key: ValueKey<String>('inspector-sheet-content-${selectedSection.keyValue}'),
                        padding: const EdgeInsets.all(16),
                        children: <Widget>[
                          switch (selectedSection) {
                            _CatalogInspectorSheetSection.sourceContext => _CatalogSourceContextCard(
                                controller: controller,
                                row: row!,
                                locale: locale,
                              ),
                            _CatalogInspectorSheetSection.catalogContext => _CatalogContextMetaCard(
                                controller: controller,
                              ),
                            _CatalogInspectorSheetSection.activity => _CatalogActivityTimelineCard(
                                controller: controller,
                              ),
                          },
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CatalogActivityTimelineCard extends StatelessWidget {
  const _CatalogActivityTimelineCard({
    required this.controller,
  });

  final CatalogWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    Widget content;
    if (controller.activityLoading) {
      content = const _CatalogActivitySkeleton();
    } else if (controller.activityError != null) {
      content = _ErrorBanner(
        message: controller.activityError!,
        onRetry: controller.refresh,
      );
    } else if (controller.activityEvents.isEmpty) {
      content = _CatalogEmptyStateCard(
        icon: Icons.history_toggle_off_outlined,
        title: l10n.activitySection,
        message: l10n.activityEmpty,
        compact: true,
      );
    } else {
      content = Column(
        children: controller.activityEvents.map((event) {
          final subtitle = controller.formatTimestamp(event.timestamp, locale);
          final eventLabel = _activityLabel(l10n, event);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(_activityIcon(event.kind)),
            title: Text(eventLabel),
            subtitle: Text(subtitle),
          );
        }).toList(),
      );
    }

    return _CatalogSectionCard(
      title: l10n.activitySection,
      child: content,
    );
  }
}

class _CompactInspectorActionBar extends StatelessWidget {
  const _CompactInspectorActionBar({
    required this.controller,
    required this.row,
    required this.locale,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow row;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final meta = controller.meta;
    if (meta == null) {
      return const SizedBox.shrink();
    }
    final isSourceLocale = locale == meta.sourceLocale;
    final blockers = controller.validateDoneBlockers(row, locale, l10n);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDeleteValue(context, controller, row, locale),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.deleteValue),
                  ),
                ),
                if (!isSourceLocale) ...<Widget>[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: blockers.isEmpty ? () => _handleDone(context, controller, row, locale) : null,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(l10n.done),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogSectionCard extends StatelessWidget {
  const _CatalogSectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.highlighted = false,
    this.contentPadding = const EdgeInsets.all(20),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final bool highlighted;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: highlighted ? theme.colorScheme.surface : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: highlighted ? theme.colorScheme.primary.withOpacity(0.24) : theme.colorScheme.outlineVariant,
          width: highlighted ? 1.2 : 1,
        ),
      ),
      child: Padding(
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _CatalogEmptyStateCard extends StatelessWidget {
  const _CatalogEmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: compact ? 28 : 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogSelectionPlaceholder extends StatelessWidget {
  const _CatalogSelectionPlaceholder({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: _CatalogEmptyStateCard(
        icon: Icons.touch_app_outlined,
        title: title,
        message: message,
      ),
    );
  }
}

class _CatalogQueueSkeleton extends StatelessWidget {
  const _CatalogQueueSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List<Widget>.generate(5, (index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SkeletonLine(widthFactor: 0.55, height: 18),
                  SizedBox(height: 12),
                  _SkeletonLine(widthFactor: 0.3),
                  SizedBox(height: 16),
                  _SkeletonLine(widthFactor: 1),
                  SizedBox(height: 8),
                  _SkeletonLine(widthFactor: 0.5),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CatalogActivitySkeleton extends StatelessWidget {
  const _CatalogActivitySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(4, (index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Row(
            children: <Widget>[
              CircleAvatar(radius: 12),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _SkeletonLine(widthFactor: 0.55),
                    SizedBox(height: 8),
                    _SkeletonLine(widthFactor: 0.35),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.widthFactor,
    this.height = 12,
  });

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueWidget = selectable
        ? SelectableText(
            value,
            style: theme.textTheme.bodyMedium,
          )
        : Text(value, style: theme.textTheme.bodyMedium);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        valueWidget,
      ],
    );
  }
}

class _TargetLocaleProgress {
  const _TargetLocaleProgress({
    required this.ready,
    required this.total,
  });

  final int ready;
  final int total;
}

_TargetLocaleProgress _targetLocaleProgress(CatalogRow row, CatalogMeta meta) {
  final targetLocales = meta.locales.where((locale) => locale != meta.sourceLocale).toList();
  if (targetLocales.isEmpty) {
    final sourceReady = row.cellStates[meta.sourceLocale]?.status == CatalogCellStatus.green ? 1 : 0;
    return _TargetLocaleProgress(ready: sourceReady, total: 1);
  }
  final ready = targetLocales.where((locale) => row.cellStates[locale]?.status == CatalogCellStatus.green).length;
  return _TargetLocaleProgress(ready: ready, total: targetLocales.length);
}

String _queueHeadline(CatalogLocalizations l10n, CatalogSummary? summary) {
  if (summary == null) {
    return l10n.loading;
  }
  return '${summary.warningRows} ${l10n.reviewRowsLabel} · ${summary.redRows} ${l10n.missingRowsLabel}';
}

String _queueSectionLabel(CatalogLocalizations l10n, CatalogQueueSection section) {
  return switch (section) {
    CatalogQueueSection.missing => l10n.filterMissing,
    CatalogQueueSection.needsReview => l10n.filterNeedsReview,
    CatalogQueueSection.ready => l10n.filterReady,
  };
}

Color _statusColor(ColorScheme scheme, CatalogCellStatus status) {
  return switch (status) {
    CatalogCellStatus.green => scheme.secondary,
    CatalogCellStatus.red => scheme.error,
    CatalogCellStatus.warning => scheme.tertiary,
  };
}

List<CatalogReviewTarget> _reviewableTargetsForRow(
  CatalogWorkspaceController controller,
  CatalogRow row,
  CatalogLocalizations l10n,
) {
  final meta = controller.meta;
  if (meta == null) {
    return const <CatalogReviewTarget>[];
  }
  return row.pendingLocales.where((locale) {
    if (locale == meta.sourceLocale) {
      return false;
    }
    final blockers = controller.validateDoneBlockers(row, locale, l10n);
    return blockers.isEmpty;
  }).map((locale) {
    return CatalogReviewTarget(
      keyPath: row.keyPath,
      locale: locale,
    );
  }).toList();
}

Future<void> _handleBulkReviewForRow(
  BuildContext context,
  CatalogWorkspaceController controller,
  CatalogRow row,
  List<CatalogReviewTarget> targets,
) async {
  if (targets.isEmpty) {
    return;
  }
  try {
    await controller.flushActiveDrafts();
    await controller.bulkReviewTargets(targets);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(CatalogLocalizations.of(context).reviewPendingSuccess(targets.length)),
      ),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }
}

String _inspectorSheetSectionLabel(
  CatalogLocalizations l10n,
  _CatalogInspectorSheetSection section,
) {
  return switch (section) {
    _CatalogInspectorSheetSection.sourceContext => l10n.sourceContextSection,
    _CatalogInspectorSheetSection.catalogContext => l10n.contextSection,
    _CatalogInspectorSheetSection.activity => l10n.activitySection,
  };
}

String _activityLabel(CatalogLocalizations l10n, CatalogActivityEvent event) {
  final base = switch (event.kind) {
    CatalogActivityKinds.keyCreated => l10n.activityKeyCreated,
    CatalogActivityKinds.sourceUpdated => l10n.activitySourceUpdated,
    CatalogActivityKinds.targetUpdated => l10n.activityTargetUpdated,
    CatalogActivityKinds.noteUpdated => l10n.activityNoteUpdated,
    CatalogActivityKinds.localeReviewed => l10n.activityLocaleReviewed,
    CatalogActivityKinds.valueDeleted => l10n.activityValueDeleted,
    _ => event.kind,
  };
  if (event.locale == null || event.locale!.trim().isEmpty) {
    return base;
  }
  return '$base · ${formatCatalogLocale(event.locale!)}';
}

IconData _activityIcon(String kind) {
  return switch (kind) {
    CatalogActivityKinds.keyCreated => Icons.add_circle_outline,
    CatalogActivityKinds.sourceUpdated => Icons.edit_note_outlined,
    CatalogActivityKinds.targetUpdated => Icons.translate_outlined,
    CatalogActivityKinds.noteUpdated => Icons.sticky_note_2_outlined,
    CatalogActivityKinds.localeReviewed => Icons.fact_check_outlined,
    CatalogActivityKinds.valueDeleted => Icons.delete_outline,
    _ => Icons.history,
  };
}

class _ValueEditor extends StatelessWidget {
  const _ValueEditor({
    required this.controller,
    required this.row,
    required this.locale,
    required this.draft,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow row;
  final String locale;
  final CatalogValueDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final localeDirection = controller.localeDirection(locale) == 'rtl' ? TextDirection.rtl : TextDirection.ltr;
    switch (draft.editorMode) {
      case CatalogEditorMode.gender:
        return Column(
          children: <Widget>[
            ...normalizedGenderKeys(draft.value).map(
              (key) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BranchEditorCard(
                  label: key,
                  sourceValue: readCatalogPath(row.valuesByLocale[controller.meta!.sourceLocale], <String>[key]),
                  localeDirection: localeDirection,
                  sourceDirection: controller.localeDirection(controller.meta!.sourceLocale) == 'rtl'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: TextFormField(
                    key: ValueKey<String>('branch-${row.keyPath}-$locale-$key'),
                    initialValue: (readCatalogPath(draft.value, <String>[key]) ?? '').toString(),
                    maxLines: null,
                    textDirection: localeDirection,
                    decoration: InputDecoration(
                      labelText: l10n.translationLabel,
                    ),
                    onChanged: (value) => controller.updateBranchDraft(
                      row: row,
                      locale: locale,
                      path: <String>[key],
                      text: value,
                    ),
                    onTapOutside: (_) => controller.flushValueDraft(row, locale),
                  ),
                ),
              ),
            ),
            _AddBranchRow(
              labels: _availableGenderCandidates(draft.value, row.valuesByLocale[controller.meta!.sourceLocale]),
              onTap: (value) => controller.addGenderBranch(
                row: row,
                locale: locale,
                category: null,
                gender: value,
              ),
            ),
            _AdvancedJsonEditor(
              controller: controller,
              row: row,
              locale: locale,
              draft: draft,
            ),
          ],
        );
      case CatalogEditorMode.plural:
        return Column(
          children: <Widget>[
            ...normalizedPluralKeys(draft.value).map(
              (key) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BranchEditorCard(
                  label: key,
                  sourceValue: readCatalogPath(row.valuesByLocale[controller.meta!.sourceLocale], <String>[key]),
                  localeDirection: localeDirection,
                  sourceDirection: controller.localeDirection(controller.meta!.sourceLocale) == 'rtl'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: TextFormField(
                    key: ValueKey<String>('branch-${row.keyPath}-$locale-$key'),
                    initialValue: (readCatalogPath(draft.value, <String>[key]) ?? '').toString(),
                    maxLines: null,
                    textDirection: localeDirection,
                    decoration: InputDecoration(
                      labelText: l10n.translationLabel,
                    ),
                    onChanged: (value) => controller.updateBranchDraft(
                      row: row,
                      locale: locale,
                      path: <String>[key],
                      text: value,
                    ),
                    onTapOutside: (_) => controller.flushValueDraft(row, locale),
                  ),
                ),
              ),
            ),
            _AddBranchRow(
              labels: _availablePluralCandidates(draft.value, row.valuesByLocale[controller.meta!.sourceLocale]),
              onTap: (value) => controller.addPluralBranch(
                row: row,
                locale: locale,
                category: value,
              ),
            ),
            _AdvancedJsonEditor(
              controller: controller,
              row: row,
              locale: locale,
              draft: draft,
            ),
          ],
        );
      case CatalogEditorMode.pluralGender:
        final sourceDirection =
            controller.localeDirection(controller.meta!.sourceLocale) == 'rtl' ? TextDirection.rtl : TextDirection.ltr;
        return Column(
          children: <Widget>[
            ...normalizedPluralKeys(draft.value).map(
              (pluralKey) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          pluralKey,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        ...normalizedGenderKeys((draft.value as Map)[pluralKey]).map(
                          (genderKey) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _BranchEditorCard(
                              label: genderKey,
                              sourceValue: readCatalogPath(
                                row.valuesByLocale[controller.meta!.sourceLocale],
                                <String>[pluralKey, genderKey],
                              ),
                              localeDirection: localeDirection,
                              sourceDirection: sourceDirection,
                              child: TextFormField(
                                key: ValueKey<String>('branch-${row.keyPath}-$locale-$pluralKey-$genderKey'),
                                initialValue:
                                    (readCatalogPath(draft.value, <String>[pluralKey, genderKey]) ?? '').toString(),
                                maxLines: null,
                                textDirection: localeDirection,
                                decoration: InputDecoration(
                                  labelText: l10n.translationLabel,
                                ),
                                onChanged: (value) => controller.updateBranchDraft(
                                  row: row,
                                  locale: locale,
                                  path: <String>[pluralKey, genderKey],
                                  text: value,
                                ),
                                onTapOutside: (_) => controller.flushValueDraft(row, locale),
                              ),
                            ),
                          ),
                        ),
                        _AddBranchRow(
                          labels: _availableGenderCandidates(
                            (draft.value as Map)[pluralKey],
                            readCatalogPath(row.valuesByLocale[controller.meta!.sourceLocale], <String>[pluralKey]),
                          ),
                          onTap: (value) => controller.addGenderBranch(
                            row: row,
                            locale: locale,
                            category: pluralKey,
                            gender: value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _AddBranchRow(
              labels: _availablePluralCandidates(draft.value, row.valuesByLocale[controller.meta!.sourceLocale]),
              onTap: (value) => controller.addPluralBranch(
                row: row,
                locale: locale,
                category: value,
              ),
            ),
            _AdvancedJsonEditor(
              controller: controller,
              row: row,
              locale: locale,
              draft: draft,
            ),
          ],
        );
      case CatalogEditorMode.raw:
        return Column(
          children: <Widget>[
            _AdvancedJsonEditor(
              controller: controller,
              row: row,
              locale: locale,
              draft: draft,
              initiallyExpanded: true,
            ),
          ],
        );
      case CatalogEditorMode.plain:
        return Column(
          children: <Widget>[
            TextFormField(
              key: ValueKey<String>('plain-${row.keyPath}-$locale'),
              initialValue: (draft.value ?? '').toString(),
              maxLines: null,
              textDirection: localeDirection,
              decoration: InputDecoration(
                labelText: l10n.translationLabel,
              ),
              onChanged: (value) => controller.updatePlainDraft(
                row: row,
                locale: locale,
                text: value,
              ),
              onTapOutside: (_) => controller.flushValueDraft(row, locale),
            ),
            const SizedBox(height: 12),
            _AdvancedJsonEditor(
              controller: controller,
              row: row,
              locale: locale,
              draft: draft,
            ),
          ],
        );
    }
  }
}

class _AdvancedJsonEditor extends StatelessWidget {
  const _AdvancedJsonEditor({
    required this.controller,
    required this.row,
    required this.locale,
    required this.draft,
    this.initiallyExpanded = false,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow row;
  final String locale;
  final CatalogValueDraft draft;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      title: Text(l10n.advancedJson),
      subtitle: Text(l10n.advancedJsonHelp),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: <Widget>[
              TextFormField(
                key: ValueKey<String>('advanced-json-${row.keyPath}-$locale'),
                initialValue: draft.rawText,
                maxLines: 10,
                minLines: 6,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: l10n.advancedJson,
                  errorText: draft.rawError == null ? null : l10n.advancedJsonHelp,
                ),
                onChanged: (value) => controller.updateAdvancedJsonDraft(
                  row: row,
                  locale: locale,
                  text: value,
                ),
                onTapOutside: (_) => controller.flushValueDraft(row, locale),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourcePreview extends StatelessWidget {
  const _SourcePreview({
    required this.controller,
    required this.value,
    required this.locale,
  });

  final CatalogWorkspaceController controller;
  final dynamic value;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final direction = controller.localeDirection(locale) == 'rtl' ? TextDirection.rtl : TextDirection.ltr;
    return Directionality(
      textDirection: direction,
      child: SelectableText(
        prettyCatalogJson(value),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _BranchEditorCard extends StatelessWidget {
  const _BranchEditorCard({
    required this.label,
    required this.sourceValue,
    required this.localeDirection,
    required this.sourceDirection,
    required this.child,
  });

  final String label;
  final dynamic sourceValue;
  final TextDirection localeDirection;
  final TextDirection sourceDirection;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(l10n.sourcePreviewLabel, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Directionality(
              textDirection: sourceDirection,
              child: SelectableText(
                sourceValue == null ? '' : sourceValue.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: localeDirection,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeMenu extends StatelessWidget {
  const _ThemeMenu({
    required this.preferencesController,
    this.compact = false,
  });

  final CatalogPreferencesController preferencesController;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    return PopupMenuButton<CatalogThemeMode>(
      tooltip: l10n.themeLabel,
      icon: compact ? const Icon(Icons.palette_outlined) : null,
      initialValue: preferencesController.themeMode,
      onSelected: (value) {
        preferencesController.setThemeMode(value);
      },
      itemBuilder: (context) => <PopupMenuEntry<CatalogThemeMode>>[
        PopupMenuItem(
          value: CatalogThemeMode.system,
          child: Text(l10n.themeSystem),
        ),
        PopupMenuItem(
          value: CatalogThemeMode.light,
          child: Text(l10n.themeLight),
        ),
        PopupMenuItem(
          value: CatalogThemeMode.dark,
          child: Text(l10n.themeDark),
        ),
      ],
      child: compact
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  '${l10n.themeLabel}: ${switch (preferencesController.themeMode) {
                    CatalogThemeMode.system => l10n.themeSystem,
                    CatalogThemeMode.light => l10n.themeLight,
                    CatalogThemeMode.dark => l10n.themeDark,
                  }}',
                ),
              ),
            ),
    );
  }
}

class _DisplayLanguageButton extends StatelessWidget {
  const _DisplayLanguageButton({
    required this.preferencesController,
    this.compact = false,
  });

  final CatalogPreferencesController preferencesController;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    if (compact) {
      return IconButton(
        tooltip: '${l10n.catalogLanguage}: ${preferencesController.displayLanguage.code.toUpperCase()}',
        onPressed: () => _showDisplayLanguageDialog(context, preferencesController),
        icon: const Icon(Icons.language),
      );
    }
    return TextButton(
      onPressed: () => _showDisplayLanguageDialog(context, preferencesController),
      child: Text('${l10n.catalogLanguage}: ${preferencesController.displayLanguage.code.toUpperCase()}'),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.status,
  });

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color background = switch (status) {
      'green' => colorScheme.secondaryContainer,
      'red' => colorScheme.errorContainer,
      _ => colorScheme.tertiaryContainer,
    };
    final Color foreground = switch (status) {
      'green' => colorScheme.onSecondaryContainer,
      'red' => colorScheme.onErrorContainer,
      _ => colorScheme.onTertiaryContainer,
    };
    return Chip(
      backgroundColor: background,
      labelStyle: TextStyle(color: foreground),
      label: Text(label),
    );
  }
}

class _SyncChip extends StatelessWidget {
  const _SyncChip({
    required this.label,
    required this.state,
  });

  final String label;
  final CatalogDraftSyncState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (state) {
      CatalogDraftSyncState.clean => (colorScheme.surfaceContainerHigh, colorScheme.onSurfaceVariant),
      CatalogDraftSyncState.saved => (colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
      CatalogDraftSyncState.saveError => (colorScheme.errorContainer, colorScheme.onErrorContainer),
      CatalogDraftSyncState.saving => (colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
      CatalogDraftSyncState.dirty => (colorScheme.surfaceContainerHighest, colorScheme.onSurface),
    };
    return Chip(
      backgroundColor: background,
      labelStyle: TextStyle(color: foreground),
      label: Text(label),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _BannerContainer(
      icon: Icons.error_outline,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: <Widget>[
          Expanded(child: Text(message)),
          TextButton(
            onPressed: onRetry,
            child: Text(CatalogLocalizations.of(context).retry),
          ),
        ],
      ),
    );
  }
}

class _ReasonBanner extends StatelessWidget {
  const _ReasonBanner({
    required this.controller,
    required this.row,
    required this.locale,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow row;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final cell = row.cellStates[locale];
    if (cell == null) {
      return const SizedBox.shrink();
    }
    final lines = <String>[];
    if (cell.reason != null) {
      lines.add(_reasonLabel(l10n, cell.reason!));
    }
    if (cell.lastEditedAt != null) {
      lines.add(
        '${l10n.pendingLabel}: ${controller.formatTimestamp(cell.lastEditedAt, Localizations.localeOf(context))}',
      );
    }
    if (cell.lastReviewedAt != null) {
      lines.add(
        '${l10n.reviewed}: ${controller.formatTimestamp(cell.lastReviewedAt, Localizations.localeOf(context))}',
      );
    }
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }
    return _BannerContainer(
      icon: Icons.info_outline,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map(Text.new).toList(),
      ),
    );
  }
}

class _BannerContainer extends StatelessWidget {
  const _BannerContainer({
    required this.icon,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AddBranchRow extends StatelessWidget {
  const _AddBranchRow({
    required this.labels,
    required this.onTap,
  });

  final List<String> labels;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        return OutlinedButton.icon(
          onPressed: () => onTap(label),
          icon: const Icon(Icons.add),
          label: Text('${l10n.addBranchLabel}: $label'),
        );
      }).toList(),
    );
  }
}

List<String> _availablePluralCandidates(dynamic value, dynamic sourceValue) {
  final existing = normalizedPluralKeys(value).toSet();
  final sourceKeys = normalizedPluralKeys(sourceValue);
  return <String>{...catalogPluralKeys, ...sourceKeys}.where((key) => !existing.contains(key)).toList();
}

List<String> _availableGenderCandidates(dynamic value, dynamic sourceValue) {
  final existing = normalizedGenderKeys(value).toSet();
  final sourceKeys = normalizedGenderKeys(sourceValue);
  return <String>{...catalogGenderKeys, ...sourceKeys}.where((key) => !existing.contains(key)).toList();
}

String _statusFilterLabel(CatalogLocalizations l10n, CatalogRowStatusFilter filter) {
  return switch (filter) {
    CatalogRowStatusFilter.all => l10n.filterAll,
    CatalogRowStatusFilter.ready => l10n.filterReady,
    CatalogRowStatusFilter.needsReview => l10n.filterNeedsReview,
    CatalogRowStatusFilter.missing => l10n.filterMissing,
  };
}

String _statusLabel(CatalogLocalizations l10n, String status) {
  return switch (status) {
    'green' => l10n.statusReady,
    'red' => l10n.statusMissing,
    _ => l10n.statusNeedsReview,
  };
}

String _reasonLabel(CatalogLocalizations l10n, String reason) {
  return switch (reason) {
    CatalogStatusReasons.sourceChanged => l10n.reasonSourceChanged,
    CatalogStatusReasons.sourceAdded => l10n.reasonSourceAdded,
    CatalogStatusReasons.sourceDeleted => l10n.reasonSourceDeleted,
    CatalogStatusReasons.sourceDeletedReviewRequired => l10n.reasonSourceDeletedReviewRequired,
    CatalogStatusReasons.targetMissing => l10n.reasonTargetMissing,
    CatalogStatusReasons.newKeyNeedsTranslationReview => l10n.reasonNewKeyNeedsReview,
    CatalogStatusReasons.targetUpdatedNeedsReview => l10n.reasonTargetUpdatedNeedsReview,
    _ => reason,
  };
}

String _syncLabel(CatalogLocalizations l10n, CatalogDraftSyncState state) {
  return switch (state) {
    CatalogDraftSyncState.clean => l10n.syncClean,
    CatalogDraftSyncState.dirty => l10n.syncDirty,
    CatalogDraftSyncState.saving => l10n.syncSaving,
    CatalogDraftSyncState.saved => l10n.syncSaved,
    CatalogDraftSyncState.saveError => l10n.syncError,
  };
}

String _rowSummaryText(CatalogLocalizations l10n, CatalogRow row) {
  if (row.missingLocales.isNotEmpty) {
    return '${l10n.missingLabel}: ${row.missingLocales.map(formatCatalogLocale).join(', ')}';
  }
  if (row.pendingLocales.isNotEmpty) {
    return '${l10n.pendingLabel}: ${row.pendingLocales.map(formatCatalogLocale).join(', ')}';
  }
  return l10n.allTargetsReady;
}

Future<void> _showDisplayLanguageDialog(
  BuildContext context,
  CatalogPreferencesController preferencesController,
) async {
  var selected = preferencesController.displayLanguage;
  final l10n = CatalogLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.catalogLanguage),
            content: RadioGroup<CatalogDisplayLanguage>(
              groupValue: selected,
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  selected = value;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: CatalogDisplayLanguage.values.map((language) {
                  return RadioListTile<CatalogDisplayLanguage>(
                    value: language,
                    title: Text(language.code.toUpperCase()),
                  );
                }).toList(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.confirm),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed == true) {
    await preferencesController.setDisplayLanguage(selected);
  }
}

Future<void> _showCreateKeyDialog(
  BuildContext context,
  CatalogWorkspaceController controller,
) async {
  final meta = controller.meta;
  if (meta == null) {
    return;
  }
  final l10n = CatalogLocalizations.of(context);
  final keyController = TextEditingController();
  final noteController = TextEditingController();
  final localeControllers = <String, TextEditingController>{
    for (final locale in <String>[meta.sourceLocale, ...meta.locales.where((locale) => locale != meta.sourceLocale)])
      locale: TextEditingController(),
  };

  Future<void> submit(
    StateSetter setState,
    ValueNotifier<String?> errorNotifier,
    ValueNotifier<bool> savingNotifier,
  ) async {
    final keyPath = keyController.text.trim();
    if (!isValidCatalogKeyPath(keyPath)) {
      errorNotifier.value = l10n.invalidKeyPath;
      return;
    }
    errorNotifier.value = null;
    final valuesByLocale = <String, dynamic>{
      for (final entry in localeControllers.entries) entry.key: entry.value.text,
    };
    if ((valuesByLocale[meta.sourceLocale] as String).trim().isEmpty) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(l10n.confirmCreateWithoutSource),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.create),
            ),
          ],
        ),
      );
      if (accepted != true) {
        return;
      }
    }

    savingNotifier.value = true;
    try {
      await controller.createKey(
        keyPath: keyPath,
        valuesByLocale: valuesByLocale,
        note: noteController.text,
      );
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      errorNotifier.value = error.toString();
    } finally {
      savingNotifier.value = false;
    }
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final errorNotifier = ValueNotifier<String?>(null);
      final savingNotifier = ValueNotifier<bool>(false);
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.createNewString),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l10n.createNewStringSubtitle),
                    const SizedBox(height: 16),
                    TextField(
                      controller: keyController,
                      decoration: InputDecoration(
                        labelText: l10n.keyPathLabel,
                        hintText: l10n.keyPathHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: l10n.noteLabel,
                        hintText: l10n.noteHint,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ...localeControllers.entries.map((entry) {
                      final locale = entry.key;
                      final isSource = locale == meta.sourceLocale;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: entry.value,
                          textDirection:
                              controller.localeDirection(locale) == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText: '${formatCatalogLocale(locale)}${isSource ? ' · ${l10n.sourceLabel}' : ''}',
                            hintText: l10n.optionalValueLabel,
                          ),
                          maxLines: 2,
                        ),
                      );
                    }),
                    ValueListenableBuilder<String?>(
                      valueListenable: errorNotifier,
                      builder: (context, error, _) {
                        if (error == null || error.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            error,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: savingNotifier,
                builder: (context, saving, _) {
                  return FilledButton(
                    onPressed: saving ? null : () => submit(setState, errorNotifier, savingNotifier),
                    child: Text(l10n.create),
                  );
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _handleDone(
  BuildContext context,
  CatalogWorkspaceController controller,
  CatalogRow row,
  String locale,
) async {
  final l10n = CatalogLocalizations.of(context);
  final blockers = controller.validateDoneBlockers(row, locale, l10n);
  if (blockers.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(blockers.first)),
    );
    return;
  }
  try {
    await controller.flushValueDraft(row, locale);
    await controller.markReviewed(row: row, locale: locale);
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }
}

Future<void> _confirmDeleteValue(
  BuildContext context,
  CatalogWorkspaceController controller,
  CatalogRow row,
  String locale,
) async {
  final l10n = CatalogLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(
        locale == controller.meta?.sourceLocale
            ? l10n.deleteSourceValueConfirmation
            : l10n.deleteLocaleValueConfirmation,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.deleteValue),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await controller.deleteValue(row: row, locale: locale);
  }
}

Future<void> _confirmDeleteKey(
  BuildContext context,
  CatalogWorkspaceController controller,
  CatalogRow row,
) async {
  final l10n = CatalogLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(l10n.deleteKeyConfirmation),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.deleteKey),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await controller.deleteKey(row);
  }
}
