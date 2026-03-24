import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/catalog_models.dart';
import '../../domain/services/catalog_flatten.dart';
import '../../domain/services/catalog_status_engine.dart';
import '../controllers/catalog_ui_logic.dart';
import '../../l10n/generated/catalog_localizations.dart';
import 'catalog_preferences_controller.dart';
import 'catalog_ui_enums.dart';
import 'catalog_workspace_controllers.dart';
import 'catalog_shared_widgets.dart';

// ---------------------------------------------------------------------------
// Value-object
// ---------------------------------------------------------------------------

class CatalogTargetLocaleProgress {
  const CatalogTargetLocaleProgress({
    required this.ready,
    required this.total,
  });

  final int ready;
  final int total;
}

// ---------------------------------------------------------------------------
// Pure helpers — no Flutter widgets
// ---------------------------------------------------------------------------

CatalogTargetLocaleProgress targetLocaleProgress(CatalogRow row, CatalogMeta meta) {
  final targetLocales = meta.locales.where((locale) => locale != meta.sourceLocale).toList();
  if (targetLocales.isEmpty) {
    final sourceReady = row.cellStates[meta.sourceLocale]?.status == CatalogCellStatus.green ? 1 : 0;
    return CatalogTargetLocaleProgress(ready: sourceReady, total: 1);
  }
  final ready = targetLocales.where((locale) => row.cellStates[locale]?.status == CatalogCellStatus.green).length;
  return CatalogTargetLocaleProgress(ready: ready, total: targetLocales.length);
}

String queueHeadline(CatalogLocalizations l10n, CatalogSummary? summary) {
  if (summary == null) {
    return l10n.loading;
  }
  return '${summary.warningRows} ${l10n.reviewRowsLabel} · ${summary.redRows} ${l10n.missingRowsLabel}';
}

String queueSectionLabel(CatalogLocalizations l10n, CatalogQueueSection section) {
  return switch (section) {
    CatalogQueueSection.missing => l10n.filterMissing,
    CatalogQueueSection.needsReview => l10n.filterNeedsReview,
    CatalogQueueSection.ready => l10n.filterReady,
  };
}

Color statusColor(ColorScheme scheme, CatalogCellStatus status) {
  return switch (status) {
    CatalogCellStatus.green => scheme.secondary,
    CatalogCellStatus.red => scheme.error,
    CatalogCellStatus.warning => scheme.tertiary,
  };
}

