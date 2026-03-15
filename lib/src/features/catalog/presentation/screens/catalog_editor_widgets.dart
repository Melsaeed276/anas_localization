import 'package:flutter/material.dart';

import '../../domain/entities/catalog_models.dart';
import '../controllers/catalog_ui_logic.dart';
import '../../l10n/l10n/generated/catalog_localizations.dart';
import 'catalog_workspace_controllers.dart';

// ---------------------------------------------------------------------------
// ValueEditor — top-level editor switcher (plain / plural / gender / raw)
// ---------------------------------------------------------------------------

class ValueEditor extends StatelessWidget {
  const ValueEditor({
    super.key,
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
                child: BranchEditorCard(
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
            AddBranchRow(
              labels: availableGenderCandidates(draft.value, row.valuesByLocale[controller.meta!.sourceLocale]),
              onTap: (value) => controller.addGenderBranch(
                row: row,
                locale: locale,
                category: null,
                gender: value,
              ),
            ),
            AdvancedJsonEditor(
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
                child: BranchEditorCard(
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
            AddBranchRow(
              labels: availablePluralCandidates(draft.value, row.valuesByLocale[controller.meta!.sourceLocale]),
              onTap: (value) => controller.addPluralBranch(
                row: row,
                locale: locale,
                category: value,
              ),
            ),
            AdvancedJsonEditor(
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
                            child: BranchEditorCard(
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
                        AddBranchRow(
                          labels: availableGenderCandidates(
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
            AddBranchRow(
              labels: availablePluralCandidates(draft.value, row.valuesByLocale[controller.meta!.sourceLocale]),
              onTap: (value) => controller.addPluralBranch(
                row: row,
                locale: locale,
                category: value,
              ),
            ),
            AdvancedJsonEditor(
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
            AdvancedJsonEditor(
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
            AdvancedJsonEditor(
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

// ---------------------------------------------------------------------------
// AdvancedJsonEditor — collapsible raw JSON editor
// ---------------------------------------------------------------------------

class AdvancedJsonEditor extends StatelessWidget {
  const AdvancedJsonEditor({
    super.key,
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

// ---------------------------------------------------------------------------
// SourcePreview — read-only selectable preview for a locale value
// ---------------------------------------------------------------------------

class SourcePreview extends StatelessWidget {
  const SourcePreview({
    super.key,
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

// ---------------------------------------------------------------------------
// BranchEditorCard — card wrapping a single plural/gender branch field
// ---------------------------------------------------------------------------

class BranchEditorCard extends StatelessWidget {
  const BranchEditorCard({
    super.key,
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

// ---------------------------------------------------------------------------
// AddBranchRow — row of "Add branch: <label>" buttons
// ---------------------------------------------------------------------------

class AddBranchRow extends StatelessWidget {
  const AddBranchRow({
    super.key,
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

// ---------------------------------------------------------------------------
// Candidate helpers (pure functions)
// ---------------------------------------------------------------------------

List<String> availablePluralCandidates(dynamic value, dynamic sourceValue) {
  final existing = normalizedPluralKeys(value).toSet();
  final sourceKeys = normalizedPluralKeys(sourceValue);
  return <String>{...catalogPluralKeys, ...sourceKeys}.where((key) => !existing.contains(key)).toList();
}

List<String> availableGenderCandidates(dynamic value, dynamic sourceValue) {
  final existing = normalizedGenderKeys(value).toSet();
  final sourceKeys = normalizedGenderKeys(sourceValue);
  return <String>{...catalogGenderKeys, ...sourceKeys}.where((key) => !existing.contains(key)).toList();
}
