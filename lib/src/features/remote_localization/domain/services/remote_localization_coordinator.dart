import 'dart:ui' show Locale;

import 'package:anas_localization/src/shared/services/logging/logging_service.dart';
import 'package:anas_localization/src/shared/services/metrics/remote_localization_metrics.dart';

import '../contracts/remote_localization_service_contract.dart';
import '../entities/remote_localization_cache_snapshot.dart';
import '../entities/remote_localization_config.dart';
import '../entities/remote_localization_failure.dart';
import '../entities/remote_localization_result.dart';
import '../../data/repositories/remote_localization_repository_impl.dart';
import '../contracts/remote_localization_cache_store.dart';

class RemoteLocalizationCoordinator implements RemoteLocalizationService {
  RemoteLocalizationCoordinator({
    required RemoteLocalizationConfig config,
    required RemoteLocalizationCacheStore cacheStore,
  })  : _config = config,
        _repository = RemoteLocalizationRepositoryImpl(
          connector: config.connector,
          cacheStore: cacheStore,
        );

  final RemoteLocalizationConfig _config;
  final RemoteLocalizationRepositoryImpl _repository;

  final Set<String> _inFlight = {};

  Future<RemoteLocalizationUpdateResult> _runWithQueue({
    required String scopeId,
    required RemoteLocalizationScope scope,
    required Future<RemoteLocalizationUpdateResult> Function() operation,
    RemoteLocalizationMetrics? metrics,
  }) async {
    if (_inFlight.contains(scopeId)) {
      return RemoteLocalizationSkippedDuplicate(
        scope: scope,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
    }

    _inFlight.add(scopeId);

    metrics?.increment(RemoteLocalizationMetric.check);
    logger.debug('Remote check started: $scopeId', 'RemoteLocalizationCoordinator');

    try {
      final result = await _executeWithTimeoutAndRetry(
        operation,
        metrics: metrics,
      );
      logger.debug('Remote check completed: $scopeId - ${result.status}', 'RemoteLocalizationCoordinator');
      return result;
    } on RemoteLocalizationFailure catch (f) {
      metrics?.increment(RemoteLocalizationMetric.failure);
      logger.error('Remote check failed: $scopeId', 'RemoteLocalizationCoordinator');
      return RemoteLocalizationFailed(
        scope: scope,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        failure: f.sanitize(),
      );
    } catch (e) {
      metrics?.increment(RemoteLocalizationMetric.failure);
      logger.error('Remote check error: $scopeId', 'RemoteLocalizationCoordinator', e);
      return RemoteLocalizationFailed(
        scope: scope,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        failure: RemoteLocalizationFailure(
          code: RemoteLocalizationFailureCode.checkFailed,
          message: e.toString(),
        ).sanitize(),
      );
    } finally {
      _inFlight.remove(scopeId);
    }
  }

  Future<T> _executeWithTimeoutAndRetry<T>(
    Future<T> Function() operation, {
    RemoteLocalizationMetrics? metrics,
  }) async {
    final timeout = _config.timeout;

    try {
      return await operation().timeout(timeout);
    } catch (_) {
      metrics?.increment(RemoteLocalizationMetric.failure);
      try {
        return await operation().timeout(timeout);
      } catch (e) {
        throw RemoteLocalizationFailure(
          code: RemoteLocalizationFailureCode.timeout,
          message: e.toString(),
          retryAttempted: true,
        );
      }
    }
  }

  @override
  Future<RemoteLocalizationUpdateResult> checkForUpdates() async {
    return _runWithQueue(
      scopeId: '__global__',
      scope: RemoteLocalizationScope.global,
      operation: () => _repository.checkForUpdates(),
      metrics: _config.metrics,
    );
  }

  @override
  Future<RemoteLocalizationUpdateResult> checkForLocaleUpdate(Locale locale) async {
    final localeStr = locale.toString();
    return _runWithQueue(
      scopeId: 'locale:$localeStr',
      scope: RemoteLocalizationScope.locale,
      operation: () => _repository.checkForLocaleUpdate(locale),
      metrics: _config.metrics,
    );
  }

  @override
  Future<RemoteLocalizationCacheSnapshot> readCache() => _repository.readCache();
}