List<CatalogReviewTarget> reviewableTargetsForRow(
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

Future<void> handleBulkReviewForRow(
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
    final l10n = CatalogLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.reviewPendingSuccess(targets.length)),
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

String inspectorSheetSectionLabel(
  CatalogLocalizations l10n,
  CatalogInspectorSheetSection section,
) {
  return switch (section) {
    CatalogInspectorSheetSection.sourceContext => l10n.sourceContextSection,
    CatalogInspectorSheetSection.catalogContext => l10n.contextSection,
    CatalogInspectorSheetSection.activity => l10n.activitySection,
  };
}

String activityLabel(CatalogLocalizations l10n, CatalogActivityEvent event) {
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

IconData activityIcon(String kind) {
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

String statusFilterLabel(CatalogLocalizations l10n, CatalogRowStatusFilter filter) {
  return switch (filter) {
    CatalogRowStatusFilter.all => l10n.filterAll,
    CatalogRowStatusFilter.ready => l10n.filterReady,
    CatalogRowStatusFilter.needsReview => l10n.filterNeedsReview,
    CatalogRowStatusFilter.missing => l10n.filterMissing,
  };
}

String statusLabel(CatalogLocalizations l10n, String status) {
  return switch (status) {
    'green' => l10n.statusReady,
    'red' => l10n.statusMissing,
    _ => l10n.statusNeedsReview,
  };
}

String reasonLabel(CatalogLocalizations l10n, String reason) {
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

String syncLabel(CatalogLocalizations l10n, CatalogDraftSyncState state) {
  return switch (state) {
    CatalogDraftSyncState.clean => l10n.syncClean,
    CatalogDraftSyncState.dirty => l10n.syncDirty,
    CatalogDraftSyncState.saving => l10n.syncSaving,
    CatalogDraftSyncState.saved => l10n.syncSaved,
    CatalogDraftSyncState.saveError => l10n.syncError,
  };
}

String rowSummaryText(CatalogLocalizations l10n, CatalogRow row) {
  if (row.missingLocales.isNotEmpty) {
    return '${l10n.missingLabel}: ${row.missingLocales.map(formatCatalogLocale).join(', ')}';
  }
  if (row.pendingLocales.isNotEmpty) {
    return '${l10n.pendingLabel}: ${row.pendingLocales.map(formatCatalogLocale).join(', ')}';
  }
  return l10n.allTargetsReady;
}

// ---------------------------------------------------------------------------
// Dialog helpers
// ---------------------------------------------------------------------------

Future<void> showDisplayLanguageDialog(
  BuildContext context,
  CatalogPreferencesController preferencesController,
) async {
  final l10n = CatalogLocalizations.of(context);
  var selected = preferencesController.displayLanguage;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.catalogLanguage),
            content: SizedBox(
              width: 400,
              child: CatalogRadioGroup<CatalogDisplayLanguage>(
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
                  children: CatalogDisplayLanguage.values.expand((language) {
                    final theme = Theme.of(context);
                    final isSelected = selected == language;
                    return [
                      RadioListTile<CatalogDisplayLanguage>(
                        value: language,
                        title: Text(
                          language.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          ),
                        ),
                        secondary: Text(
                          language.code.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.5) : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        tileColor: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                        selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 12),
                    ];
                  }).toList()
                    ..removeLast(),
                ),
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

Future<void> showCreateKeyDialog(
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

Future<void> handleDone(
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

Future<void> confirmDeleteValue(
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

Future<void> confirmDeleteKey(
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

// ---------------------------------------------------------------------------
// Locale management dialogs
// ---------------------------------------------------------------------------

Future<void> showChangeDefaultLocaleDialog(
  BuildContext context,
  CatalogWorkspaceController controller,
) async {
  final meta = controller.meta;
  if (meta == null) {
    return;
  }
  final l10n = CatalogLocalizations.of(context);
  var selected = meta.fallbackLocale;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.selectDefaultLocale),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a locale to use as the default:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...meta.locales.map((locale) {
                    final isSelected = selected == locale;
                    return RadioListTile<String>(
                      value: locale,
                      groupValue: selected,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selected = value;
                          });
                        }
                      },
                      title: Text(
                        formatCatalogLocale(locale),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      tileColor: Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25),
                    );
                  }),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: selected == meta.fallbackLocale
                    ? null
                    : () async {
                        try {
                          await controller.setFallbackLocale(selected);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        }
                      },
                child: Text(l10n.confirm),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showDeleteLocaleDialog(
  BuildContext context,
  CatalogWorkspaceController controller,
  String locale,
) async {
  final l10n = CatalogLocalizations.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(l10n.confirmDeleteLocale(locale)),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.deleteLocale),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await controller.deleteLocale(locale);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}

Future<void> showAddLocaleDialog(
  BuildContext context,
  CatalogWorkspaceController controller,
) async {
  final meta = controller.meta;
  if (meta == null) {
    return;
  }
  final l10n = CatalogLocalizations.of(context);
  final textController = TextEditingController();
  final errorNotifier = ValueNotifier<String?>(null);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.addNewLocale),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: textController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.localeCodeHint,
                      hintText: 'fr',
                    ),
                    onChanged: (_) {
                      if (errorNotifier.value != null) {
                        errorNotifier.value = null;
                      }
                    },
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: errorNotifier,
                    builder: (context, error, _) {
                      if (error == null || error.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
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
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  final locale = textController.text.trim().replaceAll('-', '_');
                  if (locale.isEmpty) {
                    errorNotifier.value = l10n.invalidLocaleCode;
                    return;
                  }

                  // Validate locale code format
                  final localePattern = RegExp(r'^[a-zA-Z]{2,3}(?:_[a-zA-Z0-9]{2,8})*$');
                  if (!localePattern.hasMatch(locale)) {
                    errorNotifier.value = l10n.invalidLocaleCode;
                    return;
                  }

                  // Check if locale already exists
                  if (meta.locales.contains(locale)) {
                    errorNotifier.value = l10n.localeAlreadyExists(locale);
                    return;
                  }

                  try {
                    await controller.addLocale(locale);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  } catch (error) {
                    errorNotifier.value = error.toString();
                  }
                },
                child: Text(l10n.addNewLocale),
              ),
            ],
          );
        },
      );
    },
  );
}
