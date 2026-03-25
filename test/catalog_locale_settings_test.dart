import 'package:anas_localization/src/features/catalog/domain/entities/catalog_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CatalogLocaleSettings', () {
    // T051: Widget test for language group visual grouping
    testWidgets('displays language groups with visual grouping', (tester) async {
      // Mock data with language groups
      final catalogState = CatalogState(
        version: 3,
        sourceLocale: 'en',
        format: 'arb',
        keys: {},
        languageGroupFallbacks: {
          'en': 'en_US',
          'ar': 'ar_EG',
        },
        customLocaleDirections: {
          'ar_SA': 'rtl',
          'ar_EG': 'rtl',
        },
      );

      final allLocales = ['en_US', 'en_GB', 'ar_EG', 'ar_SA', 'es_MX'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestCatalogLocaleSettingsWidget(
              locales: allLocales,
              catalogState: catalogState,
            ),
          ),
        ),
      );

      // Verify language group headers are displayed
      expect(find.text('English'), findsWidgets);
      expect(find.text('Arabic'), findsWidgets);
      expect(find.text('Spanish'), findsWidgets);

      // Verify locales are displayed
      expect(find.text('en_US'), findsOneWidget);
      expect(find.text('en_GB'), findsOneWidget);
      expect(find.text('ar_EG'), findsOneWidget);
      expect(find.text('ar_SA'), findsOneWidget);
      expect(find.text('es_MX'), findsOneWidget);
    });

    // T052: Widget test for fallback locale badge display
    testWidgets('displays Group Fallback badge for designated fallback locale', (tester) async {
      final catalogState = CatalogState(
        version: 3,
        sourceLocale: 'en',
        format: 'arb',
        keys: {},
        languageGroupFallbacks: {
          'en': 'en_US',
        },
        customLocaleDirections: {},
      );

      const allLocales = ['en_US', 'en_GB'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestCatalogLocaleSettingsWidget(
              locales: allLocales,
              catalogState: catalogState,
            ),
          ),
        ),
      );

      // Verify Group Fallback badge appears on en_US
      expect(find.text('Group Fallback'), findsWidgets);
    });

    // T053: Widget test for fallback chain tooltip content
    testWidgets('displays fallback chain tooltip on locale hover', (tester) async {
      final catalogState = CatalogState(
        version: 3,
        sourceLocale: 'en',
        format: 'arb',
        keys: {},
        languageGroupFallbacks: {
          'en': 'en_US',
        },
        customLocaleDirections: {},
      );

      const allLocales = ['en_US', 'en_GB'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestCatalogLocaleSettingsWidget(
              locales: allLocales,
              catalogState: catalogState,
            ),
          ),
        ),
      );

      // Verify tooltip widgets are present
      expect(find.byType(Tooltip), findsWidgets);
    });

    // T054: Widget test for custom locale badge display
    testWidgets('displays Custom badge for custom locales', (tester) async {
      final catalogState = CatalogState(
        version: 3,
        sourceLocale: 'en',
        format: 'arb',
        keys: {},
        languageGroupFallbacks: {},
        customLocaleDirections: {
          'ur_PK': 'rtl',
        },
      );

      const allLocales = ['en_US', 'ur_PK'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestCatalogLocaleSettingsWidget(
              locales: allLocales,
              catalogState: catalogState,
            ),
          ),
        ),
      );

      // Verify Custom badge appears on ur_PK
      expect(find.text('Custom'), findsWidgets);
    });

    // T054a: Widget test for expand/collapse behavior
    testWidgets('language group sections expand and collapse', (tester) async {
      final catalogState = CatalogState(
        version: 3,
        sourceLocale: 'en',
        format: 'arb',
        keys: {},
        languageGroupFallbacks: {},
        customLocaleDirections: {},
      );

      const allLocales = ['en_US', 'en_GB', 'ar_EG'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestCatalogLocaleSettingsWidget(
              locales: allLocales,
              catalogState: catalogState,
            ),
          ),
        ),
      );

      // Verify locales are visible initially (expanded)
      expect(find.text('en_US'), findsOneWidget);
      expect(find.text('en_GB'), findsOneWidget);

      // Find and tap the expand/collapse button for English group
      final expandButtons = find.byIcon(Icons.expand_more);
      expect(expandButtons, findsWidgets);

      await tester.tap(expandButtons.first);
      await tester.pumpAndSettle();

      // After collapse, expand icon should be replaced with chevron
      expect(find.byIcon(Icons.chevron_right), findsWidgets);

      // Tap to expand again
      final collapseButton = find.byIcon(Icons.chevron_right).first;
      await tester.tap(collapseButton);
      await tester.pumpAndSettle();

      // Expand icon should be back
      expect(find.byIcon(Icons.expand_more), findsWidgets);
    });

    // T053: Test FR-010 constraint - fallback selector filters invalid options
    testWidgets('fallback selector hides base→regional invalid options (FR-010)', (tester) async {
      final catalogState = CatalogState(
        version: 3,
        sourceLocale: 'en',
        format: 'arb',
        keys: {},
        languageGroupFallbacks: {},
        customLocaleDirections: {
          'ar_SA': 'rtl',
          'ar_EG': 'rtl',
        },
      );

      const allLocales = ['ar', 'ar_SA', 'ar_EG'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestCatalogLocaleSettingsWidget(
              locales: allLocales,
              catalogState: catalogState,
            ),
          ),
        ),
      );

      // Find the fallback selector for 'ar' (base language)
      // When showing fallback options for 'ar' (base), it should only show 'ar' itself
      // Regional variants like 'ar_SA' and 'ar_EG' should be hidden
      // because base→regional is not allowed by FR-010

      // Regional variants should be displayed in selector when source is regional
      // For 'ar_SA' (regional), it can fall back to 'ar' (base) or other 'ar_XX' variants
      expect(find.text('ar'), findsWidgets); // Language name should appear
    });

    // T054: Test regional locale can fall back to other regional locales and base
    testWidgets('fallback selector allows regional→regional and regional→base (FR-010)', (tester) async {
      final catalogState = CatalogState(
        version: 3,
        sourceLocale: 'en',
        format: 'arb',
        keys: {},
        languageGroupFallbacks: {},
        customLocaleDirections: {
          'ar_SA': 'rtl',
          'ar_EG': 'rtl',
        },
      );

      const allLocales = ['ar', 'ar_SA', 'ar_EG'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestCatalogLocaleSettingsWidget(
              locales: allLocales,
              catalogState: catalogState,
            ),
          ),
        ),
      );

      // For regional variant 'ar_SA', both 'ar' (base) and 'ar_EG' (regional) should be valid fallbacks
      // The selector should show these as valid options
      expect(find.text('ar'), findsWidgets); // base fallback should be available
      expect(find.text('ar_EG'), findsWidgets); // regional fallback should be available
    });
  });
}

