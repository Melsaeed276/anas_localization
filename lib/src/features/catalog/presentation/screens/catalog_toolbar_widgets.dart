import 'package:flutter/material.dart';

import '../../l10n/l10n/generated/catalog_localizations.dart';
import 'catalog_preferences_controller.dart';
import 'catalog_label_helpers.dart';

// ---------------------------------------------------------------------------
// ThemeMenu — popup menu to pick CatalogThemeMode
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// CatalogSettingsSideSheet — left drawer for global preferences
// ---------------------------------------------------------------------------

class CatalogSettingsSideSheet extends StatelessWidget {
  const CatalogSettingsSideSheet({
    super.key,
    required this.preferencesController,
  });

  final CatalogPreferencesController preferencesController;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final theme = Theme.of(context);

    // M3 Side Sheet container
    return Material(
      color: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      elevation: 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.only(
          topEnd: Radius.circular(16),
          bottomEnd: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.overviewSection,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.backLabel,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: <Widget>[
                  _SettingsHeader(title: l10n.themeLabel),
                  ThemeListTile(preferencesController: preferencesController),
                  const SizedBox(height: 16),
                  _SettingsHeader(title: l10n.catalogLanguage),
                  LanguageListTile(preferencesController: preferencesController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class ThemeListTile extends StatelessWidget {
  const ThemeListTile({super.key, required this.preferencesController});
  final CatalogPreferencesController preferencesController;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: CatalogThemeMode.values.map((mode) {
          final isSelected = preferencesController.themeMode == mode;
          final icon = switch (mode) {
            CatalogThemeMode.system => Icons.brightness_auto_outlined,
            CatalogThemeMode.light => Icons.light_mode_outlined,
            CatalogThemeMode.dark => Icons.dark_mode_outlined,
          };
          final label = switch (mode) {
            CatalogThemeMode.system => l10n.themeSystem,
            CatalogThemeMode.light => l10n.themeLight,
            CatalogThemeMode.dark => l10n.themeDark,
          };

          return ListTile(
            leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
            title: Text(label),
            trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () => preferencesController.setThemeMode(mode),
            selected: isSelected,
          );
        }).toList(),
      ),
    );
  }
}

class LanguageListTile extends StatelessWidget {
  const LanguageListTile({super.key, required this.preferencesController});
  final CatalogPreferencesController preferencesController;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        leading: const Icon(Icons.translate),
        title: Text(preferencesController.displayLanguage.label),
        subtitle: Text(l10n.catalogLanguage),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => showDisplayLanguageDialog(context, preferencesController),
      ),
    );
  }
}

/// Shows a Material 3 Modal Side Sheet.
Future<T?> showModalSideSheet<T>({
  required BuildContext context,
  required Widget child,
  String? barrierLabel,
  bool barrierDismissible = true,
  AlignmentDirectional alignment = AlignmentDirectional.centerStart,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final isCompact = width < 600;
  final sheetWidth = isCompact ? width : width.clamp(320.0, 420.0).toDouble();
  final isLeft = alignment.resolve(Directionality.of(context)) == Alignment.centerLeft;

  return showGeneralDialog<T>(
    context: context,
    barrierLabel: barrierLabel ?? 'Side Sheet',
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: alignment,
        child: SizedBox(
          width: sheetWidth,
          height: double.infinity,
          child: child,
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(isLeft ? -1.0 : 1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
  );
}
