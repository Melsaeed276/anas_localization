/// LocaleStorage handles persisting and retrieving the user's selected locale using local (SharedPreferences) storage.
///
/// This file defines a utility class for managing the user's locale preference in local storage.
/// It provides static methods for saving, loading, and clearing the selected locale code.
///
/// Usage example:
/// ```dart
/// // Save a locale
/// await AnasLocalizationStorage.saveLocale('en');
///
/// // Load a locale
/// String? locale = await AnasLocalizationStorage.loadLocale();
///
/// // Clear the saved locale
/// await AnasLocalizationStorage.clearLocale();
/// ```
library;

import '../../../../core/key_value_storage.dart';

/// A utility class for managing the selected locale in local storage.
///
/// Provides static methods to save, load, and clear the user's selected locale code
/// using [KeyValueStorage]. This can be extended to support cloud storage in the future.
///
/// This is a public class due to allowing developers to freely access and modify their locale preferences.
///
/// You can inject a custom storage implementation for testing or alternative backends:
/// ```dart
/// // Use custom storage
/// AnasLocalizationStorage.storageFactory = () async => MyCustomStorage();
/// ```
abstract class AnasLocalizationStorage {
  /// The key used to store the selected locale in storage.
  static const _localeKey = 'selected_locale';

  /// Factory function to create storage instances.
  /// Override this for testing or custom storage backends.
  static Future<KeyValueStorage> Function() storageFactory = DefaultKeyValueStorage.getInstance;

  /// Saves the selected locale code to local storage.
  ///
  /// [localeCode] is the language code to persist, for example: `'en'`, `'tr'`, or `'ar'`.
  ///
  /// Example:
  /// ```dart
  /// await AnasLocalizationStorage.saveLocale('en');
  /// ```
  ///
  /// Returns a [Future] that completes when the operation has finished.
  static Future<void> saveLocale(String localeCode) async {
    final storage = await storageFactory();
    await storage.setString(_localeKey, localeCode);
  }

  /// Loads the selected locale code from local storage.
  ///
  /// Returns a [Future] containing the saved locale code as a [String], or `null`
  /// if no locale was previously saved.
  ///
  /// Example:
  /// ```dart
  /// String? code = await AnasLocalizationStorage.loadLocale();
  /// ```
  static Future<String?> loadLocale() async {
    final storage = await storageFactory();
    return storage.getString(_localeKey);
  }

  /// Removes the saved locale from local storage.
  ///
  /// This is an optional utility method that clears the stored locale.
  ///
  /// Example:
  /// ```dart
  /// await AnasLocalizationStorage.clearLocale();
  /// ```
  ///
  /// Returns a [Future] that completes when the locale has been removed.
  static Future<void> clearLocale() async {
    final storage = await storageFactory();
    await storage.remove(_localeKey);
  }
}
