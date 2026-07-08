import 'dart:ui' show Locale;

import '../entities/remote_localization_cache_snapshot.dart';
import '../entities/remote_localization_result.dart';

abstract interface class RemoteLocalizationService {
  Future<RemoteLocalizationUpdateResult> checkForUpdates();

  Future<RemoteLocalizationUpdateResult> checkForLocaleUpdate(Locale locale);

  Future<RemoteLocalizationCacheSnapshot> readCache();
}
