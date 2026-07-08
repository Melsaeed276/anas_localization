import '../entities/remote_localization_cache_snapshot.dart';
import '../entities/remote_localization_payload.dart';

abstract interface class RemoteLocalizationCacheStore {
  Future<RemoteLocalizationCacheSnapshot?> read();

  Future<bool> write(RemoteLocalizationPayload payload);

  Future<void> clear();

  Future<RemoteLocalizationCacheSnapshot> snapshot();
}
