import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_version.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_failure.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_result.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_config.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/remote_localization/remote_localization_test_helpers.dart';

void main() {
  group('RemoteLocalizationVersion', () {
    test('normalize converts non-UTC to UTC', () {
      final nonUtc = DateTime(2026, 7, 8, 10, 0, 0);
      final version = RemoteLocalizationVersion(updatedAtUtc: nonUtc);
      final normalized = version.normalize();
      expect(normalized.updatedAtUtc.isUtc, true);
      expect(normalized.updatedAtUtc, DateTime.utc(2026, 7, 8, 10, 0, 0));
    });

    test('isNewerThan returns true for strictly newer timestamps', () {
      final older = versionAt(2026, 7, 1);
      final newer = versionAt(2026, 7, 8);
      expect(newer.isNewerThan(older), true);
      expect(older.isNewerThan(newer), false);
    });

    test('isNewerThan returns false for equal timestamps', () {
      final a = versionAt(2026, 7, 8);
      final b = versionAt(2026, 7, 8);
      expect(a.isNewerThan(b), false);
    });
  });

  group('RemoteLocalizationUpdateResult', () {
    test('updated status', () {
      final result = RemoteLocalizationUpdateSuccess(
        scope: RemoteLocalizationScope.global,
        startedAt: DateTime(2026),
        completedAt: DateTime(2026),
        appliedLocales: ['en', 'ar'],
      );
      expect(result.status, RemoteLocalizationUpdateStatus.updated);
      expect(result.appliedLocales, ['en', 'ar']);
    });

    test('noUpdate status', () {
      final result = RemoteLocalizationNoUpdate(
        scope: RemoteLocalizationScope.global,
        startedAt: DateTime(2026),
        completedAt: DateTime(2026),
      );
      expect(result.status, RemoteLocalizationUpdateStatus.noUpdate);
    });

    test('skippedDuplicate status', () {
      final result = RemoteLocalizationSkippedDuplicate(
        scope: RemoteLocalizationScope.locale,
        startedAt: DateTime(2026),
        completedAt: DateTime(2026),
      );
      expect(result.status, RemoteLocalizationUpdateStatus.skippedDuplicate);
    });

    test('unsupported status', () {
      final result = RemoteLocalizationUnsupported(
        scope: RemoteLocalizationScope.global,
        startedAt: DateTime(2026),
        completedAt: DateTime(2026),
      );
      expect(result.status, RemoteLocalizationUpdateStatus.unsupported);
    });

    test('failed status includes sanitized failure', () {
      final failure = const RemoteLocalizationFailure(
        code: RemoteLocalizationFailureCode.downloadFailed,
        message: 'Connection refused',
        retryAttempted: true,
      );
      final result = RemoteLocalizationFailed(
        scope: RemoteLocalizationScope.global,
        startedAt: DateTime(2026),
        completedAt: DateTime(2026),
        failure: failure,
      );
      expect(result.status, RemoteLocalizationUpdateStatus.failed);
      expect(result.failure.message, 'Connection refused');
      expect(result.failure.retryAttempted, true);
    });
  });

  group('RemoteLocalizationConfig', () {
    test('checkOnStartup defaults to false', () {
      final connector = FakeConnector();
      final config = RemoteLocalizationConfig(connector: connector);
      expect(config.checkOnStartup, false);
    });

    test('preserves the provided connector', () {
      final connector = FakeConnector();
      final config = RemoteLocalizationConfig(connector: connector);
      expect(config.connector, same(connector));
    });
  });
}
