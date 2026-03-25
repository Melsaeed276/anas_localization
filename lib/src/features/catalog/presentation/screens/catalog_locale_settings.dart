import 'package:flutter/material.dart';

import '../../domain/entities/catalog_models.dart';
import '../../l10n/generated/catalog_localizations.dart';
import '/src/shared/services/logging/logging_service.dart';
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
                  allLocales: locales,
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
// _LocaleSettingsTile — Individual locale tile with interactive fallback selector
// ---------------------------------------------------------------------------

class _LocaleSettingsTile extends StatefulWidget {
  const _LocaleSettingsTile({
    required this.locale,
    required this.catalogState,
    required this.sourceLocale,
    required this.allLocales,
  });

  final String locale;
  final CatalogState catalogState;
  final String sourceLocale;
  final List<String> allLocales;

  @override
  State<_LocaleSettingsTile> createState() => _LocaleSettingsTileState();
}

class _LocaleSettingsTileState extends State<_LocaleSettingsTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroupFallback = _isGroupFallback();
    final isCustomLocale = _isCustomLocale();

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Card(
        color: theme.colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                formatCatalogLocale(widget.locale),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isGroupFallback ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              subtitle: _getSubtitle(),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isGroupFallback) ...[
                    const _GroupFallbackBadge(),
                    const SizedBox(width: 8),
                  ],
                  if (isCustomLocale) ...[
                    const _CustomLocaleBadge(),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    tooltip: _isExpanded ? 'Collapse' : 'Expand',
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Fallback selector (expanded section)
            if (_isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildFallbackSelector(context, theme),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _getSubtitle() {
    final theme = Theme.of(context);
    final languageCode = widget.locale.split('_').first;
    final fallback = widget.catalogState.languageGroupFallbacks[languageCode];

    if (fallback == null || fallback == widget.locale) {
      return Text(
        'No fallback configured',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Text(
      'Fallback: ${formatCatalogLocale(fallback)}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFallbackSelector(BuildContext context, ThemeData theme) {
    final languageCode = widget.locale.split('_').first;
    final allLocalesInGroup = widget.allLocales..sort();

    // Get current fallback
    final currentFallback = widget.catalogState.languageGroupFallbacks[languageCode];

    if (allLocalesInGroup.length <= 1) {
      return Text(
        'No other locales in this language group',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select fallback locale for $languageCode group:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // Option: None
        RadioListTile<String?>(
          value: null,
          // ignore: deprecated_member_use
          groupValue: currentFallback,
          // ignore: deprecated_member_use
          onChanged: (value) => _onFallbackChanged(context, languageCode, value),
          title: Text(
            'None (no fallback)',
            style: theme.textTheme.bodyMedium,
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        // Options: Other locales in group (filtered for FR-010 compliance)
        ...allLocalesInGroup.where((locale) {
          // Filter out current locale
          if (locale == widget.locale) return false;

          // FR-010: Base language cannot fall back to regional variant
          final sourceIsRegional = widget.locale.contains('_');
          final targetIsRegional = locale.contains('_');
          if (!sourceIsRegional && targetIsRegional) {
            return false; // Invalid direction: base→regional
          }

          return true;
        }).map((locale) {
          return RadioListTile<String>(
            value: locale,
            // ignore: deprecated_member_use
            groupValue: currentFallback,
            // ignore: deprecated_member_use
            onChanged: (value) => _onFallbackChanged(context, languageCode, value),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    formatCatalogLocale(locale),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (locale == widget.sourceLocale)
                  Chip(
                    label: const Text('Source', style: TextStyle(fontSize: 11)),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  Future<void> _onFallbackChanged(
    BuildContext context,
    String languageCode,
    String? newFallback,
  ) async {
    try {
      // For now, just log the change
      // In a real app, this would call the CatalogService to persist the change
      logger.debug(
        'Fallback changed for $languageCode group: ${newFallback ?? "None"} (preview mode)',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newFallback == null
                ? 'Fallback for $languageCode cleared (preview mode)'
                : 'Fallback for $languageCode set to ${formatCatalogLocale(newFallback)} (preview mode)',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  bool _isGroupFallback() {
    return widget.catalogState.languageGroupFallbacks.containsValue(widget.locale);
  }

  bool _isCustomLocale() {
    return widget.catalogState.customLocaleDirections.containsKey(widget.locale);
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
