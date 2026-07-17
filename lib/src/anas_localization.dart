import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/widgets.dart' show Widget, StatefulWidget, State, BuildContext, InheritedWidget;
import 'package:flutter/material.dart' show Color;

import 'core/dictionary.dart';
import 'core/anas_localization_storage.dart' show AnasLocalizationStorage;
import 'core/localization_exceptions.dart';
import 'core/localization_service.dart' show LocalizationService;
import 'features/remote_localization/domain/entities/remote_localization_cache_snapshot.dart';
import 'features/remote_localization/domain/entities/remote_localization_config.dart';
import 'features/remote_localization/domain/contracts/remote_localization_service_contract.dart';
import 'services/logging_service/logging_service.dart';
import 'widgets/language_setup_overlay.dart' show AnasLanguageSetupOverlay, anasLanguageSetupOverlayKey;

/*
Instead of using import/export within the package,
Let's use 'part' / 'part of' directives to include files.

It will allow us to use private classes and members within the same library.
Making usage of the package straightforward and clean.
Disallowing users to break the package functionality etc.
*/

part 'localization_manager.dart';

/// Global getter for easy access to the current dictionary
/// Usage: t.appName, t.welcomeUser(name: 'John'), etc.
dynamic get t => _LocalizationManager.instance.currentDictionary;

/// Extension to make BuildContext-based access even easier
extension LocalizationExtension on BuildContext {
  /// Access the dictionary directly from BuildContext
  /// Usage: context.dict.appName
  Dictionary get dict => AnasLocalization.of(this).dictionary;

  /// Access locale directly from BuildContext
  /// Usage: context.locale
  Locale get locale => AnasLocalization.of(this).locale;

  /// Access supported locales directly from BuildContext
  /// Usage: context.supportedLocales
  List<Locale> get supportedLocales => AnasLocalization.of(this).supportedLocales;
}

/// Public API contract exposed by [AnasLocalization.of].
///
/// This keeps the internal inherited widget private while exposing
/// a stable, public type to package consumers.
abstract class AnasLocalizationScope {
  Widget get app;
  Locale get locale;
  bool get isInitialized;
  List<Locale> get supportedLocales;
  Dictionary get dictionary;
  Future<void> setLocale(Locale locale);

  /// Re-applies cached remote translations to the live dictionary so strings
  /// downloaded by the remote service become visible without a full app
  /// restart. See also [AnasLocalization.applyRemoteUpdates].
  Future<void> applyRemoteUpdates();
}

// ? Should we use a wrapper class that will rebuild the whole app in case of locale changes?
// ? Using such thing will also make the initialization automated.
// ? Even we can make it StatefulWidget, optimizing 'shouldUpdateWidget'

class AnasLocalization extends StatefulWidget {
  const AnasLocalization({
    super.key,
    required this.app,
    this.dictionaryFactory,
    this.assetPath = 'assets/lang',
    this.fallbackLocale = const Locale('en'),
    this.assetLocales = const [Locale('en')],
    this.animationSetup = true, // Default to true for iPhone-style setup
    this.setupDuration = const Duration(milliseconds: 2000), // Default 2 seconds
    this.overlayBackgroundColor,
    this.overlayTextColor,
    this.showProgressIndicator = true,
    this.previewDictionaries,
    this.remoteConfig,
  });

  /// The main application widget that should be wrapped with localization
  final Widget app;

  /// Factory function to create Dictionary instances from the app's generated Dictionary class
  /// If not provided, will automatically try to use generated createDictionary function
  final Dictionary Function(Map<String, dynamic>, {required String locale})? dictionaryFactory;

  /// The fallback locale to use when the current locale is not supported.
  ///
  /// Also the specified key to be translated is not exists for the current locale,
  /// it will be picked from fallback locale.
  final Locale fallbackLocale;

  /// The asset path for localization files.
  ///
  /// Defaults to `assets/lang` and can be customized when app assets are placed
  /// in a different folder.
  final String assetPath;

  /// Locales exists as assets in the app
  final List<Locale> assetLocales;

  /// Whether to enable animation during the setup
  final bool animationSetup;

  /// Duration of the setup animation
  final Duration? setupDuration;

  /// Background color of the overlay during setup
  final Color? overlayBackgroundColor;

  /// Text color of the overlay during setup
  final Color? overlayTextColor;

  /// Whether to show a progress indicator during setup
  final bool showProgressIndicator;

  /// Optional in-memory dictionaries used in Flutter preview mode/tests.
  ///
  /// If provided, locale JSON will be loaded from this map before checking
  /// assets. Key format: locale code (e.g. 'en', 'ar').
  final Map<String, Map<String, dynamic>>? previewDictionaries;

  /// Optional remote localization configuration.
  ///
  /// When provided, remote localization is enabled with the given config.
  /// Remote startup checks only run if [RemoteLocalizationConfig.checkOnStartup]
  /// is `true` and never block initial local dictionary loading.
  final RemoteLocalizationConfig? remoteConfig;

  @override
  State<StatefulWidget> createState() => _AnasLocalizationState();

  static AnasLocalizationScope of(BuildContext context) {
    final scope = _AnasLocalizationWidget.of(context);
    if (scope == null) {
      throw const LocalizationNotInitializedException();
    }
    return scope;
  }

  static Dictionary get dictionary => _LocalizationManager.instance.currentDictionary;

  /// Returns the configured [RemoteLocalizationService].
  ///
  /// If remote localization is not configured, returns a disabled service
  /// that always returns [RemoteLocalizationUpdateStatus.unsupported].
  static RemoteLocalizationService get remote => LocalizationService.remoteService;

