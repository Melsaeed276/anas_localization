import 'dart:ui' show Locale;

import '../contracts/remote_localization_service_contract.dart';
import '../entities/remote_localization_cache_snapshot.dart';
import '../entities/remote_localization_result.dart';

class RemoteLocalizationDisabledService implements RemoteLocalizationService {
  const RemoteLocalizationDisabledService();

  @override
  Future<RemoteLocalizationUpdateResult> checkForUpdates() async {
    return RemoteLocalizationUnsupported(
      scope: RemoteLocalizationScope.global,
      startedAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
  }

  @override
  Future<RemoteLocalizationUpdateResult> checkForLocaleUpdate(
    Locale locale,
  ) async {
    return RemoteLocalizationUnsupported(
      scope: RemoteLocalizationScope.locale,
      startedAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
  }

  @override
  Future<RemoteLocalizationCacheSnapshot> readCache() async {
    return const RemoteLocalizationCacheSnapshot(payloads: {});
  }

  @override
  Future<void> applyRemoteUpdates() async {}
}
