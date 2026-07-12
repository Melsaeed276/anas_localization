class RemoteTranslationMergePolicy {
  RemoteTranslationMergePolicy._();

  static const String _overrideKey = '__override__';
  static const String _valueKey = 'value';

  /// Merges translation data with package < app < remote precedence.
  ///
  /// App entries can use a metadata wrapper to prevent remote override:
  /// ```json
  /// {"key": {"value": "translation", "__override__": false}}
  /// ```
  /// Missing `__override__` defaults to `true` (remote can replace).
  /// All metadata wrappers are stripped from the result.
  static Map<String, dynamic> merge({
    required Map<String, dynamic> packageData,
    required Map<String, dynamic> appData,
    Map<String, dynamic>? remoteData,
  }) {
    final strippedApp = <String, dynamic>{};
    final protectedPaths = <String>{};
    _stripAppData(appData, strippedApp, protectedPaths, '');

    final result = <String, dynamic>{};
    _deepMerge(result, packageData);
    _deepMerge(result, strippedApp);

    if (remoteData != null) {
      _mergeRemote(result, remoteData, protectedPaths, '');
    }

    return result;
  }

  /// Recursively strips metadata wrappers from app data.
  /// A wrapper is a Map with a `value` key containing the actual translation
  /// and an optional `__override__` key for protection.
  static void _stripAppData(
    Map<String, dynamic> source,
    Map<String, dynamic> target,
    Set<String> protectedPaths,
    String prefix,
  ) {
    for (final entry in source.entries) {
      final key = entry.key;
      final value = entry.value;
      final path = prefix.isEmpty ? key : '$prefix.$key';

      if (value is Map<String, dynamic>) {
        if (value.containsKey(_valueKey)) {
          target[key] = value[_valueKey];
          final override = value[_overrideKey];
          if (override == false) {
            protectedPaths.add(path);
          }
        } else {
          final nested = <String, dynamic>{};
          target[key] = nested;
          _stripAppData(value, nested, protectedPaths, path);
        }
      } else {
        target[key] = value;
      }
    }
  }

  /// Deep merges source into target.
  static void _deepMerge(
    Map<String, dynamic> target,
    Map<String, dynamic> source,
  ) {
    for (final entry in source.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map<String, dynamic> && target[key] is Map<String, dynamic>) {
        _deepMerge(
          target[key]! as Map<String, dynamic>,
          value,
        );
      } else {
        target[key] = value;
      }
    }
  }

  /// Merges remote data into target, skipping protected paths.
  static void _mergeRemote(
    Map<String, dynamic> target,
    Map<String, dynamic> source,
    Set<String> protectedPaths,
    String prefix,
  ) {
    for (final entry in source.entries) {
      final key = entry.key;
      final value = entry.value;
      final path = prefix.isEmpty ? key : '$prefix.$key';

      if (protectedPaths.contains(path)) continue;

      if (value is Map<String, dynamic> && target[key] is Map<String, dynamic>) {
        _mergeRemote(
          target[key]! as Map<String, dynamic>,
          value,
          protectedPaths,
          path,
        );
      } else {
        target[key] = value;
      }
    }
  }
}
