# anas_localization features

This document lists what the package does and how to enable each capability. It is for both evaluators (decide fit quickly) and adopters (find and enable features by theme). For step-by-step setup, see [Get Started](../get-started/index.md) and [Setup and Guidelines](../get-started/setup-and-guidelines.md).

## Access modes

### Typed dictionary

**What it is / when to use it:** Type-safe generated dictionary APIs: your app gets a generated class with getters for each key so you get compile-time checks and IDE support. Use this when you want the default, recommended path and are fine running the code generator.

**How to enable:** Run the generator and use the generated dictionary with `AnasLocalization`. See [Generate and Wrap Your App](../get-started/generate-and-wrap.md) and [Setup and Guidelines](../get-started/setup-and-guidelines.md).

### Raw string keys

**What it is / when to use it:** Fast localization via raw string keys without generated code—same loading and fallback behavior as the typed path. Use this for quick iteration, simple apps, or when you prefer not to run codegen.

**How to enable:** Use the same runtime and asset setup as the typed path; access translations by key string instead of generated getters. See [Setup and Guidelines](../get-started/setup-and-guidelines.md) and [Read Translations](../use-in-app/read-translations.md).

---

## CLI and tooling

### Validation

**What it is / when to use it:** CLI checks for consistency and correctness of locale files (e.g. missing keys, format issues). Use it in CI or before commits to keep localizations deterministic.

**How to enable:** Run `dart run anas_localization:anas_cli validate <path>`. See [CLI Validate](../cli/validate.md) and [Setup and Guidelines](../get-started/setup-and-guidelines.md).

### Import and export (ARB / CSV / JSON)

**What it is / when to use it:** Convert between ARB, CSV, and JSON so you can edit in a spreadsheet or bridge with other tools, then import back into the project.

**How to enable:** Use `anas_cli` import/export commands. See [CLI Import and Export](../cli/import-export.md).

### Stats

**What it is / when to use it:** Summary counts and coverage for your locale files (e.g. key counts per locale, missing keys). Use it to spot gaps or report on progress.

**How to enable:** Use the CLI stats/profile options. See [CLI Common Workflows](../cli/common-workflows.md).

### Catalog workflows

**What it is / when to use it:** CLI commands to init and serve the Catalog sidecar UI and drive catalog-related automation.

**How to enable:** Run `dart run anas_localization:anas_cli catalog init` and `catalog serve`. See [CLI Catalog](../cli/catalog.md) and [Catalog Setup and Serve](../catalog/setup-and-serve.md).

---

## Locale and fallback

### Deterministic fallback chain

**What it is / when to use it:** Locale resolution follows a documented, deterministic order (e.g. `lang_script_region` → `lang_script` → `lang_region` → `lang` → fallback). Same inputs give the same result on every platform. Use it when you need predictable behavior across iOS, Android, web, and desktop.

**How to enable:** Use the default resolution or configure fallback locale; behavior is built in. See [Setup and Guidelines](../get-started/setup-and-guidelines.md) and [Locale Switching](../use-in-app/locale-switching.md).

### Platform support (iOS, Android, web, desktop)

**What it is / when to use it:** The same locale and fallback logic runs on all supported platforms; no platform-specific code paths for resolution.

**How to enable:** No extra step; use the package on your target platform. See [Get Started](../get-started/index.md).

### System locale

**What it is / when to use it:** Initial or default locale can be taken from the platform (system/device language). System locale is an input to resolution, not a different implementation per platform.

**How to enable:** Use the default behavior or set initial locale from platform; see [Locale Switching](../use-in-app/locale-switching.md).

---

## Arabic and RTL

### Arabic language support (RTL, plurals, gender, numerals, honorifics)

**What it is / when to use it:** Full Arabic localization: RTL layout, six plural forms (zero, one, two, few, many, other), gender and formality variants, regional variant (MSA, Gulf, Egyptian), Eastern/Western numerals by region, honorific resolution, and optional string-type warnings in CLI. Fallback order is canonical (plural→other, gender→other, variant→MSA, formality→key).

**How to enable:** Set app locale to an Arabic locale (e.g. `ar_SA`, `ar_EG`), wrap with `AnasDirectionalityWrapper`, configure `UserContext` (gender, formality, variant), and use `resolveMessage` or `Dictionary.resolve` for resolution. See [Setup and Guidelines](../get-started/setup-and-guidelines.md) and the [Arabic quickstart](https://github.com/Melsaeed276/anas_localization/blob/main/specs/002-arabic-localization-support/quickstart.md).

---

## Migration

### Migration from gen_l10n

**What it is / when to use it:** Documented path and tooling to move from Flutter’s `gen_l10n` to anas_localization with minimal breakage.

**How to enable:** Follow the migration guide and use the provided validation. See [Migrate from gen_l10n](../migrate/from-gen-l10n.md) and [Validate a Migration](../migrate/validate-a-migration.md).

### Migration from easy_localization

**What it is / when to use it:** Documented path and tooling to migrate from `easy_localization` to anas_localization.

**How to enable:** Follow the migration guide and validate. See [From easy_localization](../migrate/from-easy-localization.md) and [Validate a Migration](../migrate/validate-a-migration.md).

---

## Catalog

**In development.** The Catalog is a single-page sidecar UI for localization: add, edit, and update entries and configure them by type (including Arabic). You manage text without editing ARB/CSV/JSON/YAML by hand. It runs as a standalone app with autosave, explicit review completion, and structured editors for plural/gender and Arabic-specific options.

**What it is / when to use it:** Use the Catalog when you want a UI to manage translations and review status instead of editing files directly.

**How to enable:** Run `dart run anas_localization:anas_cli catalog init` then `catalog serve`. See [Catalog Overview](../catalog/index.md), [Setup and Serve](../catalog/setup-and-serve.md), and [Setup and Guidelines](../get-started/setup-and-guidelines.md).

---

## Platforms and system locale

### iOS, Android, web, desktop

**What it is / when to use it:** anas_localization targets all four platforms with the same APIs and locale behavior. Use it for cross-platform Flutter apps.

**How to enable:** Add the package and follow [Get Started](../get-started/index.md); no platform-specific setup for locale resolution.

### System-based language config

**What it is / when to use it:** Use the device or system language as the initial locale so the app matches the user’s OS language preference.

**How to enable:** Rely on default initial locale from the platform or set it explicitly; see [Locale Switching](../use-in-app/locale-switching.md).
