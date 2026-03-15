# Contract: Message Resolution API (Arabic support)

**Feature**: 002-arabic-localization-support  
**Consumers**: App code using type-safe dictionary or raw-key access; same behavior for both (Constitution I).

## Purpose

Define the observable behavior of message resolution when Arabic (or other locale with plural/gender/variant/formality) is active: inputs, outputs, fallback order, and context overrides.

## Inputs

- **key**: String (message key or path).
- **context**: UserContext (locale, gender, formality, regionalVariant). Defaults: gender = male, variant = MSA when not set.
- **overrides**: Optional per-call overrides for any of locale, gender, formality, variant (optional; when provided, override context for this call only).
- **params**: Optional map of placeholder name → value (e.g. count, name) for substitution.
- **stringType**: Optional hint (e.g. plural, numeric, date) when the key is typed; used for warnings when a required form is missing; does not change fallback result.

## Outputs

- **Resolved string**: A non-null string suitable for display. Never raw key or blank unless key is the intended fallback per spec.
- **Warnings** (tooling only): If key has an optional string type and a required form for that type is missing, CLI or Catalog UI MAY emit a warning (e.g. "key X, type plural, should have 'many' configured"). The resolved string is still the fallback value.

## Behavior

1. **Context**: Effective context = app-level default context merged with per-call overrides (overrides win).
2. **Lookup**: Resolve form from key using effective context: locale, plural form (if count provided), gender, formality, variant. Exact form first.
3. **Fallback order** (within same key): plural form → other; gender → other; variant → MSA; formality → single form if only one exists. Then base language or key.
4. **Async**: If asset for the requested locale is not yet loaded, resolve from in-memory data (e.g. fallback locale or key); do not block. When asset loads, notify listeners so UI can refresh.
5. **Determinism**: Same (key, context, params) → same result on all platforms.

## Out of scope (first release)

- Configurable fallback chain.
- Custom fallback policy per app.
