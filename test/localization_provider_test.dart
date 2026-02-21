import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anas_localization/src/core/localization_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Provide dummy values for shared_preferences before tests
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalizationProvider', () {
    test('throws if dictionary is accessed before loading', () {
      final provider = LocalizationProvider();
      expect(() => provider.dictionary, throwsException);
    });

    test('throws if locale is accessed before loading', () {
      final provider = LocalizationProvider();
      expect(() => provider.locale, throwsException);
    });

    test('loads locale and dictionary, then allows access', () async {
      final provider = LocalizationProvider();
      await provider.loadLocale('en');
      expect(provider.locale, 'en');
      expect(
        provider.dictionary.welcome,
        'Welcome',
      ); // Change to your actual key/expected value
    });

    test('saves selected locale to SharedPreferences', () async {
      final provider = LocalizationProvider();
      await provider.loadLocale('tr');
      // Load again with a new instance to test persistence
      final _ = await provider.loadSavedLocaleOrDefault();
      expect(provider.locale, 'tr');
    });

    test('restores saved locale or falls back to default', () async {
      final provider = LocalizationProvider();

      // Save a locale
      await provider.loadLocale('ar');

      // Should restore 'ar' if saved
      await provider.loadSavedLocaleOrDefault();
      expect(provider.locale, 'ar');

      // Clear storage and check fallback
      await provider.loadLocale('en');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_locale');
      await provider.loadSavedLocaleOrDefault('tr');
      expect(provider.locale, 'tr');
    });

    test(
      'loadSavedLocaleOrDefault uses fallback if no locale is saved',
      () async {
        final provider = LocalizationProvider();

        // Ensure storage is empty
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('selected_locale');

        // Should use fallback
        await provider.loadSavedLocaleOrDefault('en');
        expect(provider.locale, 'en');
      },
    );

    test(
      'calling loadLocale twice updates the locale and dictionary',
      () async {
        final provider = LocalizationProvider();
        await provider.loadLocale('en');
        expect(provider.locale, 'en');

        await provider.loadLocale('tr');
        expect(provider.locale, 'tr');
        // Check that dictionary has updated value
        expect(
          provider.dictionary.welcome,
          isNot('Welcome'),
        ); // Replace with expected Turkish
      },
    );

    test('saves selected locale to SharedPreferences', () async {
      final provider = LocalizationProvider();
      await provider.loadLocale('tr');
      // Load again with a new instance to test persistence
      final _ = await provider.loadSavedLocaleOrDefault();
      expect(provider.locale, 'tr');
    });

    test('restores saved locale or falls back to default', () async {
      final provider = LocalizationProvider();

      // Save a locale
      await provider.loadLocale('ar');

      // Should restore 'ar' if saved
      await provider.loadSavedLocaleOrDefault();
      expect(provider.locale, 'ar');

      // Clear storage and check fallback
      await provider.loadLocale('en');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_locale');
      await provider.loadSavedLocaleOrDefault('tr');
      expect(provider.locale, 'tr');
    });

    test(
      'loadSavedLocaleOrDefault uses fallback if no locale is saved',
      () async {
        final provider = LocalizationProvider();

        // Ensure storage is empty
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('selected_locale');

        // Should use fallback
        await provider.loadSavedLocaleOrDefault('en');
        expect(provider.locale, 'en');
      },
    );
  });
}
