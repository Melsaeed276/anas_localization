/// Provides the [LocalizationService] class for loading and managing localized translations.
///
/// This service is responsible for loading translation data from JSON files, creating a [Dictionary]
/// for the current locale, and providing access to the active dictionary. It is typically used by
/// state management or provider classes to enable localization throughout the app.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../generated/dictionary.dart';

/// A singleton service responsible for loading translations and providing the current [Dictionary].
///
/// [LocalizationService] loads translation data from asset JSON files for supported locales.
/// It manages the currently loaded dictionary and locale, and exposes them for use by the app.
/// This class is not responsible for persistence or storage of user choices.
///
/// If loading a non-English locale fails, it attempts to gracefully fallback to English ("en") before throwing an error.
class LocalizationService {
  /// The singleton instance of [LocalizationService].
  static final LocalizationService _instance = LocalizationService._internal();

  /// Returns the singleton instance of [LocalizationService].
  factory LocalizationService() => _instance;

  /// Internal constructor for singleton pattern.
  LocalizationService._internal();

  /// Holds the currently loaded [Dictionary], or null if not loaded.
  Dictionary? _currentDictionary;

  /// Holds the code of the currently loaded locale, or null if not loaded.
  String? _currentLocale;

  /// The list of locale codes that this service supports. Update this list as you add new language assets.
  static List<String> supportedLocales = ['en', 'tr', 'ar'];

  /// Returns the list of all supported locale codes.
  ///
  /// This is a static getter useful for locale pickers or UI elements displaying available languages.
  static List<String> get allSupportedLocales => supportedLocales;

  /// Loads translations for the given [localeCode] from assets, merging app overrides over package defaults.
  ///
  /// If loading a non-English locale fails, this method attempts to load English ("en") using the same
  /// merge strategy (app over package) before rethrowing the error.
  ///
  /// Throws an [Exception] if the locale is unsupported or no assets can be found (including fallback failure).
  Future<void> loadLocale(String localeCode) async {
    if (!supportedLocales.contains(localeCode)) {
      throw Exception('Unsupported locale: $localeCode');
    }

    try {
      final merged = await _loadMergedJsonFor(localeCode);
      _currentDictionary = Dictionary.fromMap(merged, locale: localeCode);
      _currentLocale = localeCode;
    } catch (e) {
      if (localeCode != 'en') {
        // Fallback to English using the same merge logic
        final mergedEn = await _loadMergedJsonFor('en');
        _currentDictionary = Dictionary.fromMap(mergedEn, locale: 'en');
        _currentLocale = 'en';
        return;
      }
      rethrow;
    }
  }

  /// Loads and returns a [Dictionary] for a specific [localeCode] without mutating the current state.
  /// Uses the same merge + fallback strategy as [loadLocale].
  Future<Dictionary> loadDictionaryForLocale(String localeCode) async {
    if (!supportedLocales.contains(localeCode)) {
      throw Exception('Unsupported locale: $localeCode');
    }
    try {
      final merged = await _loadMergedJsonFor(localeCode);
      return Dictionary.fromMap(merged, locale: localeCode);
    } catch (_) {
      if (localeCode != 'en') {
        final mergedEn = await _loadMergedJsonFor('en');
        return Dictionary.fromMap(mergedEn, locale: 'en');
      }
      rethrow;
    }
  }

  /// Returns the currently loaded [Dictionary].
  ///
  /// Throws an [Exception] if no dictionary is loaded.
  Dictionary get currentDictionary {
    if (_currentDictionary == null) {
      throw Exception('Localization not loaded. Call loadLocale() first.');
    }
    return _currentDictionary!;
  }

  /// Returns the code of the currently loaded locale, or null if none is loaded.
  String? get currentLocale => _currentLocale;

  /// Clears the currently loaded dictionary and locale.
  ///
  /// After calling this method, no locale is loaded and [currentDictionary] will throw until a new locale is loaded.
  void clear() {
    _currentDictionary = null;
    _currentLocale = null;
  }

  // ----- Internal helpers -----

  /// Attempts to load and merge JSON maps for [code] from:
  /// 1) App assets: 'assets/lang/{code}.json' (overrides)
  /// 2) Package assets: 'packages/anas_localization/assets/lang/{code}.json' (defaults)
  ///
  /// Returns the merged map if either source exists. If neither exists, throws.
  Future<Map<String, dynamic>> _loadMergedJsonFor(String code) async {
    final appKey = 'assets/lang/$code.json';
    final pkgKey = 'packages/anas_localization/assets/lang/$code.json';

    final Map<String, dynamic>? app = await _tryLoadJson(appKey);
    final Map<String, dynamic>? pkg = await _tryLoadJson(pkgKey);

    if (app == null && pkg == null) {
      throw Exception('No localization assets found for "$code".');
    }

    // Merge: package provides defaults, app overrides
    return {
      ...?pkg,
      ...?app,
    };
  }

  /// Loads a JSON asset by key via [rootBundle]. Returns null if missing or invalid.
  Future<Map<String, dynamic>?> _tryLoadJson(String assetKey) async {
    Future<Map<String, dynamic>?> _load(String key) async {
      final jsonString = await rootBundle.loadString(key);
      final Map<String, dynamic> map = json.decode(jsonString) as Map<String, dynamic>;
      return map;
    }

    try {
      // Try the canonical key first
      final result = await _load(assetKey);
      return result;
    } on FlutterError {
      // If the key looks like a package asset, attempt a build-prefixed variant as a last resort
      if (assetKey.startsWith('packages/anas_localization/')) {
        final altKey = 'build/flutter_assets/$assetKey';
        try {
          final result = await _load(altKey);
          return result;
        } on FlutterError {
          return null; // not found with either key
        } catch (_) {
          return null; // malformed JSON or other issue
        }
      }
      return null; // not found and not a package asset
    } catch (_) {
      // Malformed JSON — treat as missing to allow fallbacks
      return null;
    }
  }
}