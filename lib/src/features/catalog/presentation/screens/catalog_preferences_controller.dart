import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../../../../core/key_value_storage.dart';

// ---------------------------------------------------------------------------
// Storage keys
// ---------------------------------------------------------------------------

const String _catalogThemeModeStorageKey = 'anasCatalog.themeMode';
const String _catalogDisplayLanguageStorageKey = 'anasCatalog.displayLanguage';

// ---------------------------------------------------------------------------
// CatalogThemeMode
// ---------------------------------------------------------------------------

enum CatalogThemeMode {
  system,
  light,
  dark,
}

extension CatalogThemeModeExtension on CatalogThemeMode {
  ThemeMode get flutterThemeMode => switch (this) {
        CatalogThemeMode.system => ThemeMode.system,
        CatalogThemeMode.light => ThemeMode.light,
        CatalogThemeMode.dark => ThemeMode.dark,
      };

  String get storageValue => switch (this) {
        CatalogThemeMode.system => 'system',
        CatalogThemeMode.light => 'light',
        CatalogThemeMode.dark => 'dark',
      };
}

// ---------------------------------------------------------------------------
// CatalogDisplayLanguage
// ---------------------------------------------------------------------------

enum CatalogDisplayLanguage {
  en('en', Locale('en')),
  ar('ar', Locale('ar')),
  tr('tr', Locale('tr')),
  es('es', Locale('es')),
  hi('hi', Locale('hi')),
  zhCn('zh-CN', Locale('zh', 'CN'));

  const CatalogDisplayLanguage(this.code, this.locale);

  final String code;
  final Locale locale;

  static CatalogDisplayLanguage fromCode(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized == 'zh-cn' || normalized == 'zh_cn' || normalized == 'zh') {
      return CatalogDisplayLanguage.zhCn;
    }
    for (final language in values) {
      if (normalized == language.code.toLowerCase()) {
        return language;
      }
    }
    return CatalogDisplayLanguage.en;
  }
}

extension CatalogDisplayLanguageExtension on CatalogDisplayLanguage {
  String get label => switch (this) {
        CatalogDisplayLanguage.en => 'English',
        CatalogDisplayLanguage.ar => 'العربية',
        CatalogDisplayLanguage.tr => 'Türkçe',
        CatalogDisplayLanguage.es => 'Español',
        CatalogDisplayLanguage.hi => 'हिन्दी',
        CatalogDisplayLanguage.zhCn => '简体中文',
      };
}

// ---------------------------------------------------------------------------
// CatalogPreferencesController
// ---------------------------------------------------------------------------

class CatalogPreferencesController extends ChangeNotifier {
  CatalogThemeMode _themeMode = CatalogThemeMode.system;
  CatalogDisplayLanguage _displayLanguage = CatalogDisplayLanguage.en;
  bool _loaded = false;

  CatalogThemeMode get themeMode => _themeMode;
  CatalogDisplayLanguage get displayLanguage => _displayLanguage;
  bool get loaded => _loaded;

  Future<void> load({String? fallbackLocale}) async {
    final storage = await DefaultKeyValueStorage.getInstance();
    final storedTheme = storage.getString(_catalogThemeModeStorageKey);
    final storedLanguage = storage.getString(_catalogDisplayLanguageStorageKey);

    _themeMode = switch (storedTheme) {
      'light' => CatalogThemeMode.light,
      'dark' => CatalogThemeMode.dark,
      _ => CatalogThemeMode.system,
    };

    if (storedLanguage != null && storedLanguage.trim().isNotEmpty) {
      _displayLanguage = CatalogDisplayLanguage.fromCode(storedLanguage);
    } else {
      // Use fallback locale if provided, otherwise use platform locale
      if (fallbackLocale != null && fallbackLocale.trim().isNotEmpty) {
        _displayLanguage = CatalogDisplayLanguage.fromCode(fallbackLocale);
      } else {
        final platformLocale = PlatformDispatcher.instance.locale;
        _displayLanguage = CatalogDisplayLanguage.fromCode(
          platformLocale.countryCode == null || platformLocale.countryCode!.isEmpty
              ? platformLocale.languageCode
              : '${platformLocale.languageCode}-${platformLocale.countryCode}',
        );
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(CatalogThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    final storage = await DefaultKeyValueStorage.getInstance();
    await storage.setString(_catalogThemeModeStorageKey, mode.storageValue);
  }

  Future<void> setDisplayLanguage(CatalogDisplayLanguage language) async {
    if (_displayLanguage == language) {
      return;
    }
    _displayLanguage = language;
    notifyListeners();
    final storage = await DefaultKeyValueStorage.getInstance();
    await storage.setString(_catalogDisplayLanguageStorageKey, language.code);
  }
}
