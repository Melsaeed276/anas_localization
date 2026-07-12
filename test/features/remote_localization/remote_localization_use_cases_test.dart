import 'dart:ui' show Locale;

import 'package:anas_localization/src/features/remote_localization/domain/contracts/remote_localization_service_contract.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_cache_snapshot.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_result.dart';
import 'package:anas_localization/src/features/remote_localization/use_cases/check_global_remote_localization_update.dart';
import 'package:anas_localization/src/features/remote_localization/use_cases/check_locale_remote_localization_update.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRemoteService implements RemoteLocalizationService {
  bool checkForUpdatesCalled = false;
  bool checkForLocaleUpdateCalled = false;

  @override
  Future<RemoteLocalizationUpdateResult> checkForUpdates() async {
    checkForUpdatesCalled = true;
    return RemoteLocalizationNoUpdate(
      scope: RemoteLocalizationScope.global,
      startedAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
  }

  @override
  Future<RemoteLocalizationUpdateResult> checkForLocaleUpdate(
    Locale locale,
  ) async {
    checkForLocaleUpdateCalled = true;
    return RemoteLocalizationNoUpdate(
      scope: RemoteLocalizationScope.locale,
      startedAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
  }

  @override
  Future<RemoteLocalizationCacheSnapshot> readCache() async {
    return const RemoteLocalizationCacheSnapshot(payloads: {});
  }
}

void main() {
  group('use cases', () {
    test('global use case delegates to service', () async {
      final service = FakeRemoteService();
      final useCase = CheckGlobalRemoteLocalizationUpdate(
        remoteService: service,
      );

      final result = await useCase.call();
      expect(result, isNotNull);
      expect(service.checkForUpdatesCalled, true);
    });

    test('locale use case delegates to service', () async {
      final service = FakeRemoteService();
      final useCase = CheckLocaleRemoteLocalizationUpdate(
        remoteService: service,
      );

      final result = await useCase.call(const Locale('en'));
      expect(result, isNotNull);
      expect(service.checkForLocaleUpdateCalled, true);
    });
  });
}
