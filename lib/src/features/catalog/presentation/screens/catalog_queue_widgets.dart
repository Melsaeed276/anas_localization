import 'package:flutter/material.dart';

import '../../domain/entities/catalog_models.dart';
import '../../l10n/generated/catalog_localizations.dart';
import '../controllers/catalog_ui_logic.dart';
import 'catalog_label_helpers.dart';
import 'catalog_shared_widgets.dart';
import 'catalog_status_widgets.dart';
import 'catalog_ui_enums.dart';
import 'catalog_workspace_controllers.dart';

// ---------------------------------------------------------------------------
// Helper functions (made public from private originals in catalog_flutter_app)
// ---------------------------------------------------------------------------

String catalogQueueHeadline(CatalogLocalizations l10n, CatalogSummary? summary) {
  if (summary == null) {
    return l10n.loading;
  }
  return '${summary.warningRows} ${l10n.reviewRowsLabel} · ${summary.redRows} ${l10n.missingRowsLabel}';
}

String catalogQueueSectionLabel(CatalogLocalizations l10n, CatalogQueueSection section) {
  return switch (section) {
    CatalogQueueSection.missing => l10n.filterMissing,
    CatalogQueueSection.needsReview => l10n.filterNeedsReview,
    CatalogQueueSection.ready => l10n.filterReady,
  };
}

String catalogStatusFilterLabel(CatalogLocalizations l10n, CatalogRowStatusFilter filter) {
  return switch (filter) {
    CatalogRowStatusFilter.all => l10n.filterAll,
    CatalogRowStatusFilter.ready => l10n.filterReady,
    CatalogRowStatusFilter.needsReview => l10n.filterNeedsReview,
    CatalogRowStatusFilter.missing => l10n.filterMissing,
  };
}

String catalogStatusLabel(CatalogLocalizations l10n, String status) {
  return switch (status) {
    'green' => l10n.statusReady,
    'red' => l10n.statusMissing,
    _ => l10n.statusNeedsReview,
  };
}

String catalogRowSummaryText(CatalogLocalizations l10n, CatalogRow row) {
  if (row.missingLocales.isNotEmpty) {
    return '${l10n.missingLabel}: ${row.missingLocales.map(formatCatalogLocale).join(', ')}';
  }
  if (row.pendingLocales.isNotEmpty) {
    return '${l10n.pendingLabel}: ${row.pendingLocales.map(formatCatalogLocale).join(', ')}';
  }
  return l10n.allTargetsReady;
}

Color catalogStatusColor(ColorScheme scheme, CatalogCellStatus status) {
  return switch (status) {
    CatalogCellStatus.green => scheme.secondary,
    CatalogCellStatus.red => scheme.error,
    CatalogCellStatus.warning => scheme.tertiary,
  };
}

