# Read Translations

Use this page when you want the recommended runtime read patterns inside widgets.

## Recommended generated access pattern

Import your generated dictionary and read it with `getDictionary()`.

```dart
import 'generated/dictionary.dart';

@override
Widget build(BuildContext context) {
  final dict = getDictionary();

  return Column(
    children: [
      Text(dict.appName),
      Text(dict.welcomeUser(name: 'Anas')),
    ],
  );
}
```

## BuildContext helpers

For runtime state and raw lookups, `BuildContext` helpers are available:

```dart
final currentLocale = context.locale;
final supportedLocales = context.supportedLocales;
final rawValue = context.dict.getString('home.title');
```

## When to use which

- use `getDictionary()` for generated typed access
- use `context.dict` when you need raw key lookups
- use `context.locale` and `context.supportedLocales` for locale-aware UI

## Next

- [Switch Locale at Runtime](locale-switching.md)
- [Preview Dictionaries and Loaders](preview-and-loaders.md)
