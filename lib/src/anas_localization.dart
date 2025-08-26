import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/widgets.dart' show Widget, StatefulWidget, State, BuildContext, InheritedWidget;

import 'core/anas_localization_storage.dart' show AnasLocalizationStorage;
import 'core/localization_service.dart' show LocalizationService;
import 'generated/dictionary.dart' show Dictionary;

/*
Instead of using import/export within the package,
Lets use 'part' / 'part of' directives to include files.

It will allow us to use private classes and members within the same library.
Making usage of the package straightforward and clean.
Disallowing users to break the package functionality etc.
*/

part 'localization_manager.dart';

// ? Should we use a wrapper class that will rebuild the whole app in case of locale changes?
// ? Using such thing will also make the initialization automated.
// ? Even we can make it StatefulWidget, optimizing 'shouldUpdateWidget'

class AnasLocalization extends StatefulWidget {
  const AnasLocalization({
    super.key,
    required this.app,
    this.assetPath = 'assets/localization',
    this.fallbackLocale = const Locale('en'),
    this.assetLocales = const [Locale('en')],
  });

  /// The main application widget that should be wrapped with localization
  final Widget app;

  /// The fallback locale to use when the current locale is not supported.
  ///
  /// Also the specified key to be translated is not exists for the current locale,
  /// it will be picked from fallback locale.
  final Locale fallbackLocale;

  /// The asset path for localization files.
  final String assetPath; // TODO (loader-update): Make this useful

  /// Locales exists as assets in the app
  final List<Locale> assetLocales;

  @override
  State<StatefulWidget> createState() => _AnasLocalizationState();

  // ignore: library_private_types_in_public_api
  static _AnasLocalizationWidget of(BuildContext context) => _AnasLocalizationWidget.of(context)!;

  static Dictionary get dictionary => _LocalizationManager.instance.currentDictionary;
}

class _AnasLocalizationState extends State<AnasLocalization> {
  Locale? knownLocale;

  @override
  void initState() {
    super.initState();

    _LocalizationManager.instance.addListener((locale) {
      setState(() {
        knownLocale = _LocalizationManager.instance.locale;
      });
    });

    _initialize();
  }

  /// The future of initializing locale.
  Future<void> _initialize() async {
    knownLocale = await _LocalizationManager.instance.loadSavedLocaleOrDefault(widget.fallbackLocale);
  }

  @override
  Widget build(BuildContext context) => _AnasLocalizationWidget(
        app: widget.app,
        locale: knownLocale ?? widget.fallbackLocale,
        supportedLocales: widget.assetLocales, // In case of we have server sync locales, this should be changed
      );
}

class _AnasLocalizationWidget extends InheritedWidget {
  const _AnasLocalizationWidget({
    // ignore: unused_element_parameter
    super.key,
    required this.app,
    required this.locale,
    required this.supportedLocales,
  }) : super(child: app);

  final Widget app;
  final Locale locale;
  final List<Locale> supportedLocales;

  @override
  bool updateShouldNotify(_AnasLocalizationWidget oldWidget) => oldWidget.locale != locale;

  static _AnasLocalizationWidget? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AnasLocalizationWidget>();

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.any((element) => element.languageCode == locale.languageCode)) {
      throw Exception('New locale is not supported: ${locale.languageCode}');
    }
    _LocalizationManager.instance.saveLocale(locale);
  }

  Dictionary get dictionary => _LocalizationManager.instance.currentDictionary;
}