CatalogTargetLocaleProgress catalogTargetLocaleProgress(CatalogRow row, CatalogMeta meta) {
  final targetLocales = meta.locales.where((locale) => locale != meta.sourceLocale).toList();
  if (targetLocales.isEmpty) {
    final sourceReady = row.cellStates[meta.sourceLocale]?.status == CatalogCellStatus.green ? 1 : 0;
    return CatalogTargetLocaleProgress(ready: sourceReady, total: 1);
  }
  final ready = targetLocales.where((locale) => row.cellStates[locale]?.status == CatalogCellStatus.green).length;
  return CatalogTargetLocaleProgress(ready: ready, total: targetLocales.length);
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class CatalogWorkspaceBody extends StatelessWidget {
  const CatalogWorkspaceBody({
    super.key,
    required this.controller,
    required this.layout,
    required this.onOpenInspectorSheet,
    required this.inspectorBuilder,
  });

  final CatalogWorkspaceController controller;
  final CatalogLayout layout;
  final VoidCallback? onOpenInspectorSheet;

  /// Builds the inspector pane. Provided as a builder to avoid a circular
  /// import between queue and inspector widgets.
  final Widget Function({
    required CatalogWorkspaceController controller,
    required CatalogRow row,
    required String locale,
    required CatalogLayout layout,
    required VoidCallback? onOpenInspectorSheet,
  }) inspectorBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final selectedRow = controller.selectedRow;
    final selectedLocale = controller.selectedLocale ?? controller.defaultEditorLocale;
    final showCompactDetail = layout == CatalogLayout.compact && controller.compactDetailOpen && selectedRow != null;

    if (layout == CatalogLayout.compact) {
      if (!showCompactDetail) {
        return CatalogQueuePane(
          controller: controller,
          layout: layout,
        );
      }
      return inspectorBuilder(
        controller: controller,
        row: selectedRow,
        locale: selectedLocale,
        layout: layout,
        onOpenInspectorSheet: onOpenInspectorSheet,
      );
    }

    if (layout == CatalogLayout.medium) {
      return Row(
        children: <Widget>[
          SizedBox(
            width: 380,
            child: CatalogQueuePane(
              controller: controller,
              layout: layout,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: selectedRow == null
                ? CatalogSelectionPlaceholder(
                    title: l10n.selectionPlaceholderTitle,
                    message: l10n.selectionPlaceholderBody,
                  )
                : inspectorBuilder(
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
          child: CatalogQueuePane(
            controller: controller,
            layout: layout,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 5,
          child: selectedRow == null
              ? CatalogSelectionPlaceholder(
                  title: l10n.selectionPlaceholderTitle,
                  message: l10n.selectionPlaceholderBody,
                )
              : inspectorBuilder(
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

class CatalogQueuePane extends StatelessWidget {
  const CatalogQueuePane({
    super.key,
    required this.controller,
    required this.layout,
  });

  final CatalogWorkspaceController controller;
  final CatalogLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = controller.summary;
    final visibleSections = controller.visibleSections
        .where(
          (section) => controller.statusFilter != CatalogRowStatusFilter.all || controller.sectionCount(section) > 0,
        )
        .toList();

    Widget content;
    if (controller.loading && controller.rows.isEmpty) {
      content = const CatalogQueueSkeleton();
    } else if (!controller.hasAnyKeys) {
      content = CatalogEmptyStateCard(
        icon: Icons.add_chart_outlined,
        title: l10n.noKeysTitle,
        message: l10n.noKeysBody,
      );
    } else if (controller.rows.isEmpty) {
      content = CatalogEmptyStateCard(
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
            child: CatalogQueueSectionCard(
              controller: controller,
              section: section,
              rows: controller.rowsForSection(section),
              compact: layout == CatalogLayout.compact,
            ),
          );
        }).toList(),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.queueTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  catalogQueueHeadline(l10n, summary),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
                    ),
                    boxShadow: catalogShadows(theme.colorScheme),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      CatalogSearchField(
                        value: controller.search,
                        onChanged: controller.updateSearch,
                      ),
                      const SizedBox(height: 12),
                      CatalogQueueToolbar(
                        controller: controller,
                      ),
                      if (summary != null && layout == CatalogLayout.compact) ...<Widget>[
                        const SizedBox(height: 14),
                        CatalogSummaryStrip(summary: summary),
                      ],
                    ],
                  ),
                ),
                if (controller.error != null && controller.meta != null) ...<Widget>[
                  const SizedBox(height: 16),
                  ErrorBanner(
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

class CatalogQueueToolbar extends StatefulWidget {
  const CatalogQueueToolbar({
    super.key,
    required this.controller,
  });

  final CatalogWorkspaceController controller;

  @override
  State<CatalogQueueToolbar> createState() => _CatalogQueueToolbarState();
}

class _CatalogQueueToolbarState extends State<CatalogQueueToolbar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final theme = Theme.of(context);

    // Primary filters that are always visible
    final primaryFilters = [
      CatalogRowStatusFilter.all,
      CatalogRowStatusFilter.needsReview,
      CatalogRowStatusFilter.missing,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ...primaryFilters.map((filter) {
              final selected = widget.controller.statusFilter == filter;
              return FilterChip(
                selected: selected,
                showCheckmark: filter == CatalogRowStatusFilter.all,
                label: Text(catalogStatusFilterLabel(l10n, filter)),
                onSelected: (_) {
                  widget.controller.updateStatusFilter(filter);
                },
              );
            }),
            IconButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: IconButton.styleFrom(
                backgroundColor: _expanded ? theme.colorScheme.primaryContainer : null,
                foregroundColor: _expanded ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
              ),
              icon: Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
              ),
              tooltip: _expanded ? 'Show less' : 'Show more',
            ),
            if (_expanded) ...<Widget>[
              FilterChip(
                selected: widget.controller.statusFilter == CatalogRowStatusFilter.ready,
                label: Text(catalogStatusFilterLabel(l10n, CatalogRowStatusFilter.ready)),
                onSelected: (_) {
                  widget.controller.updateStatusFilter(CatalogRowStatusFilter.ready);
                },
              ),
              CatalogSortMenu(
                current: widget.controller.sortMode,
                onSelected: widget.controller.updateSortMode,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class CatalogSortMenu extends StatelessWidget {
  const CatalogSortMenu({
    super.key,
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
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
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

class CatalogSummaryStrip extends StatelessWidget {
  const CatalogSummaryStrip({
    super.key,
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
        CatalogMetricChip(
          icon: Icons.key_outlined,
          value: summary.totalKeys.toString(),
          label: l10n.keysLabel,
        ),
        CatalogMetricChip(
          icon: Icons.check_circle_outline,
          value: summary.greenRows.toString(),
          label: l10n.readyRowsLabel,
        ),
        CatalogMetricChip(
          icon: Icons.fact_check_outlined,
          value: summary.warningRows.toString(),
          label: l10n.reviewRowsLabel,
        ),
        CatalogMetricChip(
          icon: Icons.error_outline,
          value: summary.redRows.toString(),
          label: l10n.missingRowsLabel,
        ),
      ],
    );
  }
}

class CatalogMetricChip extends StatelessWidget {
  const CatalogMetricChip({
    super.key,
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
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
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

class CatalogSearchField extends StatefulWidget {
  const CatalogSearchField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<CatalogSearchField> createState() => _CatalogSearchFieldState();
}

class _CatalogSearchFieldState extends State<CatalogSearchField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant CatalogSearchField oldWidget) {
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

class CatalogQueueSectionCard extends StatelessWidget {
  const CatalogQueueSectionCard({
    super.key,
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
    final headerColor = catalogStatusColor(theme.colorScheme, section.status);
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
                      catalogQueueSectionLabel(l10n, section),
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
                  return CatalogQueueRowCard(
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

class CatalogQueueRowCard extends StatelessWidget {
  const CatalogQueueRowCard({
    super.key,
    required this.controller,
    required this.row,
    required this.compact,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow row;
  final bool compact;

  String? _previewTextFor(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim().isEmpty ? null : value.trim();
    if (value is Map) return '{...}';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final theme = Theme.of(context);
    final meta = controller.meta;
    if (meta == null) return const SizedBox.shrink();
    final selected = row.keyPath == controller.selectedKey;
    final rowSyncState = controller.rowSyncState(row.keyPath);
    final progress = catalogTargetLocaleProgress(row, meta);
    final statusColor = catalogStatusColor(theme.colorScheme, row.rowStatus);
    final activeLocale = controller.selectedLocale ?? controller.defaultEditorLocale;

    return Material(
      key: ValueKey<String>('queue-row-${row.keyPath}'),
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => controller.selectRow(row.keyPath),
        child: AnimatedContainer(
          duration: catalogMotionDuration,
          curve: catalogMotionCurve,
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.secondaryContainer : theme.colorScheme.surface,
            border: Border.all(
              color: selected ? theme.colorScheme.primary.withValues(alpha: 0.28) : theme.colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: catalogShadows(
              theme.colorScheme,
              emphasized: selected,
            ),
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
                            if ((row.note ?? '').trim().isNotEmpty) ...<Widget>[
                              Tooltip(
                                message: l10n.noteIndicator,
                                child: Icon(
                                  Icons.sticky_note_2_outlined,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            QueueSyncIndicator(state: rowSyncState),
                            const SizedBox(width: 8),
                            StatusChip(
                              label: catalogStatusLabel(l10n, row.rowStatus.name),
                              status: row.rowStatus.name,
                            ),
                            if (compact && !selected) ...<Widget>[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                        if (selected) ...<Widget>[
                          const SizedBox(height: 12),
                          if ((row.note ?? '').trim().isNotEmpty) ...<Widget>[
                            Text(
                              row.note!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: meta.locales.map((locale) {
                              final isSelectedLocale = locale == activeLocale;
                              final cellStatus = row.cellStates[locale]?.status ?? CatalogCellStatus.warning;
                              return ChoiceChip(
                                showCheckmark: false,
                                label: Text(formatCatalogLocale(locale)),
                                selected: isSelectedLocale,
                                onSelected: (_) => controller.selectLocale(locale),
                                side: BorderSide(
                                  color: isSelectedLocale
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                ),
                                avatar: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: catalogStatusColor(theme.colorScheme, cellStatus),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _previewTextFor(row.valuesByLocale[activeLocale]) ?? l10n.blockerTranslationEmpty,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: _previewTextFor(row.valuesByLocale[activeLocale]) == null
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: _previewTextFor(row.valuesByLocale[activeLocale]) == null
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ] else ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            catalogRowSummaryText(l10n, row),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
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
                                  l10n.localeProgress(progress.ready, progress.total),
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
