# Quickstart: English Localization Alignment

## Goal

Add or update English localization data using a shared `en` base plus optional regional overrides, then validate and regenerate typed dictionary output.

## Prerequisites

- Dependencies installed for the package and example app
- Existing localization assets under `assets/lang/`
- The current feature spec and plan in `specs/004-update-english-localization/`

## Workflow

### 1. Add or update shared English content

Edit `assets/lang/en.json` so it contains the shared English source of truth.

Use explicit English plural entries when count-sensitive wording is needed:

```json
{
  "itemsCount": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

### 2. Add regional overrides only where needed

Create or update one or more regional files:

- `assets/lang/en_US.json`
- `assets/lang/en_GB.json`
- `assets/lang/en_CA.json`
- `assets/lang/en_AU.json`

Only include entries that differ from `en.json`.

Example:

```json
{
  "colorLabel": "Colour"
}
```

### 3. Keep English scope limited

- Do not add Arabic-only plural forms to English entries.
- Do not add regional tone-only variants in first release.
- Keep irregular plurals, uncountables, articles, and contractions authored directly in the string values.

### 4. Validate localization assets

Run:

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings
```

Expected result:

- `en` is treated as the validation base
- Regional English files are accepted as targeted overrides
- Placeholder and key mismatches still fail validation

### 5. Regenerate typed dictionary output

Run:

```bash
dart run anas_localization:localization_gen --modules
```

If example-app assets are part of the workflow, regenerate and inspect `example/lib/generated/dictionary.dart` as part of the same change.

### 6. Run package verification

Run:

```bash
flutter analyze
flutter test
```

## Success Checks

- Runtime can resolve `en`, `en_US`, `en_GB`, `en_CA`, and `en_AU` deterministically.
- English pluralized messages behave correctly for `0`, `1`, `2`, `-1`, `-2`, and decimal counts.
- Generated dictionary helpers and raw-key lookup produce the same English result for the same input.
