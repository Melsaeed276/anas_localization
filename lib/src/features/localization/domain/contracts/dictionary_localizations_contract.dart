/// Domain contract for DictionaryLocalizations used by Catalog feature.
///
/// This contract defines the API surface that Catalog needs from DictionaryLocalizations
/// without exposing presentation layer details.
library;

import 'package:flutter/widgets.dart';

import '../entities/dictionary.dart';

/// Abstract contract for accessing localized dictionaries via BuildContext.
///
/// Catalog depends on this contract instead of the concrete DictionaryLocalizations
/// to maintain feature boundary compliance (no imports of localization/presentation/).
abstract interface class DictionaryLocalizationsContract {
  /// Get the DictionaryLocalizations instance from the given context.
  ///
  /// Returns null if no DictionaryLocalizations is found in the widget tree.
  static DictionaryLocalizationsContract? of(BuildContext context) {
    throw UnsupportedError('of must be implemented');
  }

  /// Get the localized dictionary.
  Dictionary get dictionary;
}
