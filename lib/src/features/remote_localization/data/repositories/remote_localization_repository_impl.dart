import 'dart:ui' show Locale;

import 'package:anas_localization/src/features/remote_localization/domain/contracts/remote_localization_cache_store.dart';
import 'package:anas_localization/src/features/remote_localization/domain/contracts/remote_localization_connector.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_cache_snapshot.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_failure.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_payload.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_result.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_version.dart';
import 'package:anas_localization/src/features/remote_localization/domain/repositories/remote_localization_repository.dart';
import 'package:anas_localization/src/shared/services/logging/logging_service.dart';

class RemoteLocalizationRepositoryImpl implements RemoteLocalizationRepository {
  RemoteLocalizationRepositoryImpl({
    required RemoteLocalizationConnector connector,
    required RemoteLocalizationCacheStore cacheStore,
  })  : _connector = connector,
        _cacheStore = cacheStore;

  final RemoteLocalizationConnector _connector;
  final RemoteLocalizationCacheStore _cacheStore;

  @override
  Future<RemoteLocalizationUpdateResult> checkForUpdates() async {
    if (!_connector.supportsGlobalCheck) {
      return RemoteLocalizationUnsupported(
        scope: RemoteLocalizationScope.global,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
    }

    final startedAt = DateTime.now();
    try {
      final cached = await _cacheStore.snapshot();
      final cachedVersions = RemoteVersionSnapshot(
        versions: cached.payloads.map(
          (key, value) => MapEntry(key, value.version),
        ),
      );

      final response = await _connector.checkForUpdates(cachedVersions);
      if (response.descriptors.isEmpty) {
        return RemoteLocalizationNoUpdate(
          scope: RemoteLocalizationScope.global,
          startedAt: startedAt,
          completedAt: DateTime.now(),
        );
      }

      final appliedLocales = <String>[];
      for (final descriptor in response.descriptors) {
        final cachedPayload = cached.payloadFor(descriptor.locale);
        final cachedVersion = cachedPayload?.version;
        if (cachedVersion != null && !descriptor.version.isNewerThan(cachedVersion)) continue;

        try {
          final payload = await _connector.downloadPayload(descriptor);
          if (payload.locale != descriptor.locale) continue;
          if (!payload.isValid) continue;

          final existingPayload = cached.payloadFor(descriptor.locale);
          if (existingPayload != null && !payload.isNewerThan(existingPayload)) continue;

          await _cacheStore.write(payload);
          appliedLocales.add(descriptor.locale);
        } catch (e) {
          logger.error('Failed to download payload for ${descriptor.locale}', 'RemoteLocalizationRepository', e);
        }
      }

      return RemoteLocalizationUpdateSuccess(
        scope: RemoteLocalizationScope.global,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        appliedLocales: appliedLocales,
      );
    } on RemoteLocalizationFailure catch (f) {
      return RemoteLocalizationFailed(
        scope: RemoteLocalizationScope.global,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        failure: f.sanitize(),
      );
    } catch (e) {
      return RemoteLocalizationFailed(
        scope: RemoteLocalizationScope.global,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        failure: RemoteLocalizationFailure(
          code: RemoteLocalizationFailureCode.checkFailed,
          message: e.toString(),
        ).sanitize(),
      );
    }
  }

  @override
  Future<RemoteLocalizationUpdateResult> checkForLocaleUpdate(Locale locale) async {
    if (!_connector.supportsLocaleCheck) {
      return RemoteLocalizationUnsupported(
        scope: RemoteLocalizationScope.locale,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
    }

    final startedAt = DateTime.now();
    final localeCode = locale.toString();
    try {
      final cached = await _cacheStore.snapshot();
      final cachedPayload = cached.payloadFor(localeCode);
      final cachedVersion = cachedPayload?.version;

      final response = await _connector.checkForLocaleUpdate(locale, cachedVersion);
      if (response.descriptors.isEmpty) {
        return RemoteLocalizationNoUpdate(
          scope: RemoteLocalizationScope.locale,
          startedAt: startedAt,
          completedAt: DateTime.now(),
        );
      }

      final descriptor = response.descriptors.firstWhere(
        (d) => d.locale == localeCode,
        orElse: () => response.descriptors.first,
      );

      if (descriptor.locale != localeCode) {
        return RemoteLocalizationNoUpdate(
          scope: RemoteLocalizationScope.locale,
          startedAt: startedAt,
          completedAt: DateTime.now(),
        );
      }

      final cachedP = cached.payloadFor(localeCode);
      final cachedVer = cachedP?.version;
      if (cachedVer != null && !descriptor.version.isNewerThan(cachedVer)) {
        return RemoteLocalizationNoUpdate(
          scope: RemoteLocalizationScope.locale,
          startedAt: startedAt,
          completedAt: DateTime.now(),
        );
      }

      final payload = await _connector.downloadPayload(descriptor);
      if (!payload.isValid) {
        return RemoteLocalizationFailed(
          scope: RemoteLocalizationScope.locale,
          startedAt: startedAt,
          completedAt: DateTime.now(),
          failure: const RemoteLocalizationFailure(
            code: RemoteLocalizationFailureCode.parseFailed,
            message: 'Invalid payload',
          ).sanitize(),
        );
      }

      await _cacheStore.write(payload);
      return RemoteLocalizationUpdateSuccess(
        scope: RemoteLocalizationScope.locale,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        appliedLocales: [localeCode],
      );
    } on RemoteLocalizationFailure catch (f) {
      return RemoteLocalizationFailed(
        scope: RemoteLocalizationScope.locale,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        failure: f.sanitize(),
      );
    } catch (e) {
      return RemoteLocalizationFailed(
        scope: RemoteLocalizationScope.locale,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        failure: RemoteLocalizationFailure(
          code: RemoteLocalizationFailureCode.checkFailed,
          message: e.toString(),
        ).sanitize(),
      );
    }
  }

  @override
  Future<RemoteLocalizationCacheSnapshot> readCache() => _cacheStore.snapshot();

  @override
  Future<bool> writeCache(RemoteLocalizationPayload payload) => _cacheStore.write(payload);

  @override
  Future<void> clearCache() => _cacheStore.clear();

  @override
  Future<RemoteLocalizationVersion?> cachedVersionFor(String locale) async {
    final cached = await _cacheStore.snapshot();
    return cached.payloadFor(locale)?.version;
  }
}
