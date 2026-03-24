import 'package:flutter/material.dart';

import '../../l10n/generated/catalog_localizations.dart';
import 'catalog_preferences_controller.dart';
import 'catalog_label_helpers.dart';
import 'catalog_workspace_controllers.dart';

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
    required this.workspaceController,
  });

  final CatalogPreferencesController preferencesController;
  final CatalogWorkspaceController workspaceController;

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
                  const SizedBox(height: 16),
                  _SettingsHeader(title: l10n.projectLocales),
                  ProjectLocalesSection(workspaceController: workspaceController),
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
  final locale = Localizations.localeOf(context);

  return showGeneralDialog<T>(
    context: context,
    barrierLabel: barrierLabel ?? 'Side Sheet',
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Localizations(
        locale: locale,
        delegates: CatalogLocalizations.localizationsDelegates,
        child: Directionality(
          textDirection: Directionality.of(context),
          child: Align(
            alignment: alignment,
            child: SizedBox(
              width: sheetWidth,
              height: double.infinity,
              child: child,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(isLeft ? -1.0 : 1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: child,
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Project Locales Section
// ---------------------------------------------------------------------------

class ProjectLocalesSection extends StatelessWidget {
  const ProjectLocalesSection({
    super.key,
    required this.workspaceController,
  });

  final CatalogWorkspaceController workspaceController;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final meta = workspaceController.meta;
    if (meta == null) {
      return const SizedBox.shrink();
    }

    // Sort locales with fallback first, then others alphabetically
    final sortedLocales = List<String>.from(meta.locales)
      ..sort((a, b) {
        if (a == meta.fallbackLocale) return -1;
        if (b == meta.fallbackLocale) return 1;
        return a.compareTo(b);
      });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          ...sortedLocales.map((locale) {
            final isDefault = locale == meta.fallbackLocale;
            return LocaleListTile(
              locale: locale,
              isDefault: isDefault,
              workspaceController: workspaceController,
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showAddLocaleDialog(context, workspaceController),
              icon: const Icon(Icons.add),
              label: Text(l10n.addNewLocale),
            ),
          ),
        ],
      ),
    );
  }
}

class LocaleListTile extends StatelessWidget {
  const LocaleListTile({
    super.key,
    required this.locale,
    required this.isDefault,
    required this.workspaceController,
  });

  final String locale;
  final bool isDefault;
  final CatalogWorkspaceController workspaceController;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDefault ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            locale.split('_').first.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: isDefault ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          formatCatalogLocale(locale),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isDefault ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: isDefault
            ? Text(
                l10n.defaultLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDefault)
              TextButton(
                onPressed: () => showChangeDefaultLocaleDialog(context, workspaceController),
                child: Text(l10n.changeDefaultLocale),
              )
            else
              IconButton(
                onPressed: () => showDeleteLocaleDialog(context, workspaceController, locale),
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                tooltip: l10n.deleteLocale,
              ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

String formatCatalogLocale(String locale) {
  // Convert locale codes to readable format
  // e.g., "en_US" -> "English (US)", "fr" -> "French"
  final parts = locale.split('_');
  final languageCode = parts.first;

  // Map common language codes to names
  final languageNames = <String, String>{
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

  final languageName = languageNames[languageCode] ?? languageCode.toUpperCase();

  if (parts.length > 1) {
    // Handle region codes
    final regionCode = parts.last;
    final regionNames = <String, String>{
      'US': 'United States',
      'GB': 'United Kingdom',
      'CA': 'Canada',
      'AU': 'Australia',
      'IN': 'India',
      'BR': 'Brazil',
      'MX': 'Mexico',
      'ES': 'Spain',
      'FR': 'France',
      'DE': 'Germany',
      'CN': 'China',
      'TW': 'Taiwan',
      'HK': 'Hong Kong',
    };
    final regionName = regionNames[regionCode] ?? regionCode;
    return '$languageName ($regionName)';
  }

  return languageName;
}
