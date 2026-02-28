# Migration from Flutter `gen_l10n`

This guide helps you move an existing ARB-based setup to `anas_localization` while preserving translation content.

## 1) Keep your existing ARB files

If you already have `lib/l10n/*.arb` and a `l10n.yaml`, you can import directly:

```bash
dart run anas_localization:anas_cli import l10n.yaml assets/lang
```

This reads:

- `arb-dir`
- `template-arb-file`
- `preferred-supported-locales` (when present)

and writes locale JSON files into `assets/lang`.

## 2) Generate your dictionary API

```bash
dart run anas_localization:localization_gen
```

Use watch mode during migration:

```bash
dart run anas_localization:localization_gen --watch
```

## 3) Wrap your app

Wrap `MaterialApp` (or root widget) with `AnasLocalization` and declare locales:

```dart
AnasLocalization(
  assetLocales: const [Locale('en'), Locale('ar')],
  fallbackLocale: const Locale('en'),
  app: MaterialApp(...),
)
```

## 4) Optional: export back to ARB

To share updates with ARB-based workflows:

```bash
dart run anas_localization:anas_cli export assets/lang arb lib/l10n
```

## Notes

- ARB metadata keys (`@key`, `@@locale`) are supported in import/export utilities.
- Keep locale keys consistent across files to avoid validation errors.
- Run `dart run anas_localization:anas_cli validate assets/lang` before shipping.
