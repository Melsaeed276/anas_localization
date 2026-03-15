import 'package:flutter/material.dart';

import '../../l10n/l10n/generated/catalog_localizations.dart';
import 'catalog_preferences_controller.dart';
import 'catalog_label_helpers.dart';

// ---------------------------------------------------------------------------
// ThemeMenu — popup menu to pick CatalogThemeMode
// ---------------------------------------------------------------------------

class ThemeMenu extends StatelessWidget {
  const ThemeMenu({
    super.key,
    required this.preferencesController,
    this.compact = false,
  });

  final CatalogPreferencesController preferencesController;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    return PopupMenuButton<CatalogThemeMode>(
      tooltip: l10n.themeLabel,
      icon: compact ? const Icon(Icons.palette_outlined) : null,
      initialValue: preferencesController.themeMode,
      onSelected: (value) {
        preferencesController.setThemeMode(value);
      },
      itemBuilder: (context) => <PopupMenuEntry<CatalogThemeMode>>[
        PopupMenuItem(
          value: CatalogThemeMode.system,
          child: Text(l10n.themeSystem),
        ),
        PopupMenuItem(
          value: CatalogThemeMode.light,
          child: Text(l10n.themeLight),
        ),
        PopupMenuItem(
          value: CatalogThemeMode.dark,
          child: Text(l10n.themeDark),
        ),
      ],
      child: compact
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  '${l10n.themeLabel}: ${switch (preferencesController.themeMode) {
                    CatalogThemeMode.system => l10n.themeSystem,
                    CatalogThemeMode.light => l10n.themeLight,
                    CatalogThemeMode.dark => l10n.themeDark,
                  }}',
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// DisplayLanguageButton — button / icon-button to open display-language dialog
// ---------------------------------------------------------------------------

class DisplayLanguageButton extends StatelessWidget {
  const DisplayLanguageButton({
    super.key,
    required this.preferencesController,
    this.compact = false,
  });

  final CatalogPreferencesController preferencesController;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    if (compact) {
      return IconButton(
        tooltip: '${l10n.catalogLanguage}: ${preferencesController.displayLanguage.code.toUpperCase()}',
        onPressed: () => showDisplayLanguageDialog(context, preferencesController),
        icon: const Icon(Icons.language),
      );
    }
    return TextButton(
      onPressed: () => showDisplayLanguageDialog(context, preferencesController),
      child: Text('${l10n.catalogLanguage}: ${preferencesController.displayLanguage.code.toUpperCase()}'),
    );
  }
}
