import 'package:flutter_test/flutter_test.dart';
import 'package:anas_localization/src/features/catalog/domain/entities/fallback_cascade_notification.dart';

void main() {
  group('FallbackCascadeNotification', () {
    test('creates notification with correct properties', () {
      final notification = FallbackCascadeNotification(
        deletedLocale: 'ar_EG',
        affectedSourceLocales: ['ar_SA', 'ar_west'],
        timestamp: DateTime(2024, 1, 1),
      );

      expect(notification.deletedLocale, equals('ar_EG'));
      expect(notification.affectedSourceLocales, equals(['ar_SA', 'ar_west']));
      expect(notification.timestamp, equals(DateTime(2024, 1, 1)));
    });

    test('generates message with affected locales', () {
      final notification = FallbackCascadeNotification(
        deletedLocale: 'ar_EG',
        affectedSourceLocales: ['ar_SA', 'ar_west'],
        timestamp: DateTime.now(),
      );

      expect(notification.message, contains('ar_SA'));
      expect(notification.message, contains('ar_west'));
      expect(notification.message, contains('ar_EG'));
      expect(notification.message, contains('Fallback configuration cleared'));
    });

    test('generates message for single affected locale', () {
      final notification = FallbackCascadeNotification(
        deletedLocale: 'ar_EG',
        affectedSourceLocales: ['ar_SA'],
        timestamp: DateTime.now(),
      );

      expect(notification.message, contains('ar_SA'));
      expect(notification.message, contains('ar_EG'));
    });

    test('generates simple message when no affected locales', () {
      final notification = FallbackCascadeNotification(
        deletedLocale: 'ar_EG',
        affectedSourceLocales: [],
        timestamp: DateTime.now(),
      );

      expect(notification.message, equals('Locale "ar_EG" deleted.'));
    });

    test('toString returns helpful representation', () {
      final notification = FallbackCascadeNotification(
        deletedLocale: 'ar_EG',
        affectedSourceLocales: ['ar_SA'],
        timestamp: DateTime.now(),
      );

      final str = notification.toString();
      expect(str, contains('FallbackCascadeNotification'));
      expect(str, contains('ar_EG'));
      expect(str, contains('ar_SA'));
    });

    group('Cascade delete scenarios', () {
      test('Scenario 1: Single affected locale', () {
        final notification = FallbackCascadeNotification(
          deletedLocale: 'ar_EG',
          affectedSourceLocales: ['ar_SA'],
          timestamp: DateTime.now(),
        );

        expect(notification.affectedSourceLocales.length, equals(1));
        expect(notification.message, contains('ar_SA'));
      });

      test('Scenario 2: Multiple affected locales', () {
        final notification = FallbackCascadeNotification(
          deletedLocale: 'ar_EG',
          affectedSourceLocales: ['ar_SA', 'ar_west', 'ar_desert'],
          timestamp: DateTime.now(),
        );

        expect(notification.affectedSourceLocales.length, equals(3));
        expect(notification.message, contains('ar_SA'));
        expect(notification.message, contains('ar_west'));
        expect(notification.message, contains('ar_desert'));
      });

      test('Scenario 3: No affected locales', () {
        final notification = FallbackCascadeNotification(
          deletedLocale: 'unused_locale',
          affectedSourceLocales: [],
          timestamp: DateTime.now(),
        );

        expect(notification.affectedSourceLocales.isEmpty, isTrue);
        expect(notification.message, equals('Locale "unused_locale" deleted.'));
      });
    });
  });
}
