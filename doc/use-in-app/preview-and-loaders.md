# Preview Dictionaries and Loaders

Use this page when asset bundles are not convenient, such as Flutter previews, widget tests, or custom runtime loading setups.

## Preview dictionaries

```dart
AnasLocalization(
  fallbackLocale: const Locale('en'),
  assetLocales: const [Locale('en'), Locale('ar')],
  previewDictionaries: const {
    'en': {
      'app_name': 'Preview App',
    },
    'ar': {
      'app_name': 'تطبيق المعاينة',
    },
  },
  app: const MyApp(),
)
```

## Custom translation loaders

```dart
LocalizationService.setTranslationLoaders([
  const JsonTranslationLoader(),
  const YamlTranslationLoader(),
  const CsvTranslationLoader(),
]);
```

## Notes

- preview dictionaries are checked before asset files
- the default loader registry already supports JSON, YAML, and CSV
- use `LocalizationService.resetTranslationLoaders()` to go back to defaults

## Next

- [Localized Widget Tests](../testing/widget-tests.md)
- [Concepts](../reference/concepts.md)
