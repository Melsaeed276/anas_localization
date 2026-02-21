/// Provides the [Localization] InheritedWidget for accessing localized strings in the widget tree.
///
/// Wrap your app with [Localization] and provide the current [Dictionary] and locale code.
/// Access the current dictionary with:
///
/// ```dart
/// final dictionary = Localization.of(context).dictionary;
/// ```
///
/// This allows you to use type-safe, autocompleted translations in your widgets.
library;

import 'package:flutter/widgets.dart';

import '../generated/dictionary.dart';

/// An [InheritedWidget] that exposes the current [Dictionary] and [locale] to descendant widgets.
///
/// Use [Localization.of(context)] to access the current dictionary and locale.
class Localization extends InheritedWidget {
  /// The currently loaded [Dictionary] containing localized strings.
  final Dictionary? dictionary;

  /// The current locale code (e.g., "en", "tr", "ar").
  final String? locale;

  const Localization({
    super.key,
    required super.child,
    required this.dictionary,
    required this.locale,
  });

  /// Retrieves the nearest [Localization] instance from the [BuildContext].
  ///
  /// Throws an [AssertionError] if no [Localization] ancestor is found.
  static Localization of(BuildContext context) {
    final Localization? result = context
        .dependOnInheritedWidgetOfExactType<Localization>();
    assert(result != null, 'No Localization found in context');
    return result!;
  }

  /// Notifies dependents if the dictionary or locale has changed.
  @override
  bool updateShouldNotify(Localization oldWidget) {
    // Update widgets if dictionary or locale changed
    return dictionary != oldWidget.dictionary || locale != oldWidget.locale;
  }
}
