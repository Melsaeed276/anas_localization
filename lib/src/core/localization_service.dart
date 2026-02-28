library;

import 'package:flutter/material.dart';

import '../services/logging_service/logging_service.dart';
import 'dictionary.dart';
import 'localization_exceptions.dart';
import 'translation_loader.dart';

class LocalizationService {
  factory LocalizationService() => _instance;

  LocalizationService._internal();

  static final LocalizationService _instance = LocalizationService._internal();

  Dictionary? _currentDictionary;
  String? _currentLocale;
  List<String> _lastLocaleResolutionPath = const <String>[];

  Dictionary Function(Map<String, dynamic>, {required String locale})? _dictionaryFactory;

  static List<String> supportedLocales = ['en', 'tr', 'ar'];
  static String _appAssetPath = 'assets/lang';
  static String _fallbackLocaleCode = 'en';
  static Map<String, Map<String, dynamic>> _previewDictionaries = const {};
  static TranslationLoaderRegistry _loaderRegistry = TranslationLoaderRegistry.withDefaults();

  void setDictionaryFactory(Dictionary Function(Map<String, dynamic>, {required String locale}) factory) {
    _dictionaryFactory = factory;
  }

  Dictionary Function(Map<String, dynamic>, {required String locale})? getDictionaryFactory() {
    return _dictionaryFactory;
  }

  Dictionary _createDictionary(Map<String, dynamic> map, {required String locale}) {
    if (_dictionaryFactory != null) {
      return _dictionaryFactory!(map, locale: locale);
    }
    return Dictionary.fromMap(map, locale: locale);
  }

  static void setAppAssetPath(String path) {
    _appAssetPath = path.trim().isEmpty ? 'assets/lang' : path;
  }

  static void setFallbackLocaleCode(String localeCode) {
    final normalized = normalizeLocaleCode(localeCode);
    _fallbackLocaleCode = normalized.isEmpty ? 'en' : normalized;
  }

  static String get fallbackLocaleCode => _fallbackLocaleCode;

  static void setTranslationLoaders(List<TranslationLoader> loaders) {
    _loaderRegistry = TranslationLoaderRegistry(loaders);
  }

  static void registerTranslationLoader(
    TranslationLoader loader, {
    bool highestPriority = false,
  }) {
    _loaderRegistry.register(loader, highestPriority: highestPriority);
  }

  static bool unregisterTranslationLoader(String loaderId) {
    return _loaderRegistry.unregister(loaderId);
  }

  static void resetTranslationLoaders() {
    _loaderRegistry = TranslationLoaderRegistry.withDefaults();
  }

  static List<TranslationLoader> get registeredTranslationLoaders => _loaderRegistry.loaders;

  static void setPreviewDictionaries(Map<String, Map<String, dynamic>> dictionaries) {
    _previewDictionaries = Map<String, Map<String, dynamic>>.from(dictionaries);
  }

  static void clearPreviewDictionaries() {
    _previewDictionaries = const {};
  }

  static void configure({
    String? appAssetPath,
    List<String>? locales,
    Map<String, Map<String, dynamic>>? previewDictionaries,
    String? fallbackLocaleCode,
    List<TranslationLoader>? loaders,
  }) {
    if (appAssetPath != null) {
      setAppAssetPath(appAssetPath);
    }
    if (locales != null && locales.isNotEmpty) {
      supportedLocales = locales.map(normalizeLocaleCode).toSet().toList();
    }
    if (previewDictionaries != null) {
      setPreviewDictionaries(previewDictionaries);
    }
    if (fallbackLocaleCode != null) {
      setFallbackLocaleCode(fallbackLocaleCode);
    }
    if (loaders != null && loaders.isNotEmpty) {
      setTranslationLoaders(loaders);
    }
  }

  static List<String> get allSupportedLocales => supportedLocales;

