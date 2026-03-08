# Localized Widget Tests

Use this page when you want widget tests that render localized UI without depending on bundled assets.

## Minimal localized test

```dart
import 'package:anas_localization/anas_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a localized title', (tester) async {
    await tester.pumpWidget(
      AnasLocalization(
        fallbackLocale: const Locale('en'),
        assetLocales: const [Locale('en')],
        animationSetup: false,
        previewDictionaries: const {
          'en': {
            'title': 'Home',
          },
        },
        app: MaterialApp(
          home: Builder(
            builder: (context) => Text(context.dict.getString('title')),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}
```

## Notes

- set `animationSetup: false` in tests to remove transition noise
- use `previewDictionaries` when assets are not part of the test bundle
- use generated dictionary imports when you want typed access in tests

## Next

- [CI Patterns](ci-patterns.md)
- [Preview Dictionaries and Loaders](../use-in-app/preview-and-loaders.md)