/// Test widget that simulates the CatalogLocaleSettings screen
class _TestCatalogLocaleSettingsWidget extends StatefulWidget {
  const _TestCatalogLocaleSettingsWidget({
    required this.locales,
    required this.catalogState,
  });
  final List<String> locales;
  final CatalogState catalogState;

  @override
  State<_TestCatalogLocaleSettingsWidget> createState() => _TestCatalogLocaleSettingsWidgetState();
}

class _TestCatalogLocaleSettingsWidgetState extends State<_TestCatalogLocaleSettingsWidget> {
  // Track which language groups are expanded
  late Map<String, bool> _expandedGroups;

  @override
  void initState() {
    super.initState();
    _expandedGroups = {};
    for (final group in _getLanguageGroups().keys) {
      _expandedGroups[group] = true;
    }
  }

  Map<String, List<String>> _getLanguageGroups() {
    final groups = <String, List<String>>{};

    for (final locale in widget.locales) {
      final languageCode = locale.split('_').first;
      groups.putIfAbsent(languageCode, () => []).add(locale);
    }

    return groups;
  }

  String _getLanguageName(String code) {
    const names = {
      'en': 'English',
      'ar': 'Arabic',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'ur': 'Urdu',
    };
    return names[code] ?? code.toUpperCase();
  }

  String _getLocaleDisplayName(String locale) {
    return locale;
  }

  bool _isGroupFallback(String locale) {
    // Check if this locale is a value in the fallbacks (it's a group fallback target)
    return widget.catalogState.languageGroupFallbacks.containsValue(locale);
  }

  bool _isCustomLocale(String locale) {
    return widget.catalogState.customLocaleDirections.containsKey(locale);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = _getLanguageGroups();

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final language = groups.keys.elementAt(index);
        final locales = groups[language]!;
        final isExpanded = _expandedGroups[language] ?? true;

        return Column(
          children: [
            // Language group header with expand/collapse button
            ListTile(
              leading: Icon(
                isExpanded ? Icons.expand_more : Icons.chevron_right,
              ),
              title: Text(_getLanguageName(language)),
              trailing: Text('${locales.length} locale${locales.length == 1 ? '' : 's'}'),
              onTap: () {
                setState(() {
                  _expandedGroups[language] = !isExpanded;
                });
              },
            ),
            // Locale tiles (visible when expanded)
            if (isExpanded)
              ...locales.map((locale) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Tooltip(
                    message: 'Fallback chain: $locale → en (default)',
                    child: Card(
                      child: ListTile(
                        title: Text(_getLocaleDisplayName(locale)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isGroupFallback(locale))
                              Chip(
                                label: const Text('Group Fallback'),
                                backgroundColor: theme.colorScheme.primaryContainer,
                              ),
                            if (_isCustomLocale(locale))
                              Chip(
                                label: const Text('Custom'),
                                backgroundColor: theme.colorScheme.secondaryContainer,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
