# Migration Guide: `easy_localization` → `anas_localization`

This guide helps move from `easy_localization` with minimal downtime.

## Typical Starting Point

You currently have:
- `EasyLocalization(...)` wrapping app root
- locale files in `assets/translations` (JSON/CSV/YAML)
- lookups via `.tr()` and plural/context helpers

Target:
- `AnasLocalization(...)` wrapper
- JSON locale files in `assets/lang`
- generated typed dictionary APIs

## Step 1: Normalize locale source files to JSON

If you are already using JSON, copy them to `assets/lang`.

If not, use export/import with CLI:

```bash
dart run anas_localization:anas_cli export assets/translations json translations_export.json
dart run anas_localization:anas_cli import translations_export.json assets/lang
```

## Step 2: Configure supported locales explicitly

Replace implicit setup with explicit locale declaration:

```dart
AnasLocalization(
  fallbackLocale: const Locale('en'),
  assetPath: 'assets/lang',
  assetLocales: const [Locale('en'), Locale('ar'), Locale('tr')],
  app: const MyApp(),
)
```

## Step 3: Generate dictionary API

```bash
dart run anas_localization:localization_gen
```

Optional for large projects:

```bash
dart run anas_localization:localization_gen --modules --module-depth=2
```

## Step 4: Replace translation calls incrementally

Old:

```dart
'home.title'.tr()
'cart.items'.plural(itemCount)
```

New:

```dart
context.dict.homeTitle
context.dict.cartItems(count: itemCount)
```

For temporary compatibility, keep old keys and migrate page-by-page.

## Step 5: Replace locale switching

Old:

```dart
context.setLocale(const Locale('ar'));
```

New:

```dart
await AnasLocalization.of(context).setLocale(const Locale('ar'));
```

## Compatibility Notes

- Plural maps are supported (`one`, `other`, etc.).
- Gender-aware forms (`male`, `female`) are supported.
- Locale fallback chain is deterministic (`lang_script_region → ... → fallback`).
- You can keep existing translator workflow via ARB bridge if needed.

## Rollback Plan

If rollback is required:

1. Keep old `EasyLocalization` wrapper branch ready.
2. Keep original translation directory untouched.
3. Revert lookup refactor commits (typed dictionary usages).
4. Restore `.tr()` callsites and locale setter usage.

## Validation Checklist

```bash
flutter analyze
flutter test
dart run anas_localization:anas_cli validate assets/lang --profile=balanced
```

For CI strictness:

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings
```
