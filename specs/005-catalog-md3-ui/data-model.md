# Data Model: Catalog UI Design and Stability

## Overview

This feature focuses on the Catalog UI’s presentation and behavior. The data model describes UI state and display entities that the Catalog needs to satisfy the spec: stable layout, MD3 theming, data-type–driven inputs, entry variants, validation display, RTL, error handling, multi-tab behavior, and language configuration (Arabic, English, and other languages). Underlying localization entities (keys, values, plurals, gender, regional overrides) are defined in other specs; here we model only what the UI must hold and show.

## Entities

### CatalogThemeState

Represents the active theme and design system configuration for the Catalog UI.

**Fields**
- `useMaterial3`: Whether Material 3 is enabled (must be true per spec).
- `colorScheme`: Resolved ColorScheme (light/dark) from seed or palette.
- `textTheme`: Resolved TextTheme for hierarchy and readability.
- `brightness`: Light or dark mode.

**Relationships**
- Single instance applied to the Catalog app; drives all MD3 color roles and typography.

**Validation rules**
- Must satisfy design system (MD3) color roles and typography so that FR-002, FR-010, FR-011, FR-012 can be verified.

### CatalogViewportState

Represents the current viewport and layout mode for responsive behavior.

**Fields**
- `width`: Current viewport width in logical pixels.
- `height`: Current viewport height in logical pixels.
- `isCompact`: True when width is at or above minimum supported (360px) but below a medium breakpoint if used.
- `isRTL`: Whether layout and text direction are right-to-left (from active locale or content).

**Relationships**
- Derived from MediaQuery and locale; used to choose layout and enforce 360px minimum (FR-007, SC-005).

**Validation rules**
- When width < 360px, core tasks may degrade gracefully but the design does not guarantee no horizontal scroll; at ≥ 360px, core workflow must be usable without horizontal scroll blocking controls.

### EntryFormState

Represents the current editing state of a single localization entry in the Catalog.

**Fields**
- `keyPath`: The translation key being edited.
- `dataType`: Optional data type (string, numerical, gender, date, dateTime); default string.
- `valueOrVariantMap`: Current value or map of variant keys to values (e.g. plural forms, gender, regional overrides).
- `dirty`: Whether the form has unsaved changes.
- `saveError`: Optional error message when last save failed (form data retained per FR-013).
- `validationSummary`: Inline summary or indicator for this entry (e.g. list of issue codes or short messages for FR-005 inline display).

**Relationships**
- One EntryFormState per open entry editor; may reference one LocalizationEntry from the domain layer.
- Validation summary is derived from validation results defined elsewhere; Catalog only displays it.

**Validation rules**
- When save fails, saveError must be set and form data retained. When data type changes, value input widget must update; existing value handling (clear or convert) is defined in implementation.

### ValidationPanelState

Represents the dedicated list or panel of all validation messages shown in the Catalog.

**Fields**
- `messages`: List of validation message items (entry key, message or code, severity if applicable).
- `groupedOrPaginated`: Whether messages are grouped (e.g. by entry or severity) or paginated when count is large.
- `selectedEntryKey`: Optional key of the entry to navigate to when user selects a message (for “jump to issue”).

**Relationships**
- Populated from the same validation source that feeds inline summaries; display-only (Catalog does not define validation rules).

**Validation rules**
- When there are many messages, presentation must be manageable (grouped or paginated) per edge case; current entry’s inline summary still shown separately.

### CatalogSessionState

Represents session-level state that affects save/load and multi-tab behavior.

**Fields**
- `loadError`: Optional error message when initial or refresh load failed; already-loaded state retained where applicable (FR-013).
- `sourceFilePath`: Path or identifier of the localization source being edited (for multi-tab detection).
- `lastSavedAt`: Timestamp of last successful save (for stale detection).
- `externalChangeDetected`: Whether the system has detected that the source file was modified externally (e.g. by another tab); used to show reload prompt while keeping last-save-wins behavior.

**Relationships**
- One per Catalog window/tab; used to implement FR-013 (save/load error, keep form data) and FR-014 (multi-tab defined behavior).

**Validation rules**
- On save failure: show error, keep form data. On load failure: show error, retain already-loaded state. On external change: show reload prompt; if user saves without reloading, last save wins.

### LanguageConfigurationState

Represents the language/locale configuration exposed in the Catalog for viewing and editing.

**Fields**
- `enabledLocales`: List of locale codes (e.g. en, en_US, ar, hi) that are enabled for the project.
- `supportedLanguagesForAdd`: List of languages that the package supports and that the user can add to the project from the Catalog (at least Arabic and English; list extended as the package adds grammar rules or support).
- `arabicSettings`: Optional Arabic-specific settings (e.g. RTL on/off, plural categories, gender) when Arabic is in scope; structure defined by Arabic localization spec.
- `englishSettings`: Optional English-specific settings (e.g. base locale, regional variants en_US/en_GB/en_CA/en_AU, default time format per region) when English is in scope; structure defined by English localization spec.
- `otherLanguageSettings`: Optional map or list of settings for other languages/locales (e.g. locale list, any supported options per language).
- `dirty`: Whether configuration has unsaved changes.

**Relationships**
- Backed by project or asset configuration; Catalog UI exposes it for view/edit per FR-016. Changes may affect validation scope, RTL, and entry list or variant visibility.

**Validation rules**
- Adding or removing a locale, or changing language-specific settings, must be reflected in the Catalog (e.g. validation, RTL, entry variants) without requiring full restart where possible; validation and warnings that depend on configuration update accordingly.
- The supported language list (languages that can be added to the project) includes at least Arabic and English; when a user adds a language from this list, it is appended to enabled locales and appears in add-new-key and entry editing.

**Add-new-key flow**: When the user adds a new key, the form MUST require the key and the default language string and MUST offer one input per other enabled locale (optional). The Catalog MUST show a warning for any enabled locale that has no value. The entry is created; missing locale values fall back to the default at runtime. Optional data type or variants may be set in the same flow or when editing later.

### LocalizationEntry (display)

Display-facing view of a single localization entry as shown in the list or editor. Structure aligns with existing catalog_models and shared data_type.

**Fields**
- `keyPath`: Dotted key.
- `dataType`: Optional DataType (string, numerical, gender, date, dateTime).
- `valueOrVariantMap`: Value or map of variant keys to values (plural, gender, regional).
- `status`: Optional cell/entry status (e.g. green, warning, red) from existing CatalogCellState if used.

**Relationships**
- Backed by domain/asset entities; Catalog UI only reads and writes through the existing repository and service layer.

**Validation rules**
- Data type and variant structure must match what other specs define (optional data type, Arabic/English plurals and gender, regional overrides); Catalog exposes them for view/edit and type-appropriate inputs.

## State Transitions

- **EntryFormState**: Idle → Dirty (user edits) → Saving → Idle (success) or Dirty + saveError (failure). On data type change, form switches to the new type’s input widget and handles existing value per implementation.
- **CatalogSessionState**: Loaded → LoadError (load failed) | Idle → ExternalChangeDetected (file changed on disk) → user Reload or Save (last save wins).
- **ValidationPanelState**: Messages update when validation runs; selection or navigation to an entry key is a UI action that does not change persistence.
- **LanguageConfigurationState**: Idle → Dirty (user edits locale list or language-specific settings) → Saving → Idle (success) or Dirty + error (failure). On apply, Catalog reflects change (e.g. RTL, validation scope, entry variants) where possible without full restart.
