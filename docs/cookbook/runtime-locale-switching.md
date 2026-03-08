# Runtime Locale Switching

`anas_localization` keeps locale changes explicit and context-bound.

## Change the locale

```dart
await AnasLocalization.of(context).setLocale(const Locale('ar'));
```

## Example button

```dart
ElevatedButton(
  onPressed: () async {
    await AnasLocalization.of(context).setLocale(const Locale('tr'));
  },
  child: const Text('Switch to Turkish'),
)
```

## Read the current locale

```dart
final currentLocale = context.locale;
```

## Read the supported locales

```dart
final supportedLocales = context.supportedLocales;
```

## Notes

- translation reads should come from the generated dictionary, typically `getDictionary()`
- locale switching should keep using `AnasLocalization.of(context)`
- widget tests should pump the app inside `AnasLocalization`
