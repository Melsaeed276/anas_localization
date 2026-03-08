# Switch Locale at Runtime

Use this page when the app is already localized and you want to let users change language during runtime.

## Change the locale

```dart
await AnasLocalization.of(context).setLocale(const Locale('tr'));
```

## Example button

```dart
ElevatedButton(
  onPressed: () async {
    await AnasLocalization.of(context).setLocale(const Locale('ar'));
  },
  child: const Text('Switch to Arabic'),
)
```

## Notes

- locale switching is intentionally context-bound
- translation reads can stay on the generated dictionary
- `supportedLocales` should match the locales you pass to `AnasLocalization`

## Next

- [Preview Dictionaries and Loaders](preview-and-loaders.md)
- [Migration and Locale Issues](../troubleshooting/migration-and-locale.md)
