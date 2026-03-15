library;

import '../entities/dictionary.dart';

abstract class LocalizationRepository {
  Future<void> loadLocale(String localeCode, {List<String>? preferredLocales});

  Future<Dictionary> loadDictionaryForLocale(String localeCode);

  Dictionary get currentDictionary;

  String? get currentLocale;
}
