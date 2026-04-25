# Research: Fix Dictionary Sync

## Problem
The example app’s generated typed dictionary (`example/lib/generated/dictionary.dart`) is missing typed accessors expected by `example/lib/main.dart` and other example code (for example keys such as `localizationDemo`, `basicDemo`, etc.). This creates `undefined_getter`/`undefined_method` analyzer errors and breaks the developer workflow.

## Root cause (confirmed from generator implementation)
When `bin/generate_dictionary.dart` runs from the package root, it loads JSON data using:
- `pkg`: `assets/lang/<locale>.json` (package defaults)
- `app override candidates`: a list (`appLangDirs`) that currently includes
  1. `Platform.environment['APP_LANG_DIR'] ?? 'assets/lang'`
  2. `example/assets/lang`
- It then uses `_loadFirstJson(...)`, which returns the first candidate file that successfully loads.

Because `assets/lang/<locale>.json` exists, the override lookup often stops at the package defaults (candidate #1) and never reaches `example/assets/lang/<locale>.json`. As a result, the merged locale data only contains package default keys, and the generated dictionary output lacks example-specific keys.

## Decision
Update the generator’s override input precedence so that, when `APP_LANG_DIR` is not explicitly provided, `example/assets/lang/<locale>.json` is preferred over `assets/lang/<locale>.json` for app overrides during dictionary generation from the package root.

Concretely:
- Reorder/compute `appLangDirs` such that default override candidates are checked in an order that prefers `example/assets/lang` first.
- Keep the rest of the generation pipeline (merge, keyset validation, accessor generation) unchanged.

## Rationale
- Fixes the mismatch without requiring developers to set environment variables.
- Prevents the example app and its generated typed API from diverging again.
- Maintains deterministic behavior: same input files -> same generated output.

## Alternatives considered
1. Require `APP_LANG_DIR=example/assets/lang` in docs/scripts.
   - Rejected: increases friction and still allows incorrect developer setups to silently generate stale outputs.
2. Make the generator derive override paths relative to the resolved app root.
   - Considered, but rejected for now in favor of a simpler precedence fix that matches current directory expectations and unblocks the sync immediately.
3. Copy example keys into package defaults.
   - Rejected: pollutes package defaults and breaks the separation between example overrides and package base translations.

## What must be true after the fix (validation hooks)
- Regenerating the typed dictionary should produce `example/lib/generated/dictionary.dart` containing typed accessors used by the example app.
- Analyzer should no longer report missing typed accessors for example code.
- Runtime key lookup behavior remains unchanged (covered by existing runtime-lookup tests).

