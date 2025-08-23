import 'package:anas_localization/localization.dart';
import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AnasLocalization.of(context);

    return Row(
      children: [
        const Text('Language:'),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: localization.locale.languageCode,
          onChanged: (newCode) {
            if (newCode != null) {
              localization.setLocale(Locale(newCode));
            }
          },
          items: LocalizationService.allSupportedLocales.map((code) {
            return DropdownMenuItem(
              value: code,
              child: Text(code.toUpperCase()),
            );
          }).toList(),
        ),
      ],
    );
  }
}
