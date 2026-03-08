# Migrate from gen_l10n

Use this page when your app currently uses `l10n.yaml`, ARB files, and generated `AppLocalizations`.

## Recommended migration flow

1. import or rewrite ARB output into `assets/lang/*.json`
2. validate the JSON files
3. generate the dictionary
4. replace `AppLocalizations` bootstrap and lookups

## Import ARB into the app locale folder

```bash
dart run anas_localization:anas_cli import l10n.yaml assets/lang
```

## Replace app bootstrap

```dart
AnasLocalization(
  fallbackLocale: const Locale('en'),
  assetPath: 'assets/lang',
  assetLocales: const [Locale('en'), Locale('ar')],
  app: MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      DictionaryLocalizationsDelegate(),
    ],
    supportedLocales: const [Locale('en'), Locale('ar')],
  ),
)
```

## Replace reads

```dart
final dict = getDictionary();
Text(dict.welcomeTitle);
```

## Next

- [Before and After Examples](before-and-after.md)
- [Validate a Migration](validate-a-migration.md)
