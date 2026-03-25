# Feature Specification: Hierarchical Locale Fallback System with Custom Locale Support

**Feature Branch**: `006-locale-hierarchical-fallback`  
**Created**: 2026-03-24  
**Status**: Draft  
**Input**: User description: "Hierarchical locale fallback system with custom locale support - adding new locale design is not bad but let's have a new logic: 1. for each language that has many branches like English or arabic we can have a general locale for it. and user can set a default fallback to that. for example if we have arabic-eg and arabic-sa and global arabic is setted to arabic-eg then if there is no string in arabic-sa it will fallback to arabic-eg and if there is no string in arabic-eg then it will fallback to the default fallback of the localization. the default global locale will be visible only if the user selected more than one locale of the same locale. also add the ability to let the user enter his own locale by entering the locale code and subcode (like en-us) and also let the user enter if this RTL or LTR and LTR is the default of it."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Configure Language Group Fallback for Regional Variants (Priority: P1)

A translator managing Arabic localization for a multi-region app adds `ar_EG` (Arabic - Egypt) and `ar_SA` (Arabic - Saudi Arabia). They want shared Arabic strings to be maintained in one place (`ar_EG`) so that `ar_SA` automatically inherits common translations and only defines region-specific overrides.

**Why this priority**: This is the core feature that reduces translation duplication and maintenance burden. Without this, users cannot establish fallback relationships between regional variants, forcing them to duplicate common translations across all regional locales.

**Independent Test**: Can be fully tested by creating two or more regional locales of the same language (e.g., `en_US`, `en_GB`, `en_AU`), setting one as the language group fallback, removing a translation from one regional variant, and verifying the translation is retrieved from the designated fallback locale.

**Acceptance Scenarios**:

1. **Given** a project with `ar_EG` and `ar_SA` locales, **When** user sets `ar_EG` as the language group fallback for Arabic, **Then** any translation missing in `ar_SA` is automatically retrieved from `ar_EG`
2. **Given** `ar_EG` is set as the Arabic language group fallback, **When** a translation is missing in both `ar_SA` and `ar_EG`, **Then** the system falls back to the project's default fallback locale (e.g., `en`)
3. **Given** a project with only one Arabic locale (`ar_EG`), **When** user views locale settings, **Then** no language group fallback option is shown (it only appears when 2+ regional variants exist)
4. **Given** three regional Arabic variants (`ar_EG`, `ar_SA`, `ar_AE`), **When** user changes the language group fallback from `ar_EG` to `ar_SA`, **Then** all Arabic regional variants now use `ar_SA` as their first fallback
5. **Given** a language group fallback is configured, **When** user removes the fallback configuration, **Then** regional variants revert to falling back directly to the project default

---

### User Story 2 - Add Custom Locale with Manual Text Direction (Priority: P2)

A translator needs to add support for a locale not in the predefined list (e.g., `fr_CA` for French Canadian, or a custom dialect code). They want to manually enter the locale code and specify whether it uses right-to-left (RTL) or left-to-right (LTR) text direction.

**Why this priority**: Essential for internationalization completeness but can function independently after P1. Users can work with predefined locales while this feature is being built, but it's required for full flexibility.

**Independent Test**: Can be tested by entering a valid locale code (e.g., `es_MX`), selecting LTR direction, and verifying the locale is created with the correct direction setting. The system should validate ISO 639-1/639-2 language codes and ISO 3166-1 country codes.

**Acceptance Scenarios**:

