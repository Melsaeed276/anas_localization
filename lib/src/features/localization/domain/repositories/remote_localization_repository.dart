import 'dart:ui' show Locale;

import '../entities/remote_localization_cache_snapshot.dart';
import '../entities/remote_localization_payload.dart';
import '../entities/remote_localization_result.dart';
import '../entities/remote_update_descriptor.dart';
import '../entities/remote_localization_version.dart';

abstract interface class RemoteLocalizationRepository {
  Future<RemoteLocalizationUpdateResult> checkForUpdates();

  Future<RemoteLocalizationUpdateResult> checkForLocaleUpdate(Locale locale);

  Future<RemoteLocalizationCacheSnapshot> readCache();

  Future<bool> writeCache(RemoteLocalizationPayload payload);

  Future<void> clearCache();

  Future<RemoteLocalizationVersion?> cachedVersionFor(String locale);
}
