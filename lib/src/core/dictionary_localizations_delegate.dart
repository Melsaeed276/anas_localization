import 'package:flutter/widgets.dart';

import '../core/localization_service.dart';
import 'dictionary.dart';

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
  bool isSupported(Locale locale) => LocalizationService.allSupportedLocales.contains(locale.languageCode);

  @override
  Future<DictionaryLocalizations> load(Locale locale) async {
    // Use your existing logic to load and parse the correct dictionary for [locale].
    final _ = await LocalizationService().loadLocale(locale.languageCode);
    return DictionaryLocalizations(LocalizationService().currentDictionary);
  }

  @override
  bool shouldReload(DictionaryLocalizationsDelegate old) => false;
}