  /// Re-applies cached remote translations to the live dictionary so strings
  /// downloaded by [remote] become visible without a full app restart.
  ///
  /// Convenience wrapper around [RemoteLocalizationService.applyRemoteUpdates].
  static Future<void> applyRemoteUpdates() => LocalizationService.remoteService.applyRemoteUpdates();
}

class _AnasLocalizationState extends State<AnasLocalization> {
  Locale? knownLocale;
  bool _isInitialized = false;
  late void Function(Locale?) _localeListener;
  late void Function() _remoteListener;

  @override
  void initState() {
    super.initState();

    // Create a stable listener function reference
    _localeListener = (locale) {
      if (mounted) {
        setState(() {
          knownLocale = locale;
        });
      }
    };

    _LocalizationManager.instance.addListener(_localeListener);

    // The coordinator auto-applies remote translations by reloading the
    // dictionary inside [LocalizationService] (which notifies its own
    // listeners). Subscribe so the widget rebuilds and surfaces the new
    // strings even when the active locale value does not change.
    _remoteListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    LocalizationService().addLocaleLoadedListener(_remoteListener);

    _initialize();
  }

  @override
  void dispose() {
    _LocalizationManager.instance.removeListener(_localeListener);
    LocalizationService().removeLocaleLoadedListener(_remoteListener);
    super.dispose();
  }

  /// The future of initializing locale.
  Future<void> _initialize() async {
    LocalizationService.configure(
      appAssetPath: widget.assetPath,
      locales: widget.assetLocales.map(LocalizationService.localeToCode).toList(),
      previewDictionaries: widget.previewDictionaries ?? <String, Map<String, dynamic>>{},
      fallbackLocaleCode: LocalizationService.localeToCode(widget.fallbackLocale),
      remote: widget.remoteConfig,
    );

    // Try to auto-detect dictionary factory from LocalizationService first
    // This will be set if the generated dictionary file was imported
    final currentFactory = LocalizationService().getDictionaryFactory();

    // Set the dictionary factory before loading locale
    if (widget.dictionaryFactory != null) {
      // User explicitly provided a factory
      _LocalizationManager.instance.setDictionaryFactory(widget.dictionaryFactory!);
    } else if (currentFactory != null) {
      // Auto-detected from generated dictionary import
      _LocalizationManager.instance.setDictionaryFactory(currentFactory);
    }
    // If neither is available, the default Dictionary class will be used

    final loadedLocale = await _LocalizationManager.instance.loadSavedLocaleOrDefault(widget.fallbackLocale);
    if (mounted) {
      setState(() {
        knownLocale = loadedLocale;
        _isInitialized = true;
      });
    }

    _triggerStartupRemoteCheck();
  }

  void _triggerStartupRemoteCheck() {
    final config = widget.remoteConfig;
    if (config == null || !config.checkOnStartup) return;

    config.connector
        .checkForUpdates(
      const RemoteVersionSnapshot(versions: {}),
    )
        .then((_) async {
      logger.debug('Startup remote check completed', 'AnasLocalization');
      // The coordinator automatically re-applies the live dictionary after a
      // successful check; apply again here as a safety net so remote strings
      // are visible even if the active locale loads after this check.
      await LocalizationService().applyRemoteUpdates();
    }).catchError((Object error) {
      logger.error('Startup remote check failed', 'AnasLocalization', error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizationWidget = _AnasLocalizationWidget(
      app: widget.animationSetup
          ? AnasLanguageSetupOverlay(
              key: anasLanguageSetupOverlayKey,
              duration: widget.setupDuration ?? const Duration(milliseconds: 2000),
              backgroundColor: widget.overlayBackgroundColor,
              textColor: widget.overlayTextColor,
              showProgressIndicator: widget.showProgressIndicator,
              child: widget.app,
            )
          : widget.app,
      locale: knownLocale ?? widget.fallbackLocale,
      isInitialized: _isInitialized,
      supportedLocales: widget.assetLocales,
    );

    return localizationWidget;
  }
}

class _AnasLocalizationWidget extends InheritedWidget implements AnasLocalizationScope {
  const _AnasLocalizationWidget({
    // ignore: unused_element_parameter
    super.key,
    required this.app,
    required this.locale,
    required this.isInitialized,
    required this.supportedLocales,
  }) : super(child: app);

  @override
  final Widget app;
  @override
  final Locale locale;
  @override
  final bool isInitialized;
  @override
  final List<Locale> supportedLocales;

  @override
  bool updateShouldNotify(_AnasLocalizationWidget oldWidget) =>
      oldWidget.locale != locale || oldWidget.isInitialized != isInitialized;

  static _AnasLocalizationWidget? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AnasLocalizationWidget>();

  @override
  Future<void> setLocale(Locale locale) async {
    final requestedLocaleCode = LocalizationService.localeToCode(locale);
    final isSupported = supportedLocales.any((element) {
      final supportedCode = LocalizationService.localeToCode(element);
      return supportedCode == requestedLocaleCode || element.languageCode == locale.languageCode;
    });
    if (!isSupported) {
      throw UnsupportedLocaleException(requestedLocaleCode);
    }
    await _LocalizationManager.instance.saveLocale(locale);
  }

  @override
  Dictionary get dictionary => _LocalizationManager.instance.currentDictionary;

  @override
  Future<void> applyRemoteUpdates() => LocalizationService.remoteService.applyRemoteUpdates();
}
