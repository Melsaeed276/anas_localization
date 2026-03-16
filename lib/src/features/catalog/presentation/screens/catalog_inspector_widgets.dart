// Inspector panel widgets extracted from catalog_flutter_app.dart.
// No part/part-of — uses normal imports.

import 'package:flutter/material.dart';

import '../../domain/entities/catalog_models.dart';
import '../../l10n/l10n/generated/catalog_localizations.dart';
import '../controllers/catalog_ui_logic.dart';
import 'catalog_editor_widgets.dart';
import 'catalog_label_helpers.dart';
import 'catalog_queue_widgets.dart';
import 'catalog_shared_widgets.dart';
import 'catalog_status_widgets.dart';
import 'catalog_workspace_controllers.dart';

// ---------------------------------------------------------------------------
// Helper functions (were private in catalog_flutter_app.dart)
// ---------------------------------------------------------------------------

String catalogSyncLabel(CatalogLocalizations l10n, CatalogDraftSyncState state) {
  return switch (state) {
    CatalogDraftSyncState.clean => l10n.syncClean,
    CatalogDraftSyncState.dirty => l10n.syncDirty,
    CatalogDraftSyncState.saving => l10n.syncSaving,
    CatalogDraftSyncState.saved => l10n.syncSaved,
    CatalogDraftSyncState.saveError => l10n.syncError,
  };
}

