# Generate and Wrap Your App

Use this page when your locale files exist and you are ready to generate the dictionary and bootstrap the app.

## 1. Generate the dictionary

```bash
dart run anas_localization:localization_gen
```

For larger projects you can also use module generation:

```bash
dart run anas_localization:localization_gen --modules --module-depth=2
```

## 2. Wrap your app

```dart
import 'package:anas_localization/anas_localization.dart';
import 'generated/dictionary.dart' as app_dictionary;

void main() {
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return AnasLocalization(
      fallbackLocale: const Locale('en'),
      assetLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('tr'),
      ],
      dictionaryFactory: (map, {required locale}) {
        return app_dictionary.Dictionary.fromMap(map, locale: locale);
      },
      app: const MyApp(),
    );
  }
}
```

## 3. Add Flutter delegates to `MaterialApp`

```dart
MaterialApp(
  locale: AnasLocalization.of(context).locale,
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    DictionaryLocalizationsDelegate(),
  ],
  supportedLocales: context.supportedLocales,
  home: const HomePage(),
)
```

## Next

- [Read Translations](../use-in-app/read-translations.md)
- [Switch Locale at Runtime](../use-in-app/locale-switching.md)