1. **Given** user opens the "Add Locale" dialog, **When** they select "Enter Custom Code", **Then** they see input fields for locale code and direction (LTR/RTL radio buttons with LTR as default)
2. **Given** user enters a valid locale code `es_MX` and selects LTR, **When** they submit, **Then** the locale is created with LTR direction and appears in the locale list as "Spanish (Mexico)"
3. **Given** user enters an invalid locale code `xyz_ABC`, **When** they attempt to submit, **Then** the system shows a validation error: "Invalid language code 'xyz'. Please use ISO 639-1 or 639-2 language codes."
4. **Given** user enters a valid language code but invalid country code `en_ZZ`, **When** they attempt to submit, **Then** the system shows a validation error: "Invalid country code 'ZZ'. Please use ISO 3166-1 alpha-2 country codes."
5. **Given** user enters a locale code that already exists, **When** they attempt to submit, **Then** the system shows an error: "Locale 'es_MX' already exists."
6. **Given** user creates a custom RTL locale `ur_PK`, **When** viewing translations for that locale, **Then** the text input fields display RTL text direction

---

### User Story 3 - Visualize Fallback Chain and Language Groups (Priority: P3)

A project manager reviewing the localization setup wants to understand the fallback relationships at a glance. They need to see which locales are grouped by language, which locale serves as the group fallback, and the complete fallback chain for each locale.

**Why this priority**: This enhances usability and understanding but doesn't block core functionality. Users can configure fallbacks without visualization, though it makes the system more maintainable.

**Independent Test**: Can be tested by configuring a language group fallback (e.g., setting `en_US` as fallback for English), then viewing the locale list and verifying visual indicators show: language group badge, fallback arrows, and tooltips displaying the complete fallback chain.

**Acceptance Scenarios**:

1. **Given** a project with `ar`, `ar_EG`, `ar_SA` where `ar_EG` is the language group fallback, **When** user views the locale list, **Then** locales are grouped under "Arabic" with `ar_EG` marked as "Global Fallback for Arabic"
2. **Given** `ar_SA` has `ar_EG` as its language group fallback, **When** user hovers over `ar_SA`, **Then** a tooltip shows the fallback chain: "ar_SA → ar_EG → en (default)"
3. **Given** multiple language groups exist (Arabic, English, Spanish), **When** user views the locale list, **Then** each language group is visually distinct with expandable/collapsible sections
4. **Given** a custom locale `fr_CA` has been added, **When** user views the locale list, **Then** it shows a "Custom" badge to distinguish it from predefined locales
5. **Given** no language group fallback is configured for Spanish variants, **When** user views `es_MX`, **Then** the fallback chain shows: "es_MX → en (default)" without intermediate steps

---

### Edge Cases

