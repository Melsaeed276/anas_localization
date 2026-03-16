# Research: English Localization Alignment

## Decision 1: Use a shared base `en` file with regional override files

**Decision**: Keep `assets/lang/en.json` as the shared English source of truth and add regional override files using the repo's normalized locale naming convention: `en_US.json`, `en_GB.json`, `en_CA.json`, and `en_AU.json`.

**Rationale**:
- The clarified spec requires one shared base `en` locale plus layered regional overrides.
- The runtime and validator already prefer `en` as the canonical base locale, so this aligns with current architecture instead of fighting it.
- The locale service already normalizes locale codes into language/script/region variants, which fits underscore-based file names.
- This keeps duplication low because only region-specific spelling, selected vocabulary, and formatting-sensitive entries need to differ.

**Alternatives considered**:
- Make `en_US` the base locale: rejected because the spec explicitly chose shared `en` as the common source of truth.
- Store separate full files for every English region with no shared base: rejected because it increases duplication and weakens consistency across regions.
- Add an English-specific merge mechanism outside the normal locale fallback chain: rejected because it adds complexity and risks violating deterministic locale behavior.

## Decision 2: Make the plural-count contract `num`-aware across runtime and generated APIs

**Decision**: Treat plural `count` as `num` for runtime resolution and generated dictionary APIs. English uses singular only when `count.abs() == 1`; all other values, including `0`, `1.5`, and `-2`, use plural.

**Rationale**:
- The clarified spec explicitly requires decimal and negative-count behavior.
- Current runtime and generated APIs assume `int`, which cannot express decimal inputs without coercion or data loss.
- A single `num`-aware contract keeps generated APIs and raw-key resolution aligned, satisfying the constitution's dual-access requirement.
- The English rule remains simple while preserving Arabic and other locale-specific logic in the same plural engine.

**Alternatives considered**:
- Keep `int` everywhere and reject decimals: rejected because it contradicts the approved spec.
- Parse only strings and continue collapsing unsupported values to `0`: rejected because it produces incorrect behavior for valid numeric inputs.
- Add an English-only helper outside the shared plural engine: rejected because it would fragment runtime behavior and complicate maintenance.

## Decision 3: Keep `en` as the canonical validation and generation reference locale

**Decision**: Continue using `en` as the reference locale for validation and code generation while making plural validation and optional `_type == 'plural'` warnings locale-aware so English one/other maps are valid.

**Rationale**:
- The validator and generator already prefer `en` when it exists, so preserving that convention minimizes migration risk.
- English should not inherit Arabic's six-form plural expectations, especially for optional warnings or generated helper assumptions.
- Keeping `en` canonical ensures the generated dictionary API reflects shared English content first, with regional files treated as targeted overrides rather than independent roots.

**Alternatives considered**:
- Validate English region files as if they were full standalone locales: rejected because the feature is intentionally based on shared `en` plus overrides.
- Force every locale marked `_type: plural` to satisfy Arabic's six-form set: rejected because it breaks English correctness and over-applies Arabic-specific behavior.
- Use the first locale file alphabetically as the generator reference: rejected because it is less deterministic and weaker than the current explicit English preference.

## Decision 4: Preserve the existing deterministic locale fallback model

**Decision**: Keep locale normalization and fallback in the existing `LocalizationService`/`LocalizationManager` path and validate that regional English files behave predictably when only some override assets are present.

**Rationale**:
- The constitution requires deterministic locale behavior across platforms.
- The current locale tests already cover same-language fallback and normalization for compound locales.
- This feature only needs to tighten English behavior, not redesign locale resolution.

**Alternatives considered**:
- Introduce special-case fallback just for English regions: rejected because it creates a second resolution model.
- Make missing regional override files an error condition: rejected because the spec expects reuse of shared `en` content whenever no override exists.
