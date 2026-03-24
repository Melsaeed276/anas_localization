/// Key-value storage abstraction for persisting application preferences.
///
/// This abstraction allows dependency injection of storage implementations,
/// enabling users to use their preferred storage solution
/// (e.g., `shared_preferences`, `hive`, or custom implementations).
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Abstract interface for key-value storage operations.
///
/// This interface provides a common API for storing and retrieving
/// primitive values. The default implementation uses [SharedPreferences],
/// but custom implementations can be injected for testing or alternative
/// storage backends.
///
/// Example usage:
/// ```dart
/// // Use the default implementation
/// final storage = await DefaultKeyValueStorage.getInstance();
///
/// // Or inject a custom implementation for testing
/// final mockStorage = InMemoryKeyValueStorage();
/// ```
abstract interface class KeyValueStorage {
  /// Returns a [String] value for the given [key], or `null` if not found.
  String? getString(String key);

  /// Returns a [bool] value for the given [key], or `null` if not found.
  bool? getBool(String key);

  /// Returns an [int] value for the given [key], or `null` if not found.
  int? getInt(String key);

  /// Returns a [double] value for the given [key], or `null` if not found.
  double? getDouble(String key);

  /// Returns a [List<String>] for the given [key], or `null` if not found.
  List<String>? getStringList(String key);

  /// Stores a [String] value for the given [key].
  Future<bool> setString(String key, String value);

  /// Stores a [bool] value for the given [key].
  Future<bool> setBool(String key, bool value);

  /// Stores an [int] value for the given [key].
  Future<bool> setInt(String key, int value);

  /// Stores a [double] value for the given [key].
  Future<bool> setDouble(String key, double value);

  /// Stores a [List<String>] for the given [key].
  Future<bool> setStringList(String key, List<String> value);

  /// Removes the value for the given [key].
  Future<bool> remove(String key);

  /// Returns `true` if the storage contains the given [key].
  bool containsKey(String key);

  /// Clears all key-value pairs from storage.
  Future<bool> clear();
}

/// Default implementation of [KeyValueStorage] using [SharedPreferences].
///
/// This implementation wraps the `shared_preferences` package to provide
/// cross-platform key-value storage.
class DefaultKeyValueStorage implements KeyValueStorage {
  DefaultKeyValueStorage._(this._prefs);

  final SharedPreferences _prefs;

  /// Creates a new instance of [DefaultKeyValueStorage].
  ///
  /// This is an async factory because [SharedPreferences.getInstance] is async.
  static Future<DefaultKeyValueStorage> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return DefaultKeyValueStorage._(prefs);
  }

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  int? getInt(String key) => _prefs.getInt(key);

  @override
  double? getDouble(String key) => _prefs.getDouble(key);

  @override
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  @override
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);

  @override
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  @override
  Future<bool> setDouble(String key, double value) => _prefs.setDouble(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) => _prefs.setStringList(key, value);

  @override
  Future<bool> remove(String key) => _prefs.remove(key);

  @override
  bool containsKey(String key) => _prefs.containsKey(key);

  @override
  Future<bool> clear() => _prefs.clear();
}

/// In-memory implementation of [KeyValueStorage] for testing.
///
/// This implementation stores values in memory and does not persist
/// across app restarts. Useful for unit tests.
class InMemoryKeyValueStorage implements KeyValueStorage {
  final Map<String, Object> _data = {};

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  double? getDouble(String key) => _data[key] as double?;

  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  @override
  bool containsKey(String key) => _data.containsKey(key);

  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }
}