  static String localeToCode(Locale locale) {
    final script = locale.scriptCode;
    final country = locale.countryCode;
    if (script != null && script.isNotEmpty && country != null && country.isNotEmpty) {
      return normalizeLocaleCode('${locale.languageCode}_${script}_$country');
    }
    if (script != null && script.isNotEmpty) {
      return normalizeLocaleCode('${locale.languageCode}_$script');
    }
    if (country != null && country.isNotEmpty) {
      return normalizeLocaleCode('${locale.languageCode}_$country');
    }
    return normalizeLocaleCode(locale.languageCode);
  }

  static String normalizeLocaleCode(String localeCode) {
    final trimmed = localeCode.trim();
    if (trimmed.isEmpty) return '';

    final canonical = trimmed.replaceAll('-', '_');
    final parts = canonical.split('_').where((segment) => segment.isNotEmpty).toList();
    if (parts.isEmpty) return '';

    final language = parts[0].toLowerCase();
    String? script;
    String? region;

    if (parts.length >= 2) {
      if (parts[1].length == 4) {
        script = _toScriptCase(parts[1]);
      } else {
        region = parts[1].toUpperCase();
      }
    }

    if (parts.length >= 3) {
      if (script == null && parts[1].length == 4) {
        script = _toScriptCase(parts[1]);
      } else if (script == null && parts[2].length == 4) {
        script = _toScriptCase(parts[2]);
      }
      region ??= parts[2].toUpperCase();
    }

    if (parts.length >= 4 && region == null) {
      region = parts[3].toUpperCase();
    }

    final segments = <String>[language];
    if (script != null && script.isNotEmpty) {
      segments.add(script);
    }
    if (region != null && region.isNotEmpty) {
      segments.add(region);
    }
    return segments.join('_');
  }

  static bool isLocaleSupported(String localeCode) {
    final normalizedRequested = normalizeLocaleCode(localeCode);
    if (normalizedRequested.isEmpty) {
      return false;
    }

    final normalizedSupported = supportedLocales.map(normalizeLocaleCode).toSet();
    if (normalizedSupported.contains(normalizedRequested)) {
      return true;
    }

    final requestedParts = _LocaleParts.parse(normalizedRequested);
    if (requestedParts == null) {
      return false;
    }

    return normalizedSupported.any((candidate) {
      final candidateParts = _LocaleParts.parse(candidate);
      return candidateParts != null && candidateParts.language == requestedParts.language;
    });
  }

  static List<String> resolveLocaleFallbackChain(
    String localeCode, {
    String? fallbackLocaleCode,
  }) {
    final requested = _LocaleParts.parse(normalizeLocaleCode(localeCode));
    if (requested == null) {
      return <String>[];
    }

    final fallback = _LocaleParts.parse(
      normalizeLocaleCode(fallbackLocaleCode ?? _fallbackLocaleCode),
    );

    final chain = <String>[
      ...requested.buildFallbackChain(),
    ];

    if (fallback != null) {
      for (final item in fallback.buildFallbackChain()) {
        if (!chain.contains(item)) {
          chain.add(item);
        }
      }
    }

    return chain;
  }

  List<String> getLastLocaleResolutionPath() {
    return List<String>.unmodifiable(_lastLocaleResolutionPath);
  }

  Future<void> loadLocale(String localeCode) async {
    final normalizedRequested = normalizeLocaleCode(localeCode);
    if (!isLocaleSupported(normalizedRequested)) {
      logger.error('Unsupported locale: $localeCode', 'LocalizationService');
      throw UnsupportedLocaleException(localeCode);
    }

    final resolutionPath = resolveLocaleFallbackChain(normalizedRequested);
    _lastLocaleResolutionPath = List<String>.from(resolutionPath);

    Object? lastError;
    for (final candidate in resolutionPath) {
      try {
        final merged = await _loadMergedJsonFor(candidate);
        _currentDictionary = _createDictionary(merged, locale: candidate);
        _currentLocale = candidate;
        logger.localeLoaded(candidate);
        logger.dictionaryCreated(candidate);
        return;
      } catch (error) {
        lastError = error;
      }
    }

    logger.localeLoadFailed(normalizedRequested, lastError ?? 'No locale candidates could be loaded.');
    if (lastError is LocalizationException) {
      throw lastError;
    }
    throw LocalizationAssetsNotFoundException(normalizedRequested);
  }

