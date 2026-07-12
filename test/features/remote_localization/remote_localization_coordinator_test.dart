import 'dart:ui' show Locale;

import 'package:anas_localization/src/features/remote_localization/domain/contracts/remote_localization_connector.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_config.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_result.dart';
import 'package:anas_localization/src/features/remote_localization/domain/services/remote_localization_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'remote_localization_test_helpers.dart';

void main() {
  group('coordinator', () {
    test('duplicate global check returns skippedDuplicate', () async {
      final connector = FakeConnector(
        onCheckForUpdates: (_) async {
          // ignore: inference_failure_on_instance_creation
          await Future.delayed(const Duration(milliseconds: 100));
          return const RemoteCheckResponse(descriptors: []);
        },
      );
      final cache = FakeCacheStore();
      final coordinator = RemoteLocalizationCoordinator(
        config: RemoteLocalizationConfig(connector: connector),
        cacheStore: cache,
      );

      final results = await Future.wait([
        coordinator.checkForUpdates(),
        coordinator.checkForUpdates(),
      ]);

      expect(results[0].status, isNot(RemoteLocalizationUpdateStatus.skippedDuplicate));
      expect(
        results[1].status,
        RemoteLocalizationUpdateStatus.skippedDuplicate,
      );
    });

    test('duplicate locale check returns skippedDuplicate', () async {
      final connector = FakeConnector(
        onCheckForLocaleUpdate: (locale, version) async {
          // ignore: inference_failure_on_instance_creation
          await Future.delayed(const Duration(milliseconds: 100));
          return const RemoteCheckResponse(descriptors: []);
        },
      );
      final cache = FakeCacheStore();
      final coordinator = RemoteLocalizationCoordinator(
        config: RemoteLocalizationConfig(connector: connector),
        cacheStore: cache,
      );

      final results = await Future.wait([
        coordinator.checkForLocaleUpdate(const Locale('en')),
        coordinator.checkForLocaleUpdate(const Locale('en')),
      ]);

      expect(results[0].status, isNot(RemoteLocalizationUpdateStatus.skippedDuplicate));
      expect(
        results[1].status,
        RemoteLocalizationUpdateStatus.skippedDuplicate,
      );
    });
  });
}
