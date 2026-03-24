library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/http_client_adapter.dart';
import '../../../../shared/core/formatters/text_direction_helper.dart';
import '../../client/catalog_client.dart';
import '../../config/catalog_config.dart';
import '../../domain/entities/catalog_models.dart';
import '../../l10n/generated/catalog_localizations.dart';
import 'catalog_inspector_widgets.dart';
import 'catalog_label_helpers.dart';
import 'catalog_preferences_controller.dart';
import 'catalog_queue_widgets.dart';
import 'catalog_shared_widgets.dart';
import 'catalog_status_widgets.dart';
import 'catalog_toolbar_widgets.dart';
import 'catalog_workspace_controllers.dart';

// ---------------------------------------------------------------------------
// Bootstrap
// ---------------------------------------------------------------------------

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
      // Load config first to get fallback locale
      CatalogConfig? config;
      try {
        config = await CatalogConfig.load();
      } catch (_) {
        // Config might not exist yet, use defaults
      }

      // Load preferences with fallback locale from config
      await preferencesController.load(fallbackLocale: config?.fallbackLocale);

      final bootstrapConfig = await (widget.bootstrapLoader ?? loadCatalogBootstrapConfig)();
      final client = (widget.clientFactory ?? _defaultCatalogClientFactory)(Uri.parse(bootstrapConfig.apiUrl));
      final workspaceController = CatalogWorkspaceController(
        client: client,
        fallbackLocale: config?.fallbackLocale,
      );
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
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: const Center(
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
  final client = DefaultHttpClient();
  try {
    final response = await client.get(bootstrapUri);
    final payload = response.body.trim().isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CatalogClientException(payload['error']?.toString() ?? 'Could not load catalog bootstrap.');
    }
    return CatalogBootstrapConfig.fromJson(payload);
  } finally {
    client.close();
  }
}

// ---------------------------------------------------------------------------
// App shell
// ---------------------------------------------------------------------------

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
        final locale = preferences.displayLanguage.locale;
        return MaterialApp(
          locale: locale,
          builder: (context, child) => AnasDirectionalityWrapper(
            locale: locale,
            child: child!,
          ),
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
  final isLight = brightness == Brightness.light;
  final seed = isLight ? const Color(0xFF6366F1) : const Color(0xFF818CF8); // Vibrant Indigo
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );
  final baseTheme = ThemeData(brightness: brightness, useMaterial3: true);
  final textTheme = baseTheme.textTheme.copyWith(
    headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
    ),
    headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
    titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.25,
    ),
    titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.1,
    ),
    titleSmall: baseTheme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(height: 1.35),
    bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(height: 1.35),
    bodySmall: baseTheme.textTheme.bodySmall?.copyWith(height: 1.3),
    labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.headlineMedium?.copyWith(color: scheme.onSurface),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.light ? scheme.surface : scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface.withValues(alpha: isLight ? 0.7 : 0.2),
      elevation: 0,
      shadowColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: isLight ? 0.3 : 0.15),
        ),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll<Color>(scheme.surface),
      elevation: const WidgetStatePropertyAll<double>(0),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
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
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.8),
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: scheme.surface.withValues(alpha: 0.82),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.75)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        foregroundColor: scheme.primary,
        textStyle: textTheme.labelLarge,
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: scheme.surface.withValues(alpha: isLight ? 0.8 : 0.4),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Home screen
// ---------------------------------------------------------------------------

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
  CatalogInspectorSheetSection _activeInspectorSheetSection = CatalogInspectorSheetSection.sourceContext;

  void _setInspectorSheetSection(CatalogInspectorSheetSection section) {
    if (_activeInspectorSheetSection == section) {
      return;
    }
    setState(() {
      _activeInspectorSheetSection = section;
    });
  }

  void _openInspectorSheet() {
    final selectedRow = widget.workspaceController.selectedRow;
    if (selectedRow == null) return;

    final selectedLocale = widget.workspaceController.selectedLocale ?? widget.workspaceController.defaultEditorLocale;

    showModalSideSheet(
      context: context,
      alignment: AlignmentDirectional.centerEnd,
      child: CatalogInspectorSideSheet(
        controller: widget.workspaceController,
        row: selectedRow,
        locale: selectedLocale,
        selectedSection: _activeInspectorSheetSection,
        onSectionSelected: _setInspectorSheetSection,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);

    final selectedRow = widget.workspaceController.selectedRow;
    final width = MediaQuery.sizeOf(context).width;
    final layout = width < 600
        ? CatalogLayout.compact
        : width < 840
            ? CatalogLayout.medium
            : CatalogLayout.expanded;
    final showCompactDetail =
        layout == CatalogLayout.compact && widget.workspaceController.compactDetailOpen && selectedRow != null;
    final selectedLocale = widget.workspaceController.selectedLocale ?? widget.workspaceController.defaultEditorLocale;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      key: _scaffoldKey,
      appBar: AppBar(
        title: _AppBarTitle(title: l10n.appTitle),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
          if (layout == CatalogLayout.expanded)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: FilledButton.icon(
                onPressed: () => showCreateKeyDialog(context, widget.workspaceController),
                icon: const Icon(Icons.add),
                label: Text(l10n.newString),
              ),
            )
          else
            IconButton(
              tooltip: l10n.newString,
              onPressed: () => showCreateKeyDialog(context, widget.workspaceController),
              icon: const Icon(Icons.add),
            ),
          IconButton(
            tooltip: l10n.catalogLanguage,
            onPressed: () {
              showModalSideSheet(
                context: context,
                child: CatalogSettingsSideSheet(
                  preferencesController: widget.preferencesController,
                  workspaceController: widget.workspaceController,
                ),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      bottomNavigationBar: showCompactDetail
          ? CompactInspectorActionBar(
              controller: widget.workspaceController,
              row: selectedRow,
              locale: selectedLocale,
            )
          : layout != CatalogLayout.compact && widget.workspaceController.summary != null
              ? _CatalogStatusBar(summary: widget.workspaceController.summary!)
              : null,
      body: widget.workspaceController.loading && widget.workspaceController.meta == null
          ? const Center(child: CircularProgressIndicator())
          : widget.workspaceController.error != null && widget.workspaceController.meta == null
              ? ErrorPane(
                  message: widget.workspaceController.error ?? 'Unknown error',
                  onRetry: widget.workspaceController.refresh,
                )
              : SafeArea(
                  child: CatalogWorkspaceBody(
                    controller: widget.workspaceController,
                    layout: layout,
                    onOpenInspectorSheet: selectedRow == null ? null : _openInspectorSheet,
                    inspectorBuilder: ({
                      required controller,
                      required row,
                      required locale,
                      required layout,
                      required onOpenInspectorSheet,
                    }) =>
                        CatalogInspectorPane(
                      controller: controller,
                      row: row,
                      locale: locale,
                      layout: layout,
                      onOpenInspectorSheet: onOpenInspectorSheet,
                    ),
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CatalogStatusBar — sticky bottom bar for web/tablet showing project stats
// ---------------------------------------------------------------------------

class _CatalogStatusBar extends StatelessWidget {
  const _CatalogStatusBar({required this.summary});

  final CatalogSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          CatalogSummaryStrip(summary: summary),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AppBarTitle — display-font logo that adapts to theme & language direction
// ---------------------------------------------------------------------------

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: colorScheme.primary,
        letterSpacing: isRtl ? 0 : -0.5,
        // Subtle italic only for Latin-script languages; Arabic looks
        // odd italicised so we leave RTL scripts upright.
        fontStyle: isRtl ? FontStyle.normal : FontStyle.italic,
        height: 1.1,
      ),
    );
  }
}