List<CatalogReviewTarget> catalogReviewableTargetsForRow(
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

Future<void> catalogHandleBulkReviewForRow(
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

String catalogInspectorSheetSectionLabel(
  CatalogLocalizations l10n,
  CatalogInspectorSheetSection section,
) {
  return switch (section) {
    CatalogInspectorSheetSection.sourceContext => l10n.sourceContextSection,
    CatalogInspectorSheetSection.catalogContext => l10n.contextSection,
    CatalogInspectorSheetSection.activity => l10n.activitySection,
  };
}

String catalogActivityLabel(CatalogLocalizations l10n, CatalogActivityEvent event) {
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

IconData catalogActivityIcon(String kind) {
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

// ---------------------------------------------------------------------------
// CatalogInspectorPane
// ---------------------------------------------------------------------------

class CatalogInspectorPane extends StatelessWidget {
  const CatalogInspectorPane({
    super.key,
    required this.controller,
    required this.row,
    required this.locale,
    required this.layout,
    required this.onOpenInspectorSheet,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow row;
  final String locale;
  final CatalogLayout layout;
  final VoidCallback? onOpenInspectorSheet;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = layout == CatalogLayout.compact ? 112.0 : 24.0;
    return ListView(
      key: const ValueKey<String>('catalog-inspector-list'),
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      children: <Widget>[
        CatalogOverviewCard(
          controller: controller,
          row: row,
          locale: locale,
          compact: layout == CatalogLayout.compact,
          onOpenInspectorSheet: onOpenInspectorSheet,
        ),
        const SizedBox(height: 16),
        CatalogLocalesSectionCard(
          controller: controller,
          row: row,
          locale: locale,
          compact: layout == CatalogLayout.compact,
        ),
        const SizedBox(height: 16),
        CatalogNotesSectionCard(
          controller: controller,
          row: row,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CatalogOverviewCard
// ---------------------------------------------------------------------------

class CatalogOverviewCard extends StatelessWidget {
  const CatalogOverviewCard({
    super.key,
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
    final meta = controller.meta;
    if (meta == null) return const SizedBox.shrink();
    final namespace = controller.namespaceForKey(row.keyPath);
    final progress = catalogTargetLocaleProgress(row, meta);
    final reviewableTargets = catalogReviewableTargetsForRow(controller, row, l10n);

    return CatalogSectionCard(
      title: l10n.overviewSection,
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          StatusChip(
            label: catalogStatusLabel(l10n, row.rowStatus.name),
            status: row.rowStatus.name,
          ),
          SyncChip(
            label: catalogSyncLabel(l10n, controller.rowSyncState(row.keyPath)),
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
            catalogRowSummaryText(l10n, row),
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
                MetaPill(
                  icon: Icons.account_tree_outlined,
                  label: '${l10n.namespaceLabel}: $namespace',
                ),
              MetaPill(
                icon: Icons.flag_outlined,
                label: l10n.localeProgress(progress.ready, progress.total),
              ),
              if ((row.note ?? '').trim().isNotEmpty)
                MetaPill(
                  icon: Icons.sticky_note_2_outlined,
                  label: l10n.noteIndicator,
                ),
              MetaPill(
                icon: Icons.language_outlined,
                label: '${l10n.sourceLocaleMeta}: ${formatCatalogLocale(meta.sourceLocale)}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<DataType>(
            initialValue: row.dataType,
            decoration: const InputDecoration(
              labelText: 'Data type',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: DataType.values.map((DataType t) {
              return DropdownMenuItem<DataType>(
                value: t,
                child: Text(dataTypeToString(t)),
              );
            }).toList(),
            onChanged: (DataType? v) {
              if (v != null && v != row.dataType) {
                controller.updateKeyDataType(row, v);
              }
            },
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              if (reviewableTargets.isNotEmpty)
                FilledButton.tonalIcon(
                  onPressed: () => catalogHandleBulkReviewForRow(
                    context,
                    controller,
                    row,
                    reviewableTargets,
                  ),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(l10n.reviewPendingLocales),
                ),
              if (onOpenInspectorSheet != null)
                OutlinedButton.icon(
                  key: const ValueKey<String>('inspector-sheet-trigger-details'),
                  onPressed: onOpenInspectorSheet,
                  icon: const Icon(Icons.tune_outlined),
                  label: Text(l10n.detailsSection),
                ),
              TextButton.icon(
                onPressed: () => confirmDeleteKey(context, controller, row),
                icon: const Icon(Icons.delete_outline),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
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
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CatalogNotesSectionCard
// ---------------------------------------------------------------------------

class CatalogNotesSectionCard extends StatelessWidget {
  const CatalogNotesSectionCard({
    super.key,
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
    return CatalogSectionCard(
      title: l10n.notesSection,
      subtitle: l10n.noteAutosave,
      trailing: SyncChip(
        label: catalogSyncLabel(l10n, draft.syncState),
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
            ErrorBanner(
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

// ---------------------------------------------------------------------------
// CatalogSourceContextCard
// ---------------------------------------------------------------------------

class CatalogSourceContextCard extends StatelessWidget {
  const CatalogSourceContextCard({
    super.key,
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
    if (meta == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final sourceLocale = meta.sourceLocale;
    final sourceValue = row.valuesByLocale[sourceLocale];
    final placeholders = collectCatalogPlaceholders(sourceValue).toList()..sort();

    return CatalogSectionCard(
      title: l10n.sourceContextSection,
      subtitle: '${l10n.sourcePreviewLabel} · ${formatCatalogLocale(sourceLocale)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (locale == sourceLocale) ...<Widget>[
            BannerContainer(
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
            child: SourcePreview(
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
                return MetaPill(
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

// ---------------------------------------------------------------------------
// CatalogLocalesSectionCard
// ---------------------------------------------------------------------------

class CatalogLocalesSectionCard extends StatelessWidget {
  const CatalogLocalesSectionCard({
    super.key,
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
    final meta = controller.meta;
    if (meta == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final draft = controller.valueDraftFor(row, locale);
    final blockers = controller.validateDoneBlockers(row, locale, l10n);
    final typeWarnings = controller.listOptionalTypeWarnings(row, locale);
    final isSourceLocale = locale == meta.sourceLocale;

    return CatalogSectionCard(
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
              onPressed: blockers.isEmpty ? () => handleDone(context, controller, row, locale) : null,
              child: Text(l10n.done),
            ),
          SyncChip(
            label: catalogSyncLabel(l10n, draft.syncState),
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
                label: Text('${formatCatalogLocale(item)} · ${catalogStatusLabel(l10n, status)}'),
                selected: item == locale,
                onSelected: (_) => controller.selectLocale(item),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ReasonBanner(
            controller: controller,
            row: row,
            locale: locale,
          ),
          if (draft.errorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            ErrorBanner(
              message: draft.errorMessage!,
              onRetry: () => controller.flushValueDraft(row, locale),
            ),
          ],
          if (blockers.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            BannerContainer(
              icon: Icons.warning_amber_outlined,
              color: theme.colorScheme.tertiaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: blockers.map(Text.new).toList(),
              ),
            ),
          ],
          if (typeWarnings.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            BannerContainer(
              icon: Icons.info_outline,
              color: theme.colorScheme.secondaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.typeWarningTitle,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  ...typeWarnings.map(Text.new),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          CatalogInlineSourcePreviewCard(
            controller: controller,
            row: row,
          ),
          const SizedBox(height: 16),
          ValueEditor(
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
                if (row.valuesByLocale[locale] == null)
                  FilledButton.icon(
                    onPressed: () {
                      final sourceValue = row.valuesByLocale[meta.sourceLocale];
                      if (sourceValue != null) {
                        controller.updatePlainDraft(row: row, locale: locale, text: sourceValue.toString());
                      } else {
                        controller.updatePlainDraft(row: row, locale: locale, text: '');
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.create),
                  )
                else
                  TextButton.icon(
                    onPressed: () => confirmDeleteValue(context, controller, row, locale),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.deleteValue),
                  ),
                if (!isSourceLocale)
                  FilledButton.tonalIcon(
                    onPressed: blockers.isEmpty ? () => handleDone(context, controller, row, locale) : null,
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

// ---------------------------------------------------------------------------
// CatalogInlineSourcePreviewCard
// ---------------------------------------------------------------------------

class CatalogInlineSourcePreviewCard extends StatelessWidget {
  const CatalogInlineSourcePreviewCard({
    super.key,
    required this.controller,
    required this.row,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final meta = controller.meta;
    if (meta == null) return const SizedBox.shrink();
    final sourceLocale = meta.sourceLocale;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
          SourcePreview(
            controller: controller,
            value: row.valuesByLocale[sourceLocale],
            locale: sourceLocale,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CatalogContextMetaCard
// ---------------------------------------------------------------------------

class CatalogContextMetaCard extends StatelessWidget {
  const CatalogContextMetaCard({
    super.key,
    required this.controller,
  });

  final CatalogWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final meta = controller.meta;
    if (meta == null) return const SizedBox.shrink();
    return CatalogSectionCard(
      title: l10n.contextSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MetaLine(
            label: l10n.sourceLocaleMeta,
            value: formatCatalogLocale(meta.sourceLocale),
          ),
          const SizedBox(height: 10),
          MetaLine(
            label: l10n.fallbackLocaleMeta,
            value: formatCatalogLocale(meta.fallbackLocale),
          ),
          const SizedBox(height: 10),
          MetaLine(
            label: l10n.formatMeta,
            value: meta.format.toUpperCase(),
          ),
          const SizedBox(height: 10),
          MetaLine(
            label: l10n.stateFileMeta,
            value: meta.stateFilePath,
            selectable: true,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CatalogInspectorSideSheet
// ---------------------------------------------------------------------------

class CatalogInspectorSideSheet extends StatelessWidget {
  const CatalogInspectorSideSheet({
    super.key,
    required this.controller,
    required this.row,
    required this.locale,
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final CatalogWorkspaceController controller;
  final CatalogRow? row;
  final String locale;
  final CatalogInspectorSheetSection selectedSection;
  final ValueChanged<CatalogInspectorSheetSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final theme = Theme.of(context);

    return Material(
      key: const ValueKey<String>('catalog-inspector-sheet'),
      color: theme.colorScheme.surface,
      elevation: 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(16),
          bottomStart: Radius.circular(16),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SafeArea(
          child: (row == null)
              ? CatalogSelectionPlaceholder(
                  title: l10n.contextSection,
                  message: l10n.selectionPlaceholderBody,
                )
              : Builder(
                  builder: (context) {
                    final row = this.row!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 10, 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.9),
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        l10n.detailsSection,
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      SelectableText(
                                        row.keyPath,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        catalogInspectorSheetSectionLabel(l10n, selectedSection),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
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
                            const SizedBox(height: 14),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: CatalogInspectorSheetSection.values.map((section) {
                                  return Padding(
                                    padding: const EdgeInsetsDirectional.only(end: 8),
                                    child: ChoiceChip(
                                      key: ValueKey<String>('inspector-sheet-tab-${section.keyValue}'),
                                      avatar: Icon(section.icon, size: 18),
                                      label: Text(catalogInspectorSheetSectionLabel(l10n, section)),
                                      selected: selectedSection == section,
                                      onSelected: (_) => onSectionSelected(section),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: catalogMotionDuration,
                          switchInCurve: catalogMotionCurve,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final offsetAnimation = Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(parent: animation, curve: catalogMotionCurve));
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(position: offsetAnimation, child: child),
                            );
                          },
                          child: ListView(
                            key: ValueKey<String>('inspector-sheet-content-${selectedSection.keyValue}'),
                            padding: const EdgeInsets.all(16),
                            children: <Widget>[
                              switch (selectedSection) {
                                CatalogInspectorSheetSection.sourceContext => CatalogSourceContextCard(
                                    controller: controller,
                                    row: row,
                                    locale: locale,
                                  ),
                                CatalogInspectorSheetSection.catalogContext => CatalogContextMetaCard(
                                    controller: controller,
                                  ),
                                CatalogInspectorSheetSection.activity => CatalogActivityTimelineCard(
                                    controller: controller,
                                  ),
                              },
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CatalogActivityTimelineCard
// ---------------------------------------------------------------------------

class CatalogActivityTimelineCard extends StatelessWidget {
  const CatalogActivityTimelineCard({
    super.key,
    required this.controller,
  });

  final CatalogWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    Widget content;
    if (controller.activityLoading) {
      content = const CatalogActivitySkeleton();
    } else if (controller.activityError != null) {
      content = ErrorBanner(
        message: controller.activityError!,
        onRetry: controller.refresh,
      );
    } else if (controller.activityEvents.isEmpty) {
      content = CatalogEmptyStateCard(
        icon: Icons.history_toggle_off_outlined,
        title: l10n.activitySection,
        message: l10n.activityEmpty,
        compact: true,
      );
    } else {
      content = Column(
        children: controller.activityEvents.map((event) {
          final subtitle = controller.formatTimestamp(event.timestamp, locale);
          final eventLabel = catalogActivityLabel(l10n, event);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(catalogActivityIcon(event.kind)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(eventLabel),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return CatalogSectionCard(
      title: l10n.activitySection,
      child: content,
    );
  }
}

// ---------------------------------------------------------------------------
// CompactInspectorActionBar
// ---------------------------------------------------------------------------

class CompactInspectorActionBar extends StatelessWidget {
  const CompactInspectorActionBar({
    super.key,
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
                  child: row.valuesByLocale[locale] == null
                      ? FilledButton.icon(
                          onPressed: () {
                            final sourceValue = row.valuesByLocale[meta.sourceLocale];
                            if (sourceValue != null) {
                              controller.updatePlainDraft(row: row, locale: locale, text: sourceValue.toString());
                            } else {
                              controller.updatePlainDraft(row: row, locale: locale, text: '');
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: Text(l10n.create),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => confirmDeleteValue(context, controller, row, locale),
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l10n.deleteValue),
                        ),
                ),
                if (!isSourceLocale) ...<Widget>[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: blockers.isEmpty ? () => handleDone(context, controller, row, locale) : null,
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
