# Flutter App Setup

This is the shortest path to a working Flutter integration with `anas_localization`.

## 1. Add translation files

Create locale files in `assets/lang`:

```text
assets/lang/en.json
assets/lang/ar.json
assets/lang/tr.json
```

Example `assets/lang/en.json`:

```json
{
  "app_name": "My App",
  "home": {
    "title": "Home"
  },
  "welcome_user": "Welcome {name}"
}
```

## 2. Register the asset folder

In `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/lang/
```

## 3. Generate the dictionary

```bash
dart run anas_localization:localization_gen
```

This generates `lib/generated/dictionary.dart`.

## 4. Wrap the app

```dart
import 'package:anas_localization/anas_localization.dart';
import 'generated/dictionary.dart';

void main() {
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnasLocalization(
      fallbackLocale: Locale('en'),
      assetPath: 'assets/lang',
      assetLocales: [
        Locale('en'),
        Locale('ar'),
        Locale('tr'),
      ],
      app: MyApp(),
    );
  }
}
```

## 5. Use the generated dictionary

```dart
import 'package:flutter/material.dart';
import 'generated/dictionary.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final dict = getDictionary();

    return Scaffold(
      appBar: AppBar(title: Text(dict.appName)),
      body: Center(
        child: Text(dict.welcomeUser(name: 'Anas')),
      ),
    );
  }
}
```

## Next recipes

- [Runtime locale switching](runtime-locale-switching.md)
- [Testing localized widgets](testing-localized-widgets.md)
