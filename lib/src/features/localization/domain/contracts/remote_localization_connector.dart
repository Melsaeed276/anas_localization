import 'dart:ui' show Locale;

import '../entities/remote_localization_payload.dart';
import '../entities/remote_localization_cache_snapshot.dart';
import '../entities/remote_update_descriptor.dart';

abstract interface class RemoteLocalizationConnector {
  bool get supportsGlobalCheck;
  bool get supportsLocaleCheck;

  Future<RemoteCheckResponse> checkForUpdates(
    RemoteVersionSnapshot cachedVersions,
  );

  Future<RemoteCheckResponse> checkForLocaleUpdate(
    Locale locale,
    RemoteLocalizationVersion? cachedVersion,
  );

  Future<RemoteLocalizationPayload> downloadPayload(
    RemoteUpdateDescriptor update,
  );
}

final class RemoteCheckResponse {
  const RemoteCheckResponse({
    required this.descriptors,
    this.failure,
  });

  final List<RemoteUpdateDescriptor> descriptors;
  final Object? failure;
}
