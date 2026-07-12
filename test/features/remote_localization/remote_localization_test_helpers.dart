import 'dart:ui' show Locale;

import 'package:anas_localization/src/features/remote_localization/domain/contracts/remote_localization_connector.dart';
import 'package:anas_localization/src/features/remote_localization/domain/contracts/remote_localization_cache_store.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_cache_snapshot.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_payload.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_version.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_update_descriptor.dart';
import 'package:anas_localization/src/shared/services/metrics/remote_localization_metrics.dart';

class FakeConnector implements RemoteLocalizationConnector {
  FakeConnector({
    this.supportsGlobalCheck = true,
    this.supportsLocaleCheck = true,
    this.onCheckForUpdates,
    this.onCheckForLocaleUpdate,
    this.onDownloadPayload,
  });

  @override
  final bool supportsGlobalCheck;
  @override
  final bool supportsLocaleCheck;

  Future<RemoteCheckResponse> Function(RemoteVersionSnapshot cachedVersions)? onCheckForUpdates;
  Future<RemoteCheckResponse> Function(Locale locale, RemoteLocalizationVersion? cachedVersion)? onCheckForLocaleUpdate;
  Future<RemoteLocalizationPayload> Function(RemoteUpdateDescriptor update)? onDownloadPayload;

  @override
  Future<RemoteCheckResponse> checkForUpdates(
    RemoteVersionSnapshot cachedVersions,
  ) =>
      onCheckForUpdates != null
          ? onCheckForUpdates!(cachedVersions)
          : Future.value(const RemoteCheckResponse(descriptors: []));

  @override
  Future<RemoteCheckResponse> checkForLocaleUpdate(
    Locale locale,
    RemoteLocalizationVersion? cachedVersion,
  ) =>
      onCheckForLocaleUpdate != null
          ? onCheckForLocaleUpdate!(locale, cachedVersion)
          : Future.value(const RemoteCheckResponse(descriptors: []));

  @override
  Future<RemoteLocalizationPayload> downloadPayload(
    RemoteUpdateDescriptor update,
  ) =>
      onDownloadPayload != null
          ? onDownloadPayload!(update)
          : Future.value(
              RemoteLocalizationPayload(
                locale: update.locale,
                version: update.version,
                translations: const {},
              ),
            );
}

class FakeCacheStore implements RemoteLocalizationCacheStore {
  RemoteLocalizationCacheSnapshot? _stored;

  @override
  Future<RemoteLocalizationCacheSnapshot?> read() async => _stored;

  @override
  Future<bool> write(RemoteLocalizationPayload payload) async {
    final existing = _stored;
    final payloads = Map<String, RemoteLocalizationPayload>.from(
      existing?.payloads ?? {},
    );
    payloads[payload.locale] = payload;
    _stored = RemoteLocalizationCacheSnapshot(
      payloads: payloads,
      lastWriteAt: DateTime.now(),
    );
    return true;
  }

  @override
  Future<void> clear() async {
    _stored = null;
  }

  @override
  Future<RemoteLocalizationCacheSnapshot> snapshot() async =>
      _stored ?? const RemoteLocalizationCacheSnapshot(payloads: {});
}

class FakeMetrics implements RemoteLocalizationMetrics {
  final List<RemoteLocalizationMetric> increments = [];

  @override
  void increment(RemoteLocalizationMetric metric, {Locale? locale}) {
    increments.add(metric);
  }
}

RemoteLocalizationVersion versionAt(int year, int month, int day) {
  return RemoteLocalizationVersion(
    updatedAtUtc: DateTime.utc(year, month, day),
  );
}

RemoteLocalizationVersion versionNow() {
  return RemoteLocalizationVersion(updatedAtUtc: DateTime.now().toUtc());
}

RemoteLocalizationPayload payloadFor(
  String locale, {
  DateTime? updatedAt,
  Map<String, Object?>? translations,
}) {
  return RemoteLocalizationPayload(
    locale: locale,
    version: RemoteLocalizationVersion(
      updatedAtUtc: updatedAt ?? DateTime.now().toUtc(),
    ),
    translations: translations ?? {'key': 'value_$locale'},
  );
}
