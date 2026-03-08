# Testing Localized Widgets

The simplest test pattern is to pump a small `AnasLocalization` wrapper with in-memory dictionaries.

## Example widget test

```dart
import 'package:anas_localization/anas_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders translated text', (tester) async {
    await tester.pumpWidget(
      AnasLocalization(
        fallbackLocale: const Locale('en'),
        assetLocales: const [Locale('en')],
        animationSetup: false,
        previewDictionaries: const {
          'en': {
            'home': {'title': 'Home'}
          },
        },
        app: MaterialApp(
          home: Builder(
            builder: (context) {
              return Text(context.dict.getString('home.title'));
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}
```

## If you use generated accessors

Generate the dictionary first and import `lib/generated/dictionary.dart` in the test target.

Typical read pattern:

```dart
expect(find.text(getDictionary().homeTitle), findsOneWidget);
```

## Tips

- disable the setup animation in tests with `animationSetup: false`
- use `previewDictionaries` when asset bundles are not part of the test
- keep locale switching assertions focused on UI outcome, not internal state
