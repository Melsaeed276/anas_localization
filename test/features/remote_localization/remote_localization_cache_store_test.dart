import 'package:anas_localization/src/features/remote_localization/data/sources/remote_localization_cache_store.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_payload.dart';
import 'package:anas_localization/src/features/remote_localization/domain/entities/remote_localization_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RemoteLocalizationFileCacheStore store;
  final testPayload = RemoteLocalizationPayload(
    locale: 'en',
    version: RemoteLocalizationVersion(
      updatedAtUtc: DateTime.utc(2026, 7, 8),
    ),
    translations: {'hello': 'world'},
  );

  setUp(() {
    store = RemoteLocalizationFileCacheStore(
      directoryPath: '/tmp/anas_test_cache',
    );
  });

  tearDown(() async {
    await store.clear();
  });

  group('cache store', () {
    test('read returns null for empty store', () async {
      final result = await store.read();
      expect(result, isNull);
    });

    test('write and read succeeds', () async {
      final writeResult = await store.write(testPayload);
      expect(writeResult, true);

      final readResult = await store.read();
      expect(readResult, isNotNull);
      expect(readResult!.payloadFor('en'), isNotNull);
      expect(
        readResult.payloadFor('en')!.translations['hello'],
        'world',
      );
    });

    test('clear removes all data', () async {
      await store.write(testPayload);
      await store.clear();

      final result = await store.read();
      expect(result, isNull);
    });

    test('snapshot returns empty when nothing cached', () async {
      final snapshot = await store.snapshot();
      expect(snapshot.payloads, isEmpty);
    });

    test('snapshot returns payloads after write', () async {
      await store.write(testPayload);
      final snapshot = await store.snapshot();
      expect(snapshot.payloads, isNotEmpty);
      expect(snapshot.payloadFor('en'), isNotNull);
    });

    test('write preserves existing payloads when adding new locale', () async {
      await store.write(testPayload);
      final arPayload = RemoteLocalizationPayload(
        locale: 'ar',
        version: RemoteLocalizationVersion(
          updatedAtUtc: DateTime.utc(2026, 7, 8),
        ),
        translations: {'hello': 'مرحبا'},
      );
      await store.write(arPayload);

      final snapshot = await store.snapshot();
      expect(snapshot.payloadFor('en'), isNotNull);
      expect(snapshot.payloadFor('ar'), isNotNull);
    });
  });
}
