# Migration Guide: Flutter `gen_l10n` → `anas_localization`

This guide migrates a project that currently uses:
- `l10n.yaml`
- ARB files (for example `lib/l10n/app_en.arb`)
- generated `AppLocalizations`

to:
- JSON locale files (`assets/lang/*.json`)
- generated typed dictionary (`lib/generated/dictionary.dart`)
- runtime wrapper (`AnasLocalization`)

## Prerequisites

- Existing app compiles with current `gen_l10n` setup.
- You have `l10n.yaml` committed.
- You can run Flutter/Dart CLI from the app root.

## Step 1: Import ARB into JSON

Import directly using your current `l10n.yaml`:

```bash
dart run anas_localization:anas_cli import l10n.yaml assets/lang
```

This reads:
- `arb-dir`
- `template-arb-file`
- `preferred-supported-locales` (if present)

Then writes:
- `assets/lang/en.json`
- `assets/lang/ar.json`
- etc.

## Step 2: Validate translations

Run validation before code generation:

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=balanced
```

For CI:

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings
```

## Step 3: Generate typed dictionary API

```bash
dart run anas_localization:localization_gen
```

Optional development watch mode:

```bash
dart run anas_localization:localization_gen --watch
```

## Step 4: Replace app bootstrap

Old:

```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
)
```

New:

```dart
AnasLocalization(
  fallbackLocale: const Locale('en'),
  assetPath: 'assets/lang',
  assetLocales: const [Locale('en'), Locale('ar')],
  app: MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      DictionaryLocalizationsDelegate(),
    ],
    supportedLocales: const [Locale('en'), Locale('ar')],
  ),
)
```

## Step 5: Replace lookups incrementally

Old:

```dart
AppLocalizations.of(context)!.welcomeTitle
```

New:

```dart
context.dict.welcomeTitle
```

You can migrate screen-by-screen. Both systems can temporarily coexist during the transition window.

## Compatibility Notes

- ARB metadata (`@key`, `@@locale`) is preserved by ARB import/export utilities.
- Existing translator ARB workflow can stay active:

```bash
dart run anas_localization:anas_cli export assets/lang arb lib/l10n
```

- Nested keys from ARB (`home.title`) are converted into JSON nested maps.

## Rollback Plan

If migration must be reverted:

1. Keep your original ARB folder untouched (`lib/l10n`).
2. Re-enable `gen_l10n` delegates and generated class usage.
3. Remove `AnasLocalization` wrapper and `DictionaryLocalizationsDelegate`.
4. Remove generated dictionary file and related imports.

Because ARB files remain the source of truth during migration, rollback is low-risk.

## Verification Checklist

- `flutter analyze`
- `flutter test`
- `dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings`
- Smoke-test locale switching on device/simulator