- What happens when a user tries to set a regional variant (e.g., `ar_EG`) as the fallback for the base language locale (e.g., `ar`)? System should prevent this and show error: "Cannot set a regional variant as fallback for a base language."
- What happens when a user deletes the locale that is designated as the language group fallback? System should clear all language group fallback references to that locale and notify the user: "Deleted locale 'ar_EG' was the language group fallback for Arabic. Other Arabic locales now fall back directly to the default locale."
- What happens when a user tries to create a custom locale with only a language code (e.g., `fr`) when predefined locales already exist? System should allow it and treat it as a base language locale that can serve as a language group fallback.
- What happens when a user enters a locale code with hyphen instead of underscore (e.g., `en-US` instead of `en_US`)? System should automatically normalize to underscore format (`en_US`) as per internal convention.
- What happens when the language group fallback locale is missing a translation, and the regional variant is also missing it? System should fall back to the project's default fallback locale (e.g., `en`).
- What happens when a circular fallback is attempted (e.g., `ar_EG` → `ar_SA` → `ar_EG`)? System should detect circular references during configuration and prevent saving with error: "Circular fallback detected. Please choose a different fallback locale."

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to designate one locale as the language group fallback for all regional variants of the same language (e.g., set `ar_EG` as fallback for all `ar_*` locales)
- **FR-002**: System MUST only display language group fallback options when a project contains 2 or more locales sharing the same base language code
- **FR-003**: System MUST store language group fallback preferences in the catalog state file (`.anas_localization/catalog_state.json`) with the structure: `languageGroupFallbacks: {"ar_SA": "ar_EG", "ar_AE": "ar_EG"}`
- **FR-004**: System MUST resolve missing translations using this priority order: (1) Exact locale match, (2) Language group fallback if configured, (3) Project default fallback locale
- **FR-005**: System MUST allow users to enter custom locale codes via a text input field in the "Add Locale" dialog
- **FR-006**: System MUST validate custom locale codes against ISO 639-1/639-2 language codes and ISO 3166-1 alpha-2 country codes with strict validation
- **FR-007**: System MUST provide radio button selection for text direction (LTR or RTL) when adding custom locales, with LTR as the default selection
- **FR-008**: System MUST normalize locale code input by converting hyphens to underscores (e.g., `en-US` → `en_US`)
- **FR-009**: System MUST display validation feedback in real-time as users type custom locale codes, showing format errors before submission
- **FR-010**: System MUST prevent users from setting a regional variant as the language group fallback for a base language locale
- **FR-011**: System MUST automatically clear language group fallback references when the designated fallback locale is deleted, and notify affected locales
- **FR-012**: System MUST detect and prevent circular fallback chains during configuration
- **FR-013**: System MUST group locales by base language code in the UI when 2+ regional variants exist, with visual grouping (expandable sections)
- **FR-014**: System MUST display language group fallback indicators (e.g., "Global Fallback for Arabic" badge) next to the designated fallback locale
- **FR-015**: System MUST show fallback chain tooltips on hover, displaying the complete resolution path (e.g., "ar_SA → ar_EG → en")
- **FR-016**: System MUST mark custom locales with a visual badge ("Custom") to distinguish them from predefined locales
- **FR-017**: System MUST format locale display names using language and country names (e.g., `en_US` displays as "English (United States)")
- **FR-018**: System MUST store custom locale text direction preferences in the catalog state file with the structure: `customLocaleDirections: {"custom_locale": "rtl"}`
- **FR-019**: System MUST apply stored RTL/LTR direction to text input fields and display elements for the corresponding locale
- **FR-020**: System MUST preserve backward compatibility by allowing catalog state files without `languageGroupFallbacks` or `customLocaleDirections` fields to function normally

### Key Entities

- **Language Group Fallback Configuration**: Represents the mapping between a regional locale (e.g., `ar_SA`) and its designated language group fallback (e.g., `ar_EG`). Stored as a key-value pair in the catalog state. Key attribute: target locale code, fallback locale code.
- **Custom Locale**: Represents a user-defined locale not in the predefined list. Key attributes: locale code (language + optional country), text direction (LTR/RTL), validation status. Related to existing locale files and translation entries.
- **Locale Group**: Logical grouping of locales sharing the same base language code (e.g., all `ar_*` locales form the Arabic language group). Not persisted as a separate entity but derived dynamically from existing locale codes.
- **Fallback Chain**: The ordered sequence of locales used to resolve a missing translation. Derived dynamically based on language group fallback configuration and project default fallback. Example: `ar_SA → ar_EG → en`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can configure a language group fallback for a set of regional locales in under 1 minute through the UI
- **SC-002**: Translation resolution follows the configured fallback chain without requiring code changes or server restarts
- **SC-003**: Custom locale creation with valid codes completes successfully in under 30 seconds
- **SC-004**: System rejects 100% of invalid locale codes (incorrect language or country codes) during validation
- **SC-005**: Users can visually identify language groups, fallback relationships, and custom locales within 10 seconds of viewing the locale list
- **SC-006**: Fallback chain tooltips accurately display the complete resolution path for any locale
- **SC-007**: System prevents 100% of circular fallback configurations from being saved
- **SC-008**: Deletion of a language group fallback locale automatically updates all dependent fallback configurations without data loss
- **SC-009**: Existing projects without language group fallback configuration continue to function without errors or data migration requirements
- **SC-010**: RTL/LTR text direction setting for custom locales is correctly applied to all text input and display elements for that locale
