import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/catalog_models.dart';
import '../../domain/entities/locale_validation_result.dart';
import '../../domain/services/catalog_flatten.dart';
import '../../domain/services/catalog_status_engine.dart';
import '../../domain/services/locale_validation_service.dart';
import '/src/shared/core/localization_exceptions.dart';
import '../controllers/catalog_ui_logic.dart';
import '../../l10n/generated/catalog_localizations.dart';
import 'catalog_error_dialogs.dart';
import 'catalog_preferences_controller.dart';
import 'catalog_ui_enums.dart';
import 'catalog_workspace_controllers.dart';
import 'catalog_shared_widgets.dart';

// ---------------------------------------------------------------------------
// Available locales for dropdown
// ---------------------------------------------------------------------------

class AvailableLocale {
  const AvailableLocale(this.code, this.name, this.direction);
  final String code;
  final String name;
  final String direction;
}

const List<AvailableLocale> kAvailableLocales = [
  // English variants
  AvailableLocale('en_US', 'English (US)', 'ltr'),
  AvailableLocale('en_GB', 'English (UK)', 'ltr'),
  AvailableLocale('en_AU', 'English (Australia)', 'ltr'),
  AvailableLocale('en_CA', 'English (Canada)', 'ltr'),
  AvailableLocale('en_NZ', 'English (New Zealand)', 'ltr'),
  AvailableLocale('en_IE', 'English (Ireland)', 'ltr'),
  AvailableLocale('en_SG', 'English (Singapore)', 'ltr'),
  AvailableLocale('en_ZA', 'English (South Africa)', 'ltr'),
  AvailableLocale('en_IN', 'English (India)', 'ltr'),
  // Arabic variants
  AvailableLocale('ar_SA', 'Arabic (Saudi Arabia)', 'rtl'),
  AvailableLocale('ar_EG', 'Arabic (Egypt)', 'rtl'),
  AvailableLocale('ar_LY', 'Arabic (Libya)', 'rtl'),
  AvailableLocale('ar_DZ', 'Arabic (Algeria)', 'rtl'),
  AvailableLocale('ar_MA', 'Arabic (Morocco)', 'rtl'),
  AvailableLocale('ar_IQ', 'Arabic (Iraq)', 'rtl'),
  AvailableLocale('ar_JO', 'Arabic (Jordan)', 'rtl'),
  AvailableLocale('ar_KW', 'Arabic (Kuwait)', 'rtl'),
  AvailableLocale('ar_QA', 'Arabic (Qatar)', 'rtl'),
  AvailableLocale('ar_BH', 'Arabic (Bahrain)', 'rtl'),
  AvailableLocale('ar_AE', 'Arabic (UAE)', 'rtl'),
  AvailableLocale('ar_SD', 'Arabic (Sudan)', 'rtl'),
  AvailableLocale('ar_TN', 'Arabic (Tunisia)', 'rtl'),
  AvailableLocale('ar_YE', 'Arabic (Yemen)', 'rtl'),
  AvailableLocale('ar_SY', 'Arabic (Syria)', 'rtl'),
  AvailableLocale('ar_PS', 'Arabic (Palestine)', 'rtl'),
  // European languages
  AvailableLocale('tr', 'Turkish', 'ltr'),
  AvailableLocale('es', 'Spanish', 'ltr'),
  AvailableLocale('es_MX', 'Spanish (Mexico)', 'ltr'),
  AvailableLocale('es_ES', 'Spanish (Spain)', 'ltr'),
  AvailableLocale('es_AR', 'Spanish (Argentina)', 'ltr'),
  AvailableLocale('es_CO', 'Spanish (Colombia)', 'ltr'),
  AvailableLocale('es_CL', 'Spanish (Chile)', 'ltr'),
  AvailableLocale('fr', 'French', 'ltr'),
  AvailableLocale('fr_CA', 'French (Canada)', 'ltr'),
  AvailableLocale('fr_BE', 'French (Belgium)', 'ltr'),
  AvailableLocale('fr_CH', 'French (Switzerland)', 'ltr'),
  AvailableLocale('de', 'German', 'ltr'),
  AvailableLocale('de_AT', 'German (Austria)', 'ltr'),
  AvailableLocale('de_CH', 'German (Switzerland)', 'ltr'),
  AvailableLocale('pt', 'Portuguese', 'ltr'),
  AvailableLocale('pt_BR', 'Portuguese (Brazil)', 'ltr'),
  AvailableLocale('it', 'Italian', 'ltr'),
  AvailableLocale('it_CH', 'Italian (Switzerland)', 'ltr'),
  AvailableLocale('nl', 'Dutch', 'ltr'),
  AvailableLocale('nl_BE', 'Dutch (Belgium)', 'ltr'),
  AvailableLocale('pl', 'Polish', 'ltr'),
  AvailableLocale('ru', 'Russian', 'ltr'),
  AvailableLocale('uk', 'Ukrainian', 'ltr'),
  AvailableLocale('cs', 'Czech', 'ltr'),
  AvailableLocale('sk', 'Slovak', 'ltr'),
  AvailableLocale('hu', 'Hungarian', 'ltr'),
  AvailableLocale('ro', 'Romanian', 'ltr'),
  AvailableLocale('bg', 'Bulgarian', 'ltr'),
  AvailableLocale('el', 'Greek', 'ltr'),
  AvailableLocale('sv', 'Swedish', 'ltr'),
  AvailableLocale('da', 'Danish', 'ltr'),
  AvailableLocale('no', 'Norwegian', 'ltr'),
  AvailableLocale('nb', 'Norwegian (Bokmål)', 'ltr'),
  AvailableLocale('nn', 'Norwegian (Nynorsk)', 'ltr'),
  AvailableLocale('fi', 'Finnish', 'ltr'),
  AvailableLocale('et', 'Estonian', 'ltr'),
  AvailableLocale('lv', 'Latvian', 'ltr'),
  AvailableLocale('lt', 'Lithuanian', 'ltr'),
  // Asian languages
  AvailableLocale('zh_CN', 'Chinese (Simplified)', 'ltr'),
  AvailableLocale('zh_TW', 'Chinese (Traditional)', 'ltr'),
  AvailableLocale('zh_HK', 'Chinese (Hong Kong)', 'ltr'),
  AvailableLocale('ja', 'Japanese', 'ltr'),
  AvailableLocale('ko', 'Korean', 'ltr'),
  AvailableLocale('vi', 'Vietnamese', 'ltr'),
  AvailableLocale('th', 'Thai', 'ltr'),
  AvailableLocale('id', 'Indonesian', 'ltr'),
  AvailableLocale('ms', 'Malay', 'ltr'),
  AvailableLocale('tl', 'Tagalog (Filipino)', 'ltr'),
  // South Asian languages
  AvailableLocale('hi', 'Hindi', 'ltr'),
  AvailableLocale('bn', 'Bengali', 'ltr'),
  AvailableLocale('mr', 'Marathi', 'ltr'),
  AvailableLocale('ta', 'Tamil', 'ltr'),
  AvailableLocale('te', 'Telugu', 'ltr'),
  AvailableLocale('gu', 'Gujarati', 'ltr'),
  AvailableLocale('kn', 'Kannada', 'ltr'),
  AvailableLocale('ml', 'Malayalam', 'ltr'),
  AvailableLocale('pa', 'Punjabi', 'ltr'),
  AvailableLocale('si', 'Sinhala', 'ltr'),
  AvailableLocale('ne', 'Nepali', 'ltr'),
  AvailableLocale('sd', 'Sindhi', 'rtl'),
  AvailableLocale('ur', 'Urdu', 'rtl'),
  // Middle Eastern languages
  AvailableLocale('he', 'Hebrew', 'rtl'),
  AvailableLocale('fa', 'Persian (Farsi)', 'rtl'),
  AvailableLocale('ps', 'Pashto', 'rtl'),
  AvailableLocale('ku', 'Kurdish', 'ltr'),
  AvailableLocale('yi', 'Yiddish', 'rtl'),
  // African languages
  AvailableLocale('sw', 'Swahili', 'ltr'),
  AvailableLocale('am', 'Amharic', 'ltr'),
  AvailableLocale('af', 'Afrikaans', 'ltr'),
  AvailableLocale('yo', 'Yoruba', 'ltr'),
  AvailableLocale('ig', 'Igbo', 'ltr'),
  AvailableLocale('zu', 'Zulu', 'ltr'),
  AvailableLocale('xh', 'Xhosa', 'ltr'),
  // Other languages
  AvailableLocale('ca', 'Catalan', 'ltr'),
  AvailableLocale('eu', 'Basque', 'ltr'),
  AvailableLocale('gl', 'Galician', 'ltr'),
  AvailableLocale('cy', 'Welsh', 'ltr'),
  AvailableLocale('ga', 'Irish', 'ltr'),
  AvailableLocale('is', 'Icelandic', 'ltr'),
  AvailableLocale('mt', 'Maltese', 'ltr'),
  AvailableLocale('lb', 'Luxembourgish', 'ltr'),
  AvailableLocale('mk', 'Macedonian', 'ltr'),
  AvailableLocale('sq', 'Albanian', 'ltr'),
  AvailableLocale('sr', 'Serbian', 'ltr'),
  AvailableLocale('hr', 'Croatian', 'ltr'),
  AvailableLocale('bs', 'Bosnian', 'ltr'),
  AvailableLocale('sl', 'Slovenian', 'ltr'),
  AvailableLocale('tr', 'Turkish', 'ltr'),
];

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
                      // ignore: deprecated_member_use
                      groupValue: selected,
                      // ignore: deprecated_member_use
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
                          await controller.setFallbackLocale(selected, context);
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

  if (confirmed == true && context.mounted) {
    try {
      await controller.deleteLocale(locale, context);
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
  final theme = Theme.of(context);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      // State declared outside StatefulBuilder so it persists across rebuilds.
      int selectedTabIndex = 0;
      final String searchQuery = '';
      AvailableLocale? selectedLocale;

      // T042: Custom locale state
      String customLocaleCode = '';
      String customLocaleDirection = 'ltr';
      LocaleValidationResult? customLocaleValidation;
      bool isValidatingCustomLocale = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return DefaultTabController(
            length: 2,
            child: AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.language,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.addNewLocale),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tab selector
                    TabBar(
                      onTap: (index) {
                        setState(() {
                          selectedTabIndex = index;
                        });
                      },
                      tabs: [
                        const Tab(text: 'Available Locales'),
                        const Tab(text: 'Custom Locale'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tab content
                    Expanded(
                      child: selectedTabIndex == 0
                          ? _buildAvailableLocalesTab(
                              context,
                              setState,
                              theme,
                              searchQuery,
                              selectedLocale,
                              (locale) {
                                selectedLocale = locale;
                              },
                              meta,
                            )
                          : _buildCustomLocaleTab(
                              context,
                              setState,
                              theme,
                              customLocaleCode,
                              (v) {
                                customLocaleCode = v;
                              },
                              customLocaleDirection,
                              (v) {
                                customLocaleDirection = v;
                              },
                              customLocaleValidation,
                              (v) {
                                customLocaleValidation = v;
                              },
                              isValidatingCustomLocale,
                              (v) {
                                isValidatingCustomLocale = v;
                              },
                              meta,
                            ),
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
                  onPressed: selectedTabIndex == 0
                      ? (selectedLocale == null
                          ? null
                          : () async {
                              await _handleAddPredefinedLocale(
                                dialogContext,
                                selectedLocale!,
                                controller,
                                l10n,
                              );
                            })
                      : ((customLocaleValidation?.isValid ?? false) && customLocaleCode.isNotEmpty
                          ? () async {
                              await _handleAddCustomLocale(
                                dialogContext,
                                customLocaleCode,
                                customLocaleDirection,
                                controller,
                                l10n,
                              );
                            }
                          : null),
                  child: Text(l10n.addNewLocale),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// T043-T046: Build custom locale tab
Widget _buildCustomLocaleTab(
  BuildContext context,
  StateSetter setState,
  ThemeData theme,
  String customLocaleCode,
  void Function(String) onCodeChanged,
  String customLocaleDirection,
  void Function(String) onDirectionChanged,
  LocaleValidationResult? customLocaleValidation,
  void Function(LocaleValidationResult?) onValidationChanged,
  bool isValidatingCustomLocale,
  void Function(bool) onValidatingChanged,
  CatalogMeta meta,
) {
  final validationService = const LocaleValidationService();

  return SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Locale code input
        TextField(
          decoration: InputDecoration(
            labelText: 'Locale Code',
            hintText: 'e.g., es_MX, fr_CA, de_AT',
            prefixIcon: const Icon(Icons.code),
            border: const OutlineInputBorder(),
            suffixIcon: isValidatingCustomLocale
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (customLocaleValidation != null
                    ? Icon(
                        customLocaleValidation.isValid ? Icons.check_circle : Icons.cancel,
                        color: customLocaleValidation.isValid ? Colors.green : Colors.red,
                      )
                    : null),
          ),
          onChanged: (value) {
            final trimmed = value.trim();
            setState(() {
              onCodeChanged(trimmed);
            });

            // T045: Debounced validation (300ms)
            if (trimmed.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (customLocaleCode == trimmed) {
                  setState(() {
                    onValidatingChanged(true);
                  });

                  // Validate against existing locales
                  final allLocales = meta.locales;
                  final normalized = trimmed.replaceAll('-', '_').toLowerCase();
                  final isDuplicate = allLocales.contains(normalized);

                  final result = validationService.validateLocaleCode(trimmed);

                  setState(() {
                    final effective = (isDuplicate && result.isValid)
                        ? const LocaleValidationResult(
                            isValid: false,
                            languageCode: null,
                            countryCode: null,
                            languageName: null,
                            countryName: null,
                            displayName: null,
                            errorMessage: 'Locale code already exists',
                            errorType: LocaleValidationErrorType.duplicateLocale,
                          )
                        : result;
                    onValidationChanged(effective);
                    onValidatingChanged(false);
                  });
                }
              });
            } else {
              setState(() {
                onValidationChanged(null);
              });
            }
          },
        ),
        const SizedBox(height: 16),

        // Direction selector
        Text(
          'Text Direction',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            const ButtonSegment(
              value: 'ltr',
              label: Text('LTR'),
              icon: Icon(Icons.format_align_left),
            ),
            const ButtonSegment(
              value: 'rtl',
              label: Text('RTL'),
              icon: Icon(Icons.format_align_right),
            ),
          ],
          selected: {customLocaleDirection},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              onDirectionChanged(newSelection.first);
            });
          },
        ),
        const SizedBox(height: 16),

        // T046: Validation feedback
        if (customLocaleCode.isNotEmpty) ...[
          if (customLocaleValidation != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: customLocaleValidation.isValid
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        customLocaleValidation.isValid ? Icons.check_circle : Icons.error,
                        color: customLocaleValidation.isValid
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          customLocaleValidation.isValid
                              ? 'Valid locale code'
                              : (customLocaleValidation.errorMessage ?? 'Invalid locale code'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: customLocaleValidation.isValid
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (customLocaleValidation.isValid && customLocaleValidation.displayName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Display name: ${customLocaleValidation.displayName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ],
    ),
  );
}

// Helper widget for available locales tab
Widget _buildAvailableLocalesTab(
  BuildContext context,
  StateSetter setState,
  ThemeData theme,
  String searchQuery,
  AvailableLocale? selectedLocale,
  void Function(AvailableLocale) onLocaleSelected,
  CatalogMeta meta,
) {
  // Filter locales based on search query
  final filteredLocales = searchQuery.isEmpty
      ? kAvailableLocales.where((locale) => !meta.locales.contains(locale.code)).toList()
      : kAvailableLocales.where((locale) {
          final query = searchQuery.toLowerCase();
          return !meta.locales.contains(locale.code) &&
              (locale.name.toLowerCase().contains(query) || locale.code.toLowerCase().contains(query));
        }).toList();

  final availableLocales = kAvailableLocales.where((locale) => !meta.locales.contains(locale.code)).toList();

  if (availableLocales.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'All locales added!',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Use the "Custom Locale" tab to add more.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Search field
      Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search languages...',
            prefixIcon: Icon(
              Icons.search,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
        ),
      ),
      const SizedBox(height: 12),
      // Results count
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${filteredLocales.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'locale${filteredLocales.length == 1 ? '' : 's'} available',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      // Locale list (scrollable)
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: filteredLocales.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No locales found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(4),
                  itemCount: filteredLocales.length,
                  itemBuilder: (context, index) {
                    final locale = filteredLocales[index];
                    final isSelected = selectedLocale?.code == locale.code;
                    return Card(
                      elevation: 0,
                      color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
                      margin: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 4,
                      ),
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: locale.direction == 'rtl'
                                ? theme.colorScheme.tertiaryContainer
                                : theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              locale.code.split('_').first.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: locale.direction == 'rtl'
                                    ? theme.colorScheme.onTertiaryContainer
                                    : theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          locale.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              locale.code,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (locale.direction == 'rtl') ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'RTL',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            onLocaleSelected(locale);
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    ],
  );
}

// T047: Handle adding predefined locale
Future<void> _handleAddPredefinedLocale(
  BuildContext dialogContext,
  AvailableLocale selectedLocale,
  CatalogWorkspaceController controller,
  CatalogLocalizations l10n,
) async {
  try {
    if (dialogContext.mounted) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text('Adding ${selectedLocale.name}...'),
            ],
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    }

    await controller.addLocale(
      selectedLocale.code,
      selectedLocale.direction,
      dialogContext,
    );

    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text('${selectedLocale.name} added!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (error) {
    if (dialogContext.mounted) {
      ScaffoldMessenger.of(dialogContext).hideCurrentSnackBar();
      await CatalogErrorDialog.show(
        dialogContext,
        title: 'Failed to Add Locale',
        message: error.toString(),
        operation: 'ADD_LOCALE',
      );
    }
  }
}

// T047: Handle adding custom locale
Future<void> _handleAddCustomLocale(
  BuildContext dialogContext,
  String localeCode,
  String direction,
  CatalogWorkspaceController controller,
  CatalogLocalizations l10n,
) async {
  try {
    if (dialogContext.mounted) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text('Adding custom locale $localeCode...'),
            ],
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    }

    await controller.addCustomLocale(localeCode, direction);

    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text('Custom locale $localeCode added!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (error) {
    if (dialogContext.mounted) {
      ScaffoldMessenger.of(dialogContext).hideCurrentSnackBar();
      await CatalogErrorDialog.show(
        dialogContext,
        title: 'Failed to Add Custom Locale',
        message: error.toString(),
        operation: 'ADD_CUSTOM_LOCALE',
      );
    }
  }
}
