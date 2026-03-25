# Data Model: Typed Dictionary Generation Sync

This plan models how `anas_localization` produces `dictionary.dart` from translation JSON assets, and what must remain consistent between runtime lookup and the generated typed API.

## Entities
1. `Locale`
   - Value: locale code string (for example `en`, `tr`, `ar`)

2. `TranslationFile`
   - Fields:
     - `locale` (Locale)
     - `sourceKind` (either `packageDefault` or `appOverride`)
     - `json` (Map<String, dynamic>)
     - `path` (filesystem path to `<locale>.json`)

3. `MergedLocaleData`
   - Fields:
     - `locale` (Locale)
     - `merged` (Map<String, dynamic>)
   - Merge rule:
     - `merged = packageDefaultJson + appOverrideJson` (app overrides win)

4. `FlattenedKeyset`
   - Fields:
     - `keys`: dotted key paths representing navigable string templates
   - Derived by flattening nested maps (plurals/select maps are treated as generatable endpoints)

5. `AccessorSpec`
   - Fields:
     - `dartIdentifier` (getter/method name after sanitization + collision handling)
     - `keyPath` (dotted key path used for lookup at runtime)
     - `kind`:
       - `rootGetter` (flat string key)
       - `parameterizedGetter` (template with `{param}` markers)
       - `pluralMethod` (count-based plural forms)
       - `genderAwarePluralMethod` (male/female forms)
       - `moduleSurface` (namespaced APIs when `--modules` is enabled)
     - `parameters` (placeholder list inferred from template markers)

6. `GeneratedDictionaryArtifact`
   - Fields:
     - `outputPath` (e.g. `example/lib/generated/dictionary.dart`)
     - `rootSurface` (root getters + methods)
     - `moduleSurfaces` (optional namespaced classes)

## State Transitions
1. Discover supported locales from:
   - explicit `SUPPORTED_LOCALES` env var, else
   - JSON filenames in configured lang dirs
2. Load per-locale JSON maps:
   - load package defaults
   - load app overrides (if present) using the chosen candidate precedence
3. Merge maps into `MergedLocaleData`
4. Validate keyset equality and placeholder consistency across locales
5. Generate `AccessorSpec` set
6. Emit `dictionary.dart` at the configured output path

## Invariants required by this feature
- The app override input precedence must produce the same merged keyset that the example app expects.
- Generated accessors must follow the same dotted-key lookup semantics as runtime lookup mode.
- Existing runtime lookup tests remain valid and unchanged.

