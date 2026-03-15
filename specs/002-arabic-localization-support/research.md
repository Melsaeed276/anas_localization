# Research: Arabic Language Localization Support

**Feature**: 002-arabic-localization-support  
**Plan**: [plan.md](plan.md) | **Spec**: [spec.md](spec.md)

Consolidated findings for Phase 0. All Technical Context items are resolved; no NEEDS CLARIFICATION remaining.

---

## 1. Arabic plural categories (CLDR alignment)

**Decision**: Use CLDR’s six categories (zero, one, two, few, many, other) with modulo-based rules for few/many.

**Rationale**: Unicode CLDR and ICU use: zero (n=0), one (n=1), two (n=2), few (n % 100 in 3..10), many (n % 100 in 11..99), other (everything else). This matches Arabic grammar (e.g. 103 uses “few”, 115 uses “many”). The package’s `PluralRules._getArabicPluralForm` currently uses fixed ranges (3–10, 11–99); that is wrong for 100+ (e.g. 103 should be few, 115 many).

**Alternatives considered**: Keeping current fixed ranges — rejected because they disagree with CLDR and give wrong forms for n ≥ 100.

**Action**: Update `PluralRules._getArabicPluralForm` to use `n % 100` for few/many (and keep zero/one/two/other as now).

---

## 2. Eastern vs Western Arabic numerals

**Decision**: Rely on Flutter’s `intl` and locale (e.g. `ar_SA`, `ar_MA`) to choose Eastern vs Western numerals and separators; no custom numeral substitution layer.

**Rationale**: For `ar_SA`, `NumberFormat` and `DateFormat` in Dart’s `intl` use Eastern Arabic digits and Arabic decimal/thousands separators when the locale is set. Locales like `ar_MA` can use Western digits. Use full locale (language + region) so region drives numeral system and separators.

**Alternatives considered**: Custom digit mapping — rejected to avoid duplicating intl/CLDR behavior and to keep one source of truth.

**Action**: Ensure resolution and formatting use full `Locale` (e.g. `ar_SA`, `ar_EG`, `ar_MA`) and pass it through to `NumberFormat`/`DateFormat`; document supported regions in quickstart/docs.

---

## 3. RTL and bidirectional text in Flutter

**Decision**: Keep using `Directionality` and `AnasTextDirection`; ensure `Localizations.localeOf(context)` (or app-level locale) drives direction so that when Arabic is active, layout is RTL. Rely on Flutter’s bidi for mixed LTR segments (URLs, numbers) inside RTL text.

**Rationale**: Flutter’s `Directionality` and the framework’s bidi handling are sufficient for RTL UI and inline LTR. No extra bidi library required for the spec’s “mixed content without breaking layout” requirement.

**Alternatives considered**: Adding a dedicated bidi/Unicode Bidi package — rejected as unnecessary for current scope.

**Action**: Document that apps must wrap the app (or Arabic screens) in a widget that sets `Directionality` from locale (e.g. `AnasDirectionalityWrapper`); ensure Catalog and example do this when locale is Arabic.

---

## 4. User context (locale, gender, formality, regional variant)

**Decision**: Single app-level default context (locale, gender, formality, regional variant) with optional per-call overrides (e.g. per screen or per `t()`/resolution call).

**Rationale**: Spec requires “app-level default with optional overrides”. Implement a mutable or provider-backed “current context” (locale + gender + formality + variant) used by resolution; allow callers to pass overrides for that call only so one API serves both global and ad-hoc needs.

**Alternatives considered**: Purely per-call context — rejected because spec asks for app-level default. No overrides — rejected because spec allows overrides per screen/resolution.

**Action**: Define a “user context” or “resolution context” type (locale, gender, formality, variant); inject it at app level; add optional parameters to resolution API for overrides; default gender = male when unset; default variant = MSA when unset.

---

## 5. Regional variants (MSA, Gulf, Egyptian) and formality in assets

**Decision**: Model variants and formality as optional dimensions in the asset structure (e.g. key + variant + formality in ARB/JSON or nested keys) and resolve with a defined fallback (e.g. requested variant → MSA → base/key). No separate asset file per variant; one structure that can hold variant/formality-specific strings.

**Rationale**: Keeps a single asset set while supporting “where translations exist” for dialects and formal/informal. Fallback order (variant → MSA, formality → neutral or single form) is spec-compliant and avoids file explosion.

**Alternatives considered**: One file per variant (e.g. ar_SA, ar_EG) — rejected in favor of one locale family with optional variant/formality in the structure so we don’t multiply files. Full dialect-only files — rejected; MSA is the required base.

**Action**: In data-model and contracts, define how keys can carry variant and formality (e.g. suffixes, nested keys, or ARB metadata); implement resolution that prefers requested variant/formality then falls back to MSA / neutral / key.

---

## 6. Optional string type per key and warnings

