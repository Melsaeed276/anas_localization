import 'package:flutter/material.dart';

import '../../domain/entities/catalog_models.dart';
import '../../l10n/generated/catalog_localizations.dart';
import 'catalog_toolbar_widgets.dart';
import 'catalog_workspace_controllers.dart';

// ---------------------------------------------------------------------------
// CatalogLocaleSettings — Modal for visualizing language groups and fallbacks
// ---------------------------------------------------------------------------

class CatalogLocaleSettings extends StatefulWidget {
  const CatalogLocaleSettings({
    super.key,
    required this.workspaceController,
  });

  final CatalogWorkspaceController workspaceController;

  @override
  State<CatalogLocaleSettings> createState() => _CatalogLocaleSettingsState();
}

class _CatalogLocaleSettingsState extends State<CatalogLocaleSettings> {
  late Map<String, bool> _expandedGroups;
  late List<String> _locales;
  late CatalogState _catalogState;
  late String _sourceLocale;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final meta = widget.workspaceController.meta;
    _sourceLocale = meta?.sourceLocale ?? 'en';
    _locales = meta?.locales ?? [];
    _catalogState = CatalogState.empty(
      sourceLocale: _sourceLocale,
      format: meta?.format ?? 'arb',
    );
    _initializeExpandedState();
  }

  void _initializeExpandedState() {
    final groups = _getLanguageGroups();
    _expandedGroups = {};
    for (final group in groups.keys) {
      _expandedGroups[group] = true;
    }
  }

  Map<String, List<String>> _getLanguageGroups() {
    final groups = <String, List<String>>{};
    for (final locale in _locales) {
      final languageCode = locale.split('_').first;
      groups.putIfAbsent(languageCode, () => []).add(locale);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.projectLocales),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: _buildLocaleGroupsList(),
        ),
      ),
    );
  }

  Widget _buildLocaleGroupsList() {
    final theme = Theme.of(context);
    final groups = _getLanguageGroups();

    if (groups.isEmpty) {
      return Center(
        child: Text(
          'No locales available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Sort groups by language code for consistency
    final sortedGroupKeys = groups.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedGroupKeys.length,
      itemBuilder: (context, index) {
        final languageCode = sortedGroupKeys[index];
        final locales = groups[languageCode]!;
        final isExpanded = _expandedGroups[languageCode] ?? true;

        return Column(
          children: [
            // Language group header with expand/collapse
            _LanguageGroupHeader(
              languageCode: languageCode,
              isExpanded: isExpanded,
              localeCount: locales.length,
              onTap: () {
                setState(() {
                  _expandedGroups[languageCode] = !isExpanded;
                });
              },
            ),
            // Locale tiles (visible when expanded)
            if (isExpanded)
              ...locales.map((locale) {
                return _LocaleSettingsTile(
                  locale: locale,
                  catalogState: _catalogState,
                  sourceLocale: _sourceLocale,
                );
              }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _LanguageGroupHeader — Expandable header for a language group
// ---------------------------------------------------------------------------

class _LanguageGroupHeader extends StatelessWidget {
  const _LanguageGroupHeader({
    required this.languageCode,
    required this.isExpanded,
    required this.localeCount,
    required this.onTap,
  });

  final String languageCode;
  final bool isExpanded;
  final int localeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        isExpanded ? Icons.expand_more : Icons.chevron_right,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        _getLanguageName(languageCode),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
      subtitle: Text(
        '$localeCount locale${localeCount == 1 ? '' : 's'}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
    );
  }

  String _getLanguageName(String code) {
    const names = {
      'en': 'English',
      'ar': 'Arabic',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'hi': 'Hindi',
      'tr': 'Turkish',
      'nl': 'Dutch',
      'pl': 'Polish',
      'sv': 'Swedish',
      'da': 'Danish',
      'no': 'Norwegian',
      'fi': 'Finnish',
      'th': 'Thai',
      'vi': 'Vietnamese',
      'id': 'Indonesian',
      'ms': 'Malay',
      'he': 'Hebrew',
      'fa': 'Persian',
      'ur': 'Urdu',
      'bn': 'Bengali',
      'ta': 'Tamil',
      'te': 'Telugu',
      'mr': 'Marathi',
      'gu': 'Gujarati',
      'kn': 'Kannada',
      'ml': 'Malayalam',
    };
    return names[code] ?? code.toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// _LocaleSettingsTile — Individual locale tile with badges and tooltips
// ---------------------------------------------------------------------------

class _LocaleSettingsTile extends StatelessWidget {
  const _LocaleSettingsTile({
    required this.locale,
    required this.catalogState,
    required this.sourceLocale,
  });

  final String locale;
  final CatalogState catalogState;
  final String sourceLocale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroupFallback = _isGroupFallback();
    final isCustomLocale = _isCustomLocale();

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
      child: Tooltip(
        message: _getTooltipMessage(),
        child: Card(
          color: theme.colorScheme.surfaceContainerLow,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ListTile(
            title: Text(
              formatCatalogLocale(locale),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isGroupFallback ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGroupFallback) ...[
                  const _GroupFallbackBadge(),
                  const SizedBox(width: 8),
                ],
                if (isCustomLocale) const _CustomLocaleBadge(),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  bool _isGroupFallback() {
    return catalogState.languageGroupFallbacks.containsValue(locale);
  }

  bool _isCustomLocale() {
    return catalogState.customLocaleDirections.containsKey(locale);
  }

  String _getTooltipMessage() {
    // Build a simple fallback chain: locale → sourceLocale
    return '$locale → $sourceLocale';
  }
}

// ---------------------------------------------------------------------------
// _GroupFallbackBadge — Badge showing group fallback designation
// ---------------------------------------------------------------------------

class _GroupFallbackBadge extends StatelessWidget {
  const _GroupFallbackBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      label: const Text(
        'Group Fallback',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: theme.colorScheme.onPrimaryContainer,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      side: BorderSide.none,
    );
  }
}

// ---------------------------------------------------------------------------
// _CustomLocaleBadge — Badge showing custom locale designation
// ---------------------------------------------------------------------------

class _CustomLocaleBadge extends StatelessWidget {
  const _CustomLocaleBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      label: const Text(
        'Custom',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: theme.colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: theme.colorScheme.onSecondaryContainer,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      side: BorderSide.none,
    );
  }
}