  Future<Dictionary> loadDictionaryForLocale(String localeCode) async {
    final normalizedRequested = normalizeLocaleCode(localeCode);
    if (!isLocaleSupported(normalizedRequested)) {
      throw UnsupportedLocaleException(localeCode);
    }

    final resolutionPath = resolveLocaleFallbackChain(normalizedRequested);
    _lastLocaleResolutionPath = List<String>.from(resolutionPath);

    Object? lastError;
    for (final candidate in resolutionPath) {
      try {
        final merged = await _loadMergedJsonFor(candidate);
        return _createDictionary(merged, locale: candidate);
      } catch (error) {
        lastError = error;
      }
    }

    if (lastError is LocalizationException) {
      throw lastError;
    }
    throw LocalizationAssetsNotFoundException(normalizedRequested);
  }

  Dictionary get currentDictionary {
    final current = _currentDictionary;
    if (current != null) return current;

    final locale = _currentLocale ?? (supportedLocales.isNotEmpty ? supportedLocales.first : 'en');
    return Dictionary.fromMap(const <String, dynamic>{}, locale: locale);
  }

  String? get currentLocale => _currentLocale;

  void clear() {
    _currentDictionary = null;
    _currentLocale = null;
    _lastLocaleResolutionPath = const <String>[];
  }

  Future<Map<String, dynamic>> _loadMergedJsonFor(String code) async {
    final preview = _resolvePreviewDictionary(code);
    if (preview != null) {
      return preview;
    }

    final appBase = '$_appAssetPath/$code';
    final pkgBase = 'packages/anas_localization/assets/lang/$code';

    final appData = await _loaderRegistry.loadFirst(appBase);
    final packageData = await _loaderRegistry.loadFirst(pkgBase);

    if (appData == null && packageData == null) {
      throw LocalizationAssetsNotFoundException(code);
    }

    return <String, dynamic>{
      ...?packageData,
      ...?appData,
    };
  }

  Map<String, dynamic>? _resolvePreviewDictionary(String localeCode) {
    final normalized = normalizeLocaleCode(localeCode);
    final candidates = <String>{
      localeCode,
      normalized,
      normalized.replaceAll('_', '-'),
    };

    for (final candidate in candidates) {
      final preview = _previewDictionaries[candidate];
      if (preview != null) {
        return Map<String, dynamic>.from(preview);
      }
    }
    return null;
  }
}

class _LocaleParts {
  const _LocaleParts({
    required this.language,
    this.script,
    this.region,
  });

  final String language;
  final String? script;
  final String? region;

  static _LocaleParts? parse(String localeCode) {
    final normalized = LocalizationService.normalizeLocaleCode(localeCode);
    if (normalized.isEmpty) return null;
    final parts = normalized.split('_');
    if (parts.isEmpty) return null;

    final language = parts[0];
    String? script;
    String? region;

    if (parts.length >= 2) {
      if (parts[1].length == 4) {
        script = _toScriptCase(parts[1]);
      } else {
        region = parts[1].toUpperCase();
      }
    }

    if (parts.length >= 3) {
      if (script == null && parts[1].length == 4) {
        script = _toScriptCase(parts[1]);
      }
      region ??= parts[2].toUpperCase();
    }

    return _LocaleParts(
      language: language.toLowerCase(),
      script: script,
      region: region,
    );
  }

  List<String> buildFallbackChain() {
    final chain = <String>[];

    if (script != null && script!.isNotEmpty && region != null && region!.isNotEmpty) {
      chain.add('${language}_${script}_$region');
    }
    if (script != null && script!.isNotEmpty) {
      chain.add('${language}_$script');
    }
    if (region != null && region!.isNotEmpty) {
      chain.add('${language}_$region');
    }
    chain.add(language);

    return chain;
  }
}

String _toScriptCase(String value) {
  if (value.isEmpty) return value;
  final normalized = value.toLowerCase();
  return normalized[0].toUpperCase() + normalized.substring(1);
}
