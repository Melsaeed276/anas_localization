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
    final meta = controller.meta;
    if (meta == null) return const SizedBox.shrink();
    final sourceLocale = meta.sourceLocale;
    final l10n = CatalogLocalizations.of(context);
    final localeDirection = controller.localeDirection(locale) == 'rtl' ? TextDirection.rtl : TextDirection.ltr;

    switch (draft.editorMode) {
      case CatalogEditorMode.gender:
        final genderRequiredKeys = normalizedGenderKeys(row.valuesByLocale[sourceLocale]).toSet();
        return Column(
          children: <Widget>[
            ...normalizedGenderKeys(draft.value).map(
              (key) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BranchEditorCard(
                  label: key,
                  sourceValue: readCatalogPath(row.valuesByLocale[sourceLocale], <String>[key]),
                  localeDirection: localeDirection,
                  sourceDirection:
                      controller.localeDirection(sourceLocale) == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
                  onRemove: genderRequiredKeys.contains(key)
                      ? null
                      : () => controller.removeBranch(row: row, locale: locale, path: <String>[key]),
                  child: EditorTextField(
                    key: ValueKey<String>('branch-${row.keyPath}-$locale-$key'),
                    initialValue: (readCatalogPath(draft.value, <String>[key]) ?? '').toString(),
                    textDirection: localeDirection,
                    labelText: l10n.translationLabel,
                    sourceValue: readCatalogPath(row.valuesByLocale[sourceLocale], <String>[key])?.toString(),
                    placeholders: collectCatalogPlaceholders(
                      readCatalogPath(row.valuesByLocale[sourceLocale], <String>[key]),
                    ).toList()
                      ..sort(),
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
              labels: availableGenderCandidates(draft.value, row.valuesByLocale[sourceLocale]),
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
        final pluralRequiredKeys = normalizedPluralKeys(row.valuesByLocale[sourceLocale]).toSet();
        return Column(
          children: <Widget>[
            ...normalizedPluralKeys(draft.value).map(
              (key) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BranchEditorCard(
                  label: key,
                  sourceValue: readCatalogPath(row.valuesByLocale[sourceLocale], <String>[key]),
                  localeDirection: localeDirection,
                  sourceDirection:
                      controller.localeDirection(sourceLocale) == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
                  onRemove: pluralRequiredKeys.contains(key)
                      ? null
                      : () => controller.removeBranch(row: row, locale: locale, path: <String>[key]),
                  child: EditorTextField(
                    key: ValueKey<String>('branch-${row.keyPath}-$locale-$key'),
                    initialValue: (readCatalogPath(draft.value, <String>[key]) ?? '').toString(),
                    textDirection: localeDirection,
                    labelText: l10n.translationLabel,
                    sourceValue: readCatalogPath(row.valuesByLocale[sourceLocale], <String>[key])?.toString(),
                    placeholders: collectCatalogPlaceholders(
                      readCatalogPath(row.valuesByLocale[sourceLocale], <String>[key]),
                    ).toList()
                      ..sort(),
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
              labels: availablePluralCandidates(draft.value, row.valuesByLocale[sourceLocale]),
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
        final pgSourceDirection =
            controller.localeDirection(sourceLocale) == 'rtl' ? TextDirection.rtl : TextDirection.ltr;
        final pgRequiredPluralKeys = normalizedPluralKeys(row.valuesByLocale[sourceLocale]).toSet();
        return Column(
          children: <Widget>[
            ...normalizedPluralKeys(draft.value).map(
              (pluralKey) {
                final pgRequiredGenderKeys = normalizedGenderKeys(
                  readCatalogPath(row.valuesByLocale[sourceLocale], <String>[pluralKey]),
                ).toSet();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  pluralKey,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (!pgRequiredPluralKeys.contains(pluralKey))
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  tooltip: 'Remove',
                                  onPressed: () => controller.removeBranch(
                                    row: row,
                                    locale: locale,
                                    path: <String>[pluralKey],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...normalizedGenderKeys((draft.value as Map)[pluralKey]).map(
                            (genderKey) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: BranchEditorCard(
                                label: genderKey,
                                sourceValue: readCatalogPath(
                                  row.valuesByLocale[sourceLocale],
                                  <String>[pluralKey, genderKey],
                                ),
                                localeDirection: localeDirection,
                                sourceDirection: pgSourceDirection,
                                onRemove: pgRequiredGenderKeys.contains(genderKey)
                                    ? null
                                    : () => controller.removeBranch(
                                          row: row,
                                          locale: locale,
                                          path: <String>[pluralKey, genderKey],
                                        ),
                                child: EditorTextField(
                                  key: ValueKey<String>('branch-${row.keyPath}-$locale-$pluralKey-$genderKey'),
                                  initialValue:
                                      (readCatalogPath(draft.value, <String>[pluralKey, genderKey]) ?? '').toString(),
                                  textDirection: localeDirection,
                                  labelText: l10n.translationLabel,
                                  sourceValue: readCatalogPath(
                                    row.valuesByLocale[sourceLocale],
                                    <String>[pluralKey, genderKey],
                                  )?.toString(),
                                  placeholders: collectCatalogPlaceholders(
                                    readCatalogPath(
                                      row.valuesByLocale[sourceLocale],
                                      <String>[pluralKey, genderKey],
                                    ),
                                  ).toList()
                                    ..sort(),
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
                              readCatalogPath(row.valuesByLocale[sourceLocale], <String>[pluralKey]),
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
                );
              },
            ),
            AddBranchRow(
              labels: availablePluralCandidates(draft.value, row.valuesByLocale[sourceLocale]),
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
            EditorTextField(
              key: ValueKey<String>('plain-${row.keyPath}-$locale'),
              initialValue: (draft.value ?? '').toString(),
              textDirection: localeDirection,
              labelText: l10n.translationLabel,
              sourceValue: row.valuesByLocale[sourceLocale]?.toString(),
              placeholders: collectCatalogPlaceholders(
                row.valuesByLocale[sourceLocale],
              ).toList()
                ..sort(),
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
    this.onRemove,
  });

  final String label;
  final dynamic sourceValue;
  final TextDirection localeDirection;
  final TextDirection sourceDirection;
  final Widget child;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child:
                      Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remove',
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemove,
                  ),
              ],
            ),
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

// ---------------------------------------------------------------------------
// EditorTextField — custom text field with glowing focus and inline actions
// ---------------------------------------------------------------------------

class EditorTextField extends StatefulWidget {
  const EditorTextField({
    super.key,
    required this.initialValue,
    required this.labelText,
    required this.textDirection,
    required this.onChanged,
    required this.onTapOutside,
    this.sourceValue,
    this.placeholders = const <String>[],
  });

  final String initialValue;
  final String labelText;
  final TextDirection textDirection;
  final ValueChanged<String> onChanged;
  final TapRegionCallback onTapOutside;
  final String? sourceValue;
  final List<String> placeholders;

  @override
  State<EditorTextField> createState() => _EditorTextFieldState();
}

class _EditorTextFieldState extends State<EditorTextField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void didUpdateWidget(covariant EditorTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _copyFromSource() {
    if (widget.sourceValue != null) {
      _controller.text = widget.sourceValue!;
      widget.onChanged(widget.sourceValue!);
    }
  }

  void _insertPlaceholder(String name) {
    final placeholder = '{$name}';
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final newText = text.replaceRange(start, end, placeholder);

    // If name is empty, place cursor inside brackets. Otherwise place after.
    final offset = name.isEmpty ? start + 1 : start + placeholder.length;

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: offset),
    );
    widget.onChanged(newText);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color:
            _isFocused ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.labelText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          _controller.clear();
                          widget.onChanged('');
                        },
                        icon: Icon(Icons.clear, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    if (widget.sourceValue != null)
                      Tooltip(
                        message: CatalogLocalizations.of(context).sourceLabel,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: _copyFromSource,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.content_copy, size: 14, color: theme.colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    CatalogLocalizations.of(context).sourceLabel,
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  avatar: Icon(
                    Icons.add_box_outlined,
                    size: 14,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  label: Text(
                    '{}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  tooltip: CatalogLocalizations.of(context).addBranchLabel, // Reusing localized label "Add"
                  onPressed: () => _insertPlaceholder(''),
                ),
                ...widget.placeholders.map((name) {
                  return ActionChip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      Icons.data_object_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      '{$name}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _insertPlaceholder(name),
                  );
                }),
              ],
            ),
          ),
          TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            minLines: 2,
            textDirection: widget.textDirection,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            ),
            onChanged: widget.onChanged,
            onTapOutside: widget.onTapOutside,
          ),
        ],
      ),
    );
  }
}
