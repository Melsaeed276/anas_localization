import 'package:flutter/material.dart';
import 'package:anas_localization/anas_localization.dart';
import 'package:provider/provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocalizationProvider>();
    final current = provider.locale;

    return Row(
      children: [
        const Text('Language:'),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: current,
          onChanged: (newCode) {
            if (newCode != null) {
              provider.loadLocale(newCode);
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