import 'dart:ui' show Locale;

import '../entities/remote_localization_cache_snapshot.dart';
import '../entities/remote_localization_result.dart';

abstract interface class RemoteLocalizationService {
  Future<RemoteLocalizationUpdateResult> checkForUpdates();

  Future<RemoteLocalizationUpdateResult> checkForLocaleUpdate(Locale locale);

  /// Re-applies the cached remote translations into the live dictionary so
  /// that strings downloaded by [checkForUpdates]/[checkForLocaleUpdate]
  /// become visible without a full app restart.
  Future<void> applyRemoteUpdates();

  Future<RemoteLocalizationCacheSnapshot> readCache();
}
