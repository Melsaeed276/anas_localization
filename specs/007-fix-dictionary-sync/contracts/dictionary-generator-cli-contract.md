# Contract: Dictionary Generator CLI (Typed `dictionary.dart`)

This contract documents the inputs/outputs and the key precedence rule that must not regress.

## Inputs
The generator (`bin/generate_dictionary.dart`, invoked via `anas_localization:localization_gen` / `anas update --gen`) uses:

1. `SUPPORTED_LOCALES` (optional)
   - Comma-separated list of locale codes (example: `en,tr,ar`)
   - Overrides auto-discovery from configured lang directories.

2. `APP_LANG_DIR` (optional)
   - Path to a directory containing `<locale>.json` files for app overrides.
   - If unset, the generator uses default candidate directories for overrides.

3. `OUTPUT_DART` (optional)
   - File path to write `dictionary.dart` to (primarily used by tests).

## Output
Writes a Dart source file containing:
- `class Dictionary` that extends the runtime base dictionary
- Typed accessors whose names are derived from translation key paths
- Getter/method semantics for parameterized templates, plurals, and (optionally) module surfaces

## Precedence rule (critical for this feature)
For app overrides, the generator must prefer `example/assets/lang/<locale>.json` over `assets/lang/<locale>.json` by default when generating the example app’s dictionary from the package root.

In other words:
- Base translation input always starts from `assets/lang/<locale>.json`
- App override input is loaded from a candidate list where `example/assets/lang` appears before package `assets/lang` as the “first match wins” candidate.

## Determinism & Validation
- Same set of input JSON files -> same generated `dictionary.dart`
- Missing locale files must fail with a non-zero exit code.
- Keyset/placeholder consistency across languages must be validated (generator already performs this check).

