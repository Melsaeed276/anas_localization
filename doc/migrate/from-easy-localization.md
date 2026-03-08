# Migrate from easy_localization

Use this page when your app currently reads strings through `.tr()` and stores locale files in `assets/translations`.

## What changes

- source files move into `assets/lang`
- app bootstrap changes from `EasyLocalization` to `AnasLocalization`
- lookups move to generated dictionary access
- locale switching moves to `AnasLocalization.of(context).setLocale(...)`

## Normalize translation files

If your source files are already JSON, move or copy them into `assets/lang`.

If you need a format bridge, use the package CLI:

```bash
dart run anas_localization:anas_cli export assets/translations json translations_export.json
dart run anas_localization:anas_cli import translations_export.json assets/lang
```

## Replace setup

```dart
AnasLocalization(
  fallbackLocale: const Locale('en'),
  assetPath: 'assets/lang',
  assetLocales: const [Locale('en'), Locale('ar'), Locale('tr')],
  app: const MyApp(),
)
```

## Replace lookups

```dart
final dict = getDictionary();
Text(dict.homeTitle);
Text(dict.cartItems(count: itemCount));
await AnasLocalization.of(context).setLocale(const Locale('ar'));
```

## Next

- [Before and After Examples](before-and-after.md)
- [Validate a Migration](validate-a-migration.md)