**Decision**: Support an optional “string type” (e.g. numeric, date, plural) on a key. Use it to (1) guide fallback when a form is missing and (2) emit targeted warnings in CLI and Catalog UI (e.g. “key X, type plural, should have ‘many’ configured”). Resolved value for the user is always the fallback chain result; warnings are tooling-only.

**Rationale**: Spec (FR-012, FR-017) requires fallback to a valid message and optional warnings in CLI/Catalog when a key has a type and a required form is missing. Type is optional so existing keys stay unchanged.

**Alternatives considered**: Warnings only in Catalog — rejected because spec says “CLI or Catalog UI”. Making type required — rejected; spec says optional.

**Action**: Add optional `type` (or equivalent) to the translation entry model and to asset format (ARB/JSON) where applicable; in validation/CLI and Catalog, if type is set and a required form for that type is missing, log or show the specified warning; resolution logic uses only the fallback chain (no blocking).

---

## 7. Async loading: fallback then refresh

**Decision**: When a translation is requested and the asset is not yet loaded, resolve immediately using the fallback chain and do not block. When the asset finishes loading, trigger a rebuild/refresh so the UI shows the newly loaded translation where applicable.

**Rationale**: Spec (FR-019): “resolve immediately using the fallback chain and MUST NOT block”; “when the asset finishes loading, the system MUST rebuild or refresh the displayed text.” So: synchronous resolution from whatever is in memory (including fallback), plus a notification/stream or `ChangeNotifier` when new assets load so that widgets depending on that locale rebuild.

**Alternatives considered**: Blocking until load — rejected by spec. No refresh after load — rejected by spec.

**Action**: Ensure loader/registry notifies listeners when a locale’s asset is loaded; app-level localization state (e.g. `AnasLocalization` or equivalent) subscribes and triggers rebuild (e.g. `notifyListeners` or equivalent) so visible messages update.

---

## 8. Canonical fallback order

**Decision**: Implement exactly the spec order: within same key try alternate form (plural → other, gender → other, variant → MSA), then base language or key. Gender default when unset is male.

**Rationale**: Spec (FR-012) and clarifications require a single canonical order and male default. No configurable fallback chain in first release.

**Action**: Document this order in contracts and data-model; implement resolution in one place (shared between type-safe and raw-key access) so behavior is deterministic and consistent.

---

## 9. Honorifics and titles

**Decision**: Support a small set of known titles (e.g. Dr., Mr., Mrs., Engineer) with Arabic masculine/feminine forms (e.g. الدكتور/الدكتورة); for unknown titles, fall back to name-only or a generic label.

**Rationale**: Spec (FR-011, User Story 7) asks for title + name in Arabic with correct gender form and a safe fallback. A fixed table is sufficient for “first release” and keeps scope bounded.

**Alternatives considered**: Full translation key per title — acceptable but can be implemented as a small table keyed by title + gender. No honorifics — rejected by spec.

**Action**: Add a small honorific/title map (title → male/female Arabic string) and a resolution function (title + gender → string); use name-only or generic when title is unknown.

---

## 10. Search and sort (Arabic)

**Decision**: Use locale-aware collation for sort (e.g. `Intl`/collation or platform) when locale is Arabic; for search, normalize equivalent character forms (e.g. hamza variants) and optionally ignore diacritics so matches are predictable. Implementation can be in the package or documented for app use.

**Rationale**: Spec (FR-013, User Story 9) requires Arabic alphabetical order and search normalization. Flutter’s `intl` and platform APIs provide collation; character normalization is standard (NFC/NFD or custom map for hamza).

**Alternatives considered**: No package support, app-only — acceptable if we document the requirement and point to intl/collation; prefer providing a small helper (e.g. normalize for search, sort key for Arabic) in the package for consistency.

**Action**: In data-model/contracts, define “Arabic sort” and “search normalization” as optional helpers; implement or delegate to intl/collation and document in quickstart.

---

## Summary table

| Topic | Decision | Key action |
|-------|----------|------------|
| Arabic plurals | CLDR 6 forms; few/many by n % 100 | Update `PluralRules` for Arabic |
| Numerals | Use intl + full locale (ar_SA, ar_MA, …) | Pass full Locale to formatters; document regions |
| RTL/bidi | Directionality + framework bidi | Document Directionality wrapper usage |
| User context | App-level default + per-call overrides | Add context type and override parameters |
| Variants/formality | Optional in asset structure; fallback variant→MSA | Define key structure; implement resolution |
| String type | Optional; warnings in CLI and Catalog | Add type to model; validation + UI warnings |
| Async load | Fallback immediately; refresh on load | Notify on load; trigger rebuild |
| Fallback order | Fixed order; male default | Single resolution path; document order |
| Honorifics | Small table + fallback | Title map + resolver |
| Search/sort | Locale-aware sort + search normalization | Helper or docs + intl/collation |
