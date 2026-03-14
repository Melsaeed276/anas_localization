import 'package:flutter/widgets.dart';

import '../../data/repositories/localization_service.dart';
import '../../domain/entities/dictionary.dart';

class DictionaryLocalizations {
  DictionaryLocalizations(this.dictionary);

  final Dictionary dictionary;

  static DictionaryLocalizations? of(BuildContext context) {
    return Localizations.of<DictionaryLocalizations>(context, DictionaryLocalizations);
  }
}

class DictionaryLocalizationsDelegate extends LocalizationsDelegate<DictionaryLocalizations> {
  const DictionaryLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => LocalizationService.isLocaleSupported(LocalizationService.localeToCode(locale));

  @override
  Future<DictionaryLocalizations> load(Locale locale) async {
    // Load the dictionary for the full locale code (e.g. zh_Hant_TW) without
    // touching the singleton's current dictionary, avoiding a race condition
    // when multiple locales are resolved concurrently.
    final dictionary = await LocalizationService().loadDictionaryForLocale(
      LocalizationService.localeToCode(locale),
    );
    return DictionaryLocalizations(dictionary);
  }

  @override
  bool shouldReload(DictionaryLocalizationsDelegate old) => false;
}
