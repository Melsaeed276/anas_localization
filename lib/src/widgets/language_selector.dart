/// Pre-built widgets for language switching
library;

import 'package:flutter/material.dart';
import '../anas_localization.dart';
import 'language_setup_overlay.dart';

/// A pre-built language selector dropdown widget
class AnasLanguageSelector extends StatelessWidget {
  const AnasLanguageSelector({
    super.key,
    this.supportedLocales,
    this.onLocaleChanged,
    this.decoration,
    this.style,
  });

  final List<Locale>? supportedLocales;
  final ValueChanged<Locale>? onLocaleChanged;
  final InputDecoration? decoration;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final currentLocale = AnasLocalization.of(context).locale;
    final locales = supportedLocales ?? [
      const Locale('en'),
      const Locale('ar'),
      const Locale('tr'),
    ];

    return DropdownButtonFormField<Locale>(
      initialValue: currentLocale,
      decoration: decoration ?? const InputDecoration(
        labelText: 'Language',
        border: OutlineInputBorder(),
      ),
      style: style,
      items: locales.map((locale) {
        return DropdownMenuItem(
          value: locale,
          child: Text(_getLocalizedLanguageName(context, locale.languageCode)),
        );
      }).toList(),
      onChanged: (Locale? newLocale) async {
        if (newLocale != null && newLocale != currentLocale) {
          // Try to use the setup overlay first, fall back to direct setLocale if not available
          if (!AnasLanguageSetup.tryChangeLanguage(newLocale)) {
            // Fallback to direct setLocale when setup overlay is not available
            await AnasLocalization.of(context).setLocale(newLocale);
          }
          onLocaleChanged?.call(newLocale);
        }
      },
    );
  }

  String _getLocalizedLanguageName(BuildContext context, String languageCode) {
    final dictionary = AnasLocalization.of(context).dictionary;
    final supportedLanguages = dictionary.toMap()['supported_languages'] as Map<String, dynamic>?;
    if (supportedLanguages != null && supportedLanguages.containsKey(languageCode)) {
      return supportedLanguages[languageCode] as String;
    }
    return languageCode.toUpperCase();
  }
}

/// A simple language toggle button (for apps with 2 languages)
class AnasLanguageToggle extends StatelessWidget {
  const AnasLanguageToggle({
    super.key,
    required this.primaryLocale,
    required this.secondaryLocale,
    this.onLocaleChanged,
  });

  final Locale primaryLocale;
  final Locale secondaryLocale;
  final ValueChanged<Locale>? onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final currentLocale = AnasLocalization.of(context).locale;
    final isCurrentPrimary = currentLocale.languageCode == primaryLocale.languageCode;

    return IconButton(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isCurrentPrimary
                ? primaryLocale.languageCode.toUpperCase()
                : secondaryLocale.languageCode.toUpperCase(),
          ),
          const Icon(Icons.swap_horiz),
        ],
      ),
      onPressed: () async {
        final newLocale = isCurrentPrimary ? secondaryLocale : primaryLocale;
        // Try to use the setup overlay first, fall back to direct setLocale if not available
        if (!AnasLanguageSetup.tryChangeLanguage(newLocale)) {
          // Fallback to direct setLocale when setup overlay is not available
          await AnasLocalization.of(context).setLocale(newLocale);
        }
        onLocaleChanged?.call(newLocale);
      },
    );
  }
}

/// A language selector that opens as a dialog with confirmation
class AnasLanguageDialog extends StatelessWidget {
  const AnasLanguageDialog({
    super.key,
    this.supportedLocales,
    this.onLocaleChanged,
    this.showDescription = false,
  });

  final List<Locale>? supportedLocales;
  final ValueChanged<Locale>? onLocaleChanged;
  final bool showDescription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDescription) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  AnasLocalization.of(context).dictionary.getString('dialog_language_description'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showLanguageDialog(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primaryContainer,
                        ),
                        child: Center(
                          child: Text(
                            _getFlagFromJson(context),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getLocalizedLanguageName(context, AnasLocalization.of(context).locale.languageCode),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLocale = AnasLocalization.of(context).locale;
    final locales = supportedLocales ?? AnasLocalization.of(context).supportedLocales;
    final dict = AnasLocalization.of(context).dictionary;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog<Locale>(
      context: context,
      builder: (BuildContext dialogContext) {
        Locale? selectedLocale = currentLocale;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 312,
                  minWidth: 280,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          dict.getString('select_language'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),

                    // Language options
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: SingleChildScrollView(
                          child: Column(
                            children: locales.map((locale) {
                              final isSelected = selectedLocale == locale;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                    ? colorScheme.secondaryContainer.withValues(alpha: 0.3)
                                    : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Material(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.surfaceContainerHigh,
                                  //Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setState(() {
                                        selectedLocale = locale;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _getLocalizedLanguageName(context, locale.languageCode),
                                              style: theme.textTheme.bodyLarge?.copyWith(
                                                color: isSelected
                                                  ? colorScheme.onPrimary
                                                  : colorScheme.onSurface,
                                                fontWeight: isSelected
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

                    // Actions
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            onPressed: selectedLocale != null && selectedLocale != currentLocale
                                ? () async {
                                    final localeToSet = selectedLocale ?? currentLocale;
                                    // Try to use the setup overlay first, fall back to direct setLocale if not available
                                    if (!AnasLanguageSetup.tryChangeLanguage(localeToSet)) {
                                      // Fallback to direct setLocale when setup overlay is not available
                                      await AnasLocalization.of(context).setLocale(localeToSet);
                                    }
                                    onLocaleChanged?.call(localeToSet);
                                    if (dialogContext.mounted) {
                                      Navigator.of(dialogContext).pop();
                                    }
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              minimumSize: const Size(double.infinity, 40),
                            ),
                            child: Text(dict.getString('confirm')),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.error,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                minimumSize: const Size(double.infinity, 40),
                              ),
                              child: Text(dict.getString('cancel')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getFlagFromJson(BuildContext context) {
    final dictionary = AnasLocalization.of(context).dictionary;
    final flag = dictionary.getString('language_flag');
    return flag.isNotEmpty ? flag : '🌐';
  }

  String _getLocalizedLanguageName(BuildContext context, String languageCode) {
    final dictionary = AnasLocalization.of(context).dictionary;
    final supportedLanguages = dictionary.toMap()['supported_languages'] as Map<String, dynamic>?;
    if (supportedLanguages != null && supportedLanguages.containsKey(languageCode)) {
      return supportedLanguages[languageCode] as String;
    }
    return languageCode.toUpperCase();
  }
}
