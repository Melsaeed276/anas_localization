# Before and After Examples

Use this page when you want concrete examples of how common migration targets change.

## easy_localization

Before:

```dart
Text('home.title'.tr())
```

After:

```dart
final dict = getDictionary();
Text(dict.homeTitle)
```

## gen_l10n

Before:

```dart
Text(AppLocalizations.of(context)!.welcomeTitle)
```

After:

```dart
final dict = getDictionary();
Text(dict.welcomeTitle)
```

## Locale switching

Before:

```dart
context.setLocale(const Locale('ar'));
```

After:

```dart
await AnasLocalization.of(context).setLocale(const Locale('ar'));
```

## Next

- [Migration Strategy](migration-strategy.md)
- [Validate a Migration](validate-a-migration.md)
