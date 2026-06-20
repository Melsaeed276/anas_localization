/// Domain contract for LocalizationService used by Catalog feature.
///
/// This contract defines the API surface that Catalog needs from LocalizationService
/// without exposing data or presentation layer details.
library;

import '../entities/dictionary.dart';

/// Abstract contract for localization service configuration and access.
///
/// Catalog depends on this contract instead of the concrete LocalizationService
/// to maintain feature boundary compliance (no imports of localization/data/).
abstract interface class LocalizationServiceContract {
  /// Get the singleton instance of the localization service.
  ///
  /// This factory method allows features to access the service
  /// without importing the concrete implementation.
  static LocalizationServiceContract? _instance;

  /// Register the concrete implementation.
  ///
  /// This should be called once at app startup to wire the concrete
  /// implementation to the contract.
  static void register(LocalizationServiceContract instance) {
    _instance = instance;
  }

  /// Get the registered instance.
  ///
  /// Throws [StateError] if no instance has been registered.
  static LocalizationServiceContract get instance {
    if (_instance == null) {
      throw StateError(
        'LocalizationServiceContract not registered. '
        'Call LocalizationServiceContract.register() at app startup.',
      );
    }
    return _instance!;
  }

  /// Set the dictionary factory for creating Dictionary instances.
  void setDictionaryFactory(
    Dictionary Function(Map<String, dynamic>, {required String locale}) factory,
  );

  /// Get the current locale code.
  String? get currentLocale;

  /// Get the current dictionary.
  Dictionary? get currentDictionary;
}
