# Feature Specification: Catalog UI Design and Stability

**Feature Branch**: `005-catalog-md3-ui`  
**Created**: 2026-03-15  
**Status**: Draft  
**Input**: User description: "update the Catalog UI Design and make it stable, the UI will use Material Design 3 and Flutter MD3 design system. also add the new features that we created by specs."

## Clarifications

### Session 2026-03-15

- Q: What order of magnitude should the Catalog support for number of entries (e.g. hundreds, thousands, tens of thousands)? → A: Up to ~5,000 entries – medium projects; list and search must stay responsive at that scale.
- Q: When save or load fails, how should the Catalog behave? → A: Show error message in the Catalog and keep data in the form (user can fix and save again).
- Q: Is the Catalog used by a single user at a time (one machine, one process), or can multiple users or sessions edit the same localization source? → A: Single user, multiple tabs or sessions possible (same user, same machine).
- Q: What is the smallest viewport width the Catalog must support without horizontal scroll blocking core tasks? → A: 360px – minimum width; typical small phone.
- Q: Where should validation/warning messages appear for entries? → A: Both – inline summary or indicator for the current entry; dedicated list or panel for all validation messages.
- Q: When the user adds a new key that already exists (same key path in the same source), what should happen? → A: Warn and let the user choose: overwrite existing or cancel.
- Q: When adding a new key, must every enabled locale have a value or can some be empty? → A: The user MUST provide the default language string; other supported languages are optional but the Catalog shows a warning that the user should add them. If the user does not add a string for another language, the system falls back to the default language value for that locale.
- Q: How is the default language determined or configured? → A: The default language is the one the user configures when initializing the package (e.g. in main) as fallbackLocale. The Catalog uses that value for add-new-key (required default string) and for fallback when a locale has no value; the Catalog may display it in language configuration but does not set it there.
- Q: When should edits be persisted—autosave or explicit save? → A: Manual save only (on Save button press; no autosave).
- Q: How should the Catalog display while the entry list or search is loading? → A: Skeleton placeholders that mimic the list/search layout.
- Q: Should the Catalog UI itself be translatable (e.g. Arabic/English)? → A: Yes. The Catalog supports the languages provided in the project’s locale assets (e.g. assets/lang), and the user can select one of them to view the Catalog UI (labels, buttons, messages) so developers feel comfortable with the tool.
- Q: What should list search/filter match against—keys only, or keys and values? → A: Keys and values; search also includes notes so users can find entries by key, translation text, or note content.
- Q: Can each key (entry) have a note? → A: Yes. Each key can have a note so the user can write details or keep notes related to that key; the Catalog exposes note view and edit for each entry.
- Q: What should the Catalog show when there are no entries (empty list)? → A: Quick actions (e.g. add key, add new language) and a slogan related to the package to motivate users.
- Q: How should the Catalog layout work when it opens? → A: Show the key list with a Quickstart or actions panel next to it (e.g. add key, add new language, slogan); when the user selects a key from the list, the detail area shows that key’s details (edit form, values, note, etc.).
- Q: When the same source is open in two tabs and one saves, what happens in the other tab? → A: When the file is detected as changed (e.g. after save from another tab), show a prompt with the option to reload so the user is not left with stale data without notice.
- Q: After saving a new key (or changes to keys), should the dictionary model be updated? → A: Yes. After a successful save, the new key (or updated keys) MUST be reflected in the generated dictionary model so the type-safe API includes it.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consistent, Stable Catalog Experience (Priority: P1)

As a person managing localization content, I use a Catalog interface that looks and behaves consistently, follows a clear visual hierarchy and interaction model, and does not change unexpectedly between sessions or after updates so I can work efficiently and trust the tool.

**Why this priority**: Stability and visual consistency are the foundation; without them, users cannot rely on the Catalog for daily work.

**Independent Test**: Use the Catalog across multiple sessions and after typical updates; verify layout, navigation, and controls remain consistent and that no regressions occur in core flows (view entries, edit, save).

**Acceptance Scenarios**:

1. **Given** the Catalog is open, **When** the user views the main screen, **Then** they see the key list with a detail area next to it showing a Quickstart or actions panel (e.g. add key, add new language, slogan); when they select a key from the list, the detail area shows that key’s details.
2. **Given** the Catalog is open, **When** the user navigates between sections, **Then** layout, typography, and controls follow a single design system so the experience feels unified.
3. **Given** the Catalog has been updated, **When** the user returns to the same task, **Then** existing workflows (e.g. list, filter, edit entry) still work as before without broken or missing controls.
4. **Given** the user performs a primary task (e.g. edit an entry and save), **When** the action completes, **Then** feedback is clear and the state is predictable (e.g. saved state visible, no duplicate or missing content).

---

### User Story 2 - Catalog Surfaces All Specified Localization Features (Priority: P1)

As a person managing localization, I can use the Catalog to access and operate all capabilities described in the package feature set: optional data type per entry with type-appropriate inputs, support for Arabic and English localization behavior (e.g. plurals, regional variants, RTL where applicable), and validation or warnings so the Catalog is the single place to manage content that matches the rest of the system.

**Why this priority**: The Catalog must reflect the features from the other specifications; otherwise users must use other tools or work around missing UI.

**Independent Test**: For each major capability (data type selection and type-specific inputs, plural/gender/regional variants where applicable, validation messages), confirm the Catalog exposes the option or result and that behavior matches the corresponding feature specification.

**Acceptance Scenarios**:

1. **Given** the user is creating or editing an entry, **When** they choose a data type (e.g. string, numerical, gender, date, date and time), **Then** the value input adapts to that type (e.g. number field, gender options, date or date-time picker) as specified for the optional data type feature.
2. **Given** entries support plural or gender variants or regional overrides, **When** the user views or edits such an entry in the Catalog, **Then** they can see and edit the relevant variants (e.g. plural forms, gender, regional overrides) where the underlying feature supports them.
3. **Given** validation or warnings are defined for missing or inconsistent data (e.g. type-based or locale-based), **When** the Catalog displays or validates entries, **Then** the current entry shows an inline summary or indicator, and a dedicated list or panel shows all validation messages so the user can fix issues without leaving the Catalog.
4. **Given** the package supports right-to-left layout for certain locales, **When** the user uses the Catalog in a context where RTL is relevant, **Then** the Catalog layout and text direction support RTL so content is readable and usable.
5. **Given** the user wants to manage which languages and locales are in the project, **When** they open language configuration in the Catalog, **Then** they can view the list of configured languages/locales and change language-specific settings (e.g. Arabic: RTL, plural forms, gender; English: base and regional variants, time format; other languages: locale list and any supported options) so that the Catalog is the single place to configure localization for the project.
6. **Given** the user wants to add a new translation key, **When** they use the add-new-key flow in the Catalog, **Then** they MUST enter the key and the default language string; they may enter values for other supported languages (one input per enabled locale), and the Catalog shows a warning for any locale left empty that the user should add a translation. If a locale has no value, the system falls back to the default language value for that key.
7. **Given** the user wants to add a new localization language to the project, **When** they use the add-language flow in the Catalog, **Then** they can select from a list of languages that the localization package supports (at least Arabic and English, for which grammar rules are defined) so that the chosen language is added to the project’s enabled locales and appears in the Catalog for editing.
8. **Given** the user is viewing or editing an entry, **When** they want to add or edit a note for that key, **Then** they can view and edit an optional note (details or notes related to that key); the note is stored with the entry and is included in list search and filter.
9. **Given** the entry list is empty, **When** the user opens the Catalog, **Then** they see a clear empty state with quick actions (e.g. add key, add new language) and a package-related slogan or message to motivate them.

---

### User Story 3 - Accessible and Responsive Catalog (Priority: P2)

As a person using the Catalog on different devices or with assistive technologies, I can complete core tasks regardless of screen size or input method, and critical controls and content meet accessibility expectations so the Catalog is usable for everyone in supported environments.

**Why this priority**: Accessibility and responsiveness ensure the Catalog works in real-world conditions (small screens, keyboards, screen readers) and align with the chosen design system goals.

**Independent Test**: Resize the Catalog or use it on a smaller viewport and with keyboard or screen reader; verify primary tasks (open list, select entry, edit and save) are completable and that focus order and labels are sensible.

**Acceptance Scenarios**:

1. **Given** the user has a narrow or small viewport, **When** they open the Catalog, **Then** content and controls adapt so that list, detail, and edit flows remain usable without horizontal scrolling or overlapping critical controls.
2. **Given** the user relies on keyboard navigation, **When** they move through the Catalog, **Then** focus order is logical and all primary actions can be reached and activated via keyboard.
3. **Given** the user relies on a screen reader, **When** they navigate the Catalog, **Then** controls and content have appropriate labels and structure so that key actions and content are announced and operable.

---

### User Story 4 - Design System Compliance for Trust and Maintainability (Priority: P2)

As a product owner or maintainer, the Catalog UI adheres to a defined design system (Material Design 3) so that visual style, components, and patterns are consistent with the rest of the product and with documented design and accessibility guidelines, making the UI easier to maintain and extend.

**Why this priority**: Design system adherence supports long-term stability, reduces one-off styling, and aligns with the chosen standard for hierarchy, utility, and style.

**Independent Test**: Review the Catalog against the designated design system guidelines (e.g. color roles, typography, spacing, component patterns, accessibility) and confirm that the UI conforms for the main screens and components.

**Acceptance Scenarios**:

1. **Given** the design system defines color roles and typography, **When** the user views the Catalog, **Then** colors and text styles follow those roles so hierarchy and readability match the system.
2. **Given** the design system defines standard components (e.g. buttons, fields, cards, navigation), **When** the Catalog uses those components, **Then** they match the system’s patterns so behavior and appearance are consistent.
3. **Given** the design system includes accessibility requirements, **When** the Catalog is evaluated against those requirements, **Then** the Catalog meets the specified level (e.g. contrast, touch targets, semantics) for the main flows.
4. **Given** a screen or dialog has multiple actions, **When** the user views it, **Then** the most important action (e.g. Save) uses the highest button emphasis (primary), secondary actions use medium emphasis, and tertiary actions use the lowest emphasis, so that the primary action is visually clear.

---

### User Story 5 - Easy to Implement and Edit (Priority: P2)

As a developer building or maintaining the Catalog, the UI is structured so that it is straightforward to implement and to edit later: screens and components follow a small set of clear patterns, reuse the design system so that changes to style or behavior are localized, and avoid unnecessary complexity so that adding or changing a screen or control does not require large refactors.

**Why this priority**: Easy-to-implement and easy-to-edit UI reduces cost and risk when building the Catalog and when evolving it (e.g. new features, fixes, or design tweaks).

**Independent Test**: Review the Catalog’s structure and patterns; confirm that screens are composed from a consistent set of building blocks, that layout and styling are driven by the design system rather than one-off code, and that a representative change (e.g. add a button, change a label, or adjust a layout) can be made in a localized way without rewriting unrelated parts.

**Acceptance Scenarios**:

1. **Given** the Catalog uses the design system’s standard components and themes, **When** a developer implements or edits a screen, **Then** they can rely on shared components and tokens so that implementation and edits are localized and predictable.
2. **Given** the Catalog has a clear structure (e.g. list, detail, edit, configuration), **When** a developer adds or changes a feature, **Then** the change fits into that structure without introducing duplicate or tangled logic.
3. **Given** a developer needs to change copy, layout, or a single control, **When** they make the change, **Then** the impact is limited to the relevant screen or component so that the UI remains easy to edit over time.

---

### Edge Cases

- When the entry list is empty, the Catalog shows an empty state with quick actions (e.g. add key, add new language) and a package-related slogan or message to motivate users.
- When the Catalog opens, the key list is shown with a detail area next to it; the detail area shows Quickstart/actions when no key is selected and shows the selected key’s details when the user selects a key from the list.
- When the Catalog is used with up to approximately 5,000 entries, list and search remain responsive and do not block core tasks.
- When the user switches locale or regional variant, the Catalog reflects the change (e.g. RTL/LTR, regional overrides) without requiring a full restart.
- When validation produces many warnings, the dedicated list or panel presents them in a manageable way (e.g. grouped or paginated) so the user can act on them; the current entry still shows its inline summary or indicator.
- When a data type is changed on an existing entry, the value input updates to the new type and existing value is handled safely (e.g. clear or convert where defined).
- When the Catalog is opened on a new platform or window size for the first time, the layout adapts correctly and no critical controls are off-screen or unreachable.
- When the entry list or search is loading, the Catalog shows skeleton placeholders that mimic the list/search layout until content is ready.
- When save fails (e.g. disk error, permission, or validation blocking write), the Catalog shows an error message and keeps the form data so the user can correct and save again. When load fails, the Catalog shows an error and retains any already-loaded state where applicable.
- When the same localization source is open in multiple tabs or sessions and the file is changed (e.g. saved from another tab), the Catalog detects the change and shows a prompt with the option to reload so the user is not left with stale data without notice; if they save without reloading, last save wins.
- When the user changes language configuration (e.g. adds or removes a locale, or changes a language-specific setting), the Catalog reflects the change (e.g. entry list or validation scope, RTL switch) without requiring a full restart where possible; any validation or warnings that depend on the configuration are updated accordingly.
- When the user adds a new key, the default language string is required; other locales may be left empty, in which case the Catalog shows a warning that the user should add them and the runtime falls back to the default language value for missing locales. Optional data type or variants (e.g. plural, gender) may be set in the same flow or later when editing the entry.
- When the user adds a new language from the supported list, the new locale appears in the enabled set and in the add-new-key form so that values can be entered for it; if the language has grammar rules (e.g. Arabic, English), the Catalog applies them for that language.
- When the user submits a new key that already exists in the source, the Catalog warns and lets the user choose: overwrite the existing entry or cancel (keep form data so they can change the key and try again).
- When the user changes the Catalog UI display language (selected from the project’s supported languages, e.g. assets/lang), the Catalog interface (labels, buttons, messages) updates to the selected language without requiring a full restart where possible.
- When the user searches or filters the entry list, matches include entries where the key path, any translation value (per locale), or notes contain the search text, so that search covers keys, values, and notes.
- When the user adds or edits a note on an entry, the note is stored with the key and can be viewed or edited later; notes are optional and allow the user to keep details or notes related to that key.
- After a successful save that adds or changes keys, the dictionary model (generated code) is regenerated so the new or updated keys are available in the type-safe dictionary API.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Catalog UI MUST present a consistent visual and interaction model so that layout, typography, and controls do not change unexpectedly between sessions or after updates.
- **FR-002**: The Catalog UI MUST follow the designated design system (Material Design 3) for visual hierarchy, components, spacing, and patterns so that the Catalog aligns with the product’s design and accessibility standards.
- **FR-003**: The Catalog MUST allow users to select an optional data type per entry (e.g. string, numerical, gender, date, date and time) and MUST provide type-appropriate value inputs (e.g. number field, gender options, date or date-time picker, text field) as specified by the optional data type feature.
- **FR-004**: The Catalog MUST expose entry variants required by other features (e.g. plural forms, gender variants, regional overrides) so users can view and edit them where the underlying localization model supports them.
- **FR-005**: The Catalog MUST display validation or warning messages in two ways: an inline summary or indicator for the current entry, and a dedicated list or panel showing all validation messages, so users can correct issues from within the Catalog.
- **FR-006**: The Catalog MUST support right-to-left layout when the active locale or content requires RTL so that text and layout direction are correct for supported languages.
- **FR-007**: The Catalog MUST adapt to viewport widths down to 360px so that core tasks (list, select, edit, save) remain usable without horizontal scroll blocking critical controls.
- **FR-008**: The Catalog MUST support keyboard navigation so that primary actions and content can be reached and activated via keyboard.
- **FR-009**: The Catalog MUST expose controls and content to assistive technologies with appropriate labels and structure so that screen reader users can complete core tasks.
- **FR-010**: The Catalog MUST use the design system’s color roles and typography so that hierarchy and readability meet the designated standard.
- **FR-011**: The Catalog MUST use standard components and patterns from the design system so that behavior and appearance are consistent and maintainable.
- **FR-012**: The Catalog MUST meet the design system’s accessibility requirements (e.g. contrast, touch targets, semantics) for the main Catalog flows.
- **FR-013**: When save or load fails, the Catalog MUST show an error message and MUST keep the current form data (for save failure) so the user can fix and save again; on load failure, retain any already-loaded state where applicable.
- **FR-014**: The Catalog MUST persist changes to the localization source only when the user explicitly triggers save (e.g. Save button); the Catalog does not autosave edits.
- **FR-015**: When the same localization source is edited in multiple tabs or sessions (same user, same machine), the Catalog MUST detect when the file has changed (e.g. after a save from another tab) and MUST show a prompt offering the user the option to reload so that they are not left with stale data without notice. If the user does not reload and saves, last save wins; the prompt ensures the user can choose to reload before overwriting.
- **FR-016**: Buttons in the Catalog MUST use visual emphasis that matches their importance: the single most important action per screen or section (e.g. Save, Confirm) MUST use the highest emphasis (primary); secondary actions (e.g. Cancel, Add variant, Reload) MUST use medium emphasis; tertiary or low-priority actions (e.g. Help, minor options) MUST use the lowest emphasis, so that users can quickly identify the primary action.
- **FR-017**: The Catalog MUST expose language configuration so that users can view and edit the set of languages/locales in the project and language-specific settings. At least the following MUST be configurable from the Catalog (where the underlying localization model supports them): (1) list of supported languages/locales and ability to add or remove locales; (2) Arabic configuration (e.g. RTL, plural categories, gender); (3) English configuration (e.g. base locale and regional variants such as en-US, en-GB, en-CA, en-AU, and default time format per region); (4) other languages’ locale list and any supported options so that the Catalog is the single place to manage which languages the project supports and how they behave.
- **FR-018**: The Catalog UI MUST be designed so that it is easy to implement and easy to edit: use the design system’s standard components and tokens so that styling and behavior are consistent and changes are localized; keep a clear structure (key list + detail area that shows Quickstart/actions when nothing is selected and key details when a key is selected; edit and configuration as needed) so that new or changed features fit without duplicate or tangled logic; and avoid unnecessary complexity so that changing copy, layout, or a single control does not require large refactors.
- **FR-019**: The Catalog MUST allow users to add a new translation key with the default language string required and one input per other enabled locale. The user MUST provide the default language string; values for other locales are optional. The Catalog MUST show a warning for any enabled locale that has no value, indicating that the user should add a translation. At runtime, when a locale has no value for a key, the system falls back to the default language value. Optional data type or variants may be set in the same flow or when editing the entry later. When the key already exists in the source, the Catalog MUST warn and offer the user the choice to overwrite the existing entry or cancel (form data retained if they cancel).
- **FR-020**: The Catalog MUST allow users to add a new localization language to the project by selecting from a list of languages that the localization package supports.
- **FR-021**: While the entry list or search results are loading, the Catalog MUST display skeleton placeholders that mimic the list or search layout so the user sees a loading state rather than a blank or static screen.
- **FR-022**: The Catalog MUST allow the user to select the display language for the Catalog UI from the project’s supported languages (e.g. from assets/lang or the project’s locale assets). Labels, buttons, and messages in the Catalog UI MUST be shown in the selected language so developers can use the Catalog in a language they are comfortable with.
- **FR-023**: List search and filter in the Catalog MUST match against key path, translation values (per locale where applicable), and notes. Users MUST be able to find entries by key, by value text in any locale, or by note content so that search covers keys, values, and notes.
- **FR-024**: The Catalog MUST allow the user to view and edit an optional note per entry (per key). Each key can have one note so the user can write details or keep notes related to that key; the note is stored with the entry and is included in search and filter.
- **FR-025**: When the entry list is empty, the Catalog MUST show a clear empty state that includes quick actions (e.g. add key, add new language) and a slogan or short message related to the package to motivate users.
- **FR-026**: When the Catalog opens, it MUST show the key list with a detail area next to it. The detail area MUST show a Quickstart or actions panel (e.g. add key, add new language, package slogan) when no key is selected; when the user selects a key from the list, the detail area MUST show that key’s details (edit form, values, note, variants, etc.) so that list and detail work as a master–detail layout.
- **FR-027**: After a successful save that adds or changes keys in the localization source, the package MUST regenerate the dictionary model (generated code) so that the new or updated keys are available in the type-safe dictionary API. The Catalog or the package workflow (e.g. Catalog triggers codegen after save, or user runs codegen via CLI) MUST ensure the dictionary model reflects the saved keys.

### Button UX priorities

Buttons MUST be prioritized by importance and rendered with the corresponding design-system emphasis:

| Priority | Use for | Visual treatment (MD3) |
|----------|--------|------------------------|
| **Primary** | One main action per screen/section (e.g. Save entry, Confirm dialog, Submit) | Highest emphasis (filled/primary) |
| **Secondary** | Supporting actions (e.g. Cancel, Add variant, Reload, Back) | Medium emphasis (tonal or outlined) |
| **Tertiary** | Low-priority or optional actions (e.g. Help, secondary options, dismiss) | Lowest emphasis (text) |

Only one primary button SHOULD appear per logical section or dialog so that the main action is unambiguous.

### Key Entities

- **Catalog UI**: The user interface used to view, create, and edit localization entries and to see validation or warnings; it must be stable, consistent, and aligned with the design system.
- **Localization entry**: A single translatable item (key and one or more values/variants) that may have an optional data type, an optional note per key (for details or notes related to that key), and may support plurals, gender, or regional overrides as defined in other specifications. The default language value is required when creating a new key; other locales may be empty and fall back to the default at runtime. The user can view and edit the note in the Catalog; list search and filter match against key path, values, and notes.
- **Data type**: An optional classification for an entry (e.g. string, numerical, gender, date, date and time) that drives input controls and validation in the Catalog.
- **Design system**: The chosen visual and interaction standard (Material Design 3) used to ensure consistency, accessibility, and maintainability of the Catalog and the product.
- **Language configuration**: The set of languages and locales enabled for the project and their language-specific settings (e.g. Arabic: RTL, plural forms, gender; English: base and regional variants, time format; other languages: locale list and supported options). The Catalog exposes this so users can view and edit it without leaving the Catalog.
- **Supported language list**: The list of languages that the localization package supports and that users can add to the project from the Catalog. At least Arabic and English are included (grammar rules defined); the list is extended as the package adds support for more languages.
- **Default language**: The locale configured by the user when initializing the package (e.g. in main) as fallbackLocale. The Catalog uses this as the required default when adding a new key and as the fallback when a locale has no value for a key. The Catalog may display it in language configuration but does not set it there; it is defined at package initialization.
- **Catalog UI display language**: The language in which the Catalog interface itself (labels, buttons, messages) is shown. The user can select it from the project’s supported languages (e.g. from assets/lang); this allows developers to use the Catalog in a language they are comfortable with.

## Assumptions

- The behaviors and data models for localization (e.g. plurals, gender, regional variants, data types, validation) are defined in other specifications; this specification focuses on the Catalog UI’s design, stability, and exposure of those features.
- Material Design 3 is the designated design system for the product; the Catalog will follow its guidelines for components, color, typography, spacing, and accessibility.
- “Stable” means no regressions in core Catalog workflows (list, view, edit, save) and consistent appearance and behavior across sessions and after updates.
- Supported viewports and platforms are those already in scope for the product; the Catalog need not support every possible device but must adapt within that scope. The minimum viewport width the Catalog must support is 360px (typical small phone); at that width and above, core tasks must not be blocked by horizontal scrolling.
- Validation and warning rules are defined elsewhere; the Catalog only displays them and does not define the rules.
- The Catalog is designed to remain responsive for up to approximately 5,000 entries; list and search behavior (e.g. virtualization or pagination) shall support that scale.
- The Catalog may be used with multiple tabs or sessions by the same user on the same machine; when the file is changed (e.g. saved from another tab), the Catalog shows a reload prompt so the user can choose to reload; if they do not reload and save, last save wins.
- The Catalog does not autosave; changes are persisted only when the user explicitly triggers save (e.g. Save button).
- The Catalog UI (labels, buttons, messages) is translatable; the user can select one of the project’s supported languages (e.g. from assets/lang) to view the Catalog in that language, so developers feel comfortable with the tool.
- The Catalog UI is intended to be easy to implement and easy to edit: following the design system and a clear screen structure keeps implementation and future changes localized and predictable.
- The supported language list (languages that can be added to the project from the Catalog) includes at least Arabic and English in the first release; additional languages are added to the list as the package defines grammar rules or support for them.
- The default language is the fallbackLocale configured when the user initializes the package (e.g. in main). When adding a new key, the default language string is required. Other locale values are optional; missing values fall back to the default at runtime, and the Catalog shows a warning for empty locales. The Catalog uses and may display the default language but does not define it; it is set at package init.
- After a successful save that adds or changes keys, the dictionary model (generated code) is regenerated so the new or updated keys are available in the type-safe dictionary API; the Catalog or package workflow ensures this so that the generated API stays in sync with the saved localization source.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete the primary Catalog workflow (open list, select an entry, edit value or variants, save) in under two minutes for a typical entry without encountering layout or control regressions.
- **SC-002**: All capabilities required by the optional data type feature (data type selection and type-specific inputs) are available and usable in the Catalog for at least one entry per supported type.
- **SC-003**: At least one flow that uses plural, gender, or regional variants (as defined in the Arabic and English localization specs) can be performed entirely from the Catalog (view and edit) for a representative set of entries.
- **SC-004**: Validation or warning messages defined for entries appear in the Catalog for at least one representative scenario (e.g. missing plural form or type mismatch) so users can act on them without leaving the Catalog.
- **SC-005**: At 360px viewport width (minimum supported), users can complete the primary Catalog workflow without horizontal scrolling that blocks critical controls or content.
- **SC-006**: A reviewer can confirm that the Catalog’s main screens and components conform to the designated design system (color roles, typography, component patterns) with no more than a defined set of documented exceptions, if any.
- **SC-007**: The Catalog meets the design system’s stated accessibility level (e.g. contrast, touch targets, semantics) for the main flows when evaluated with the designated method or tool.
- **SC-008**: A reviewer can confirm that button emphasis matches importance (one primary per section/dialog, secondary and tertiary actions use lower emphasis) on the main Catalog screens and dialogs.
- **SC-009**: Users can open language configuration in the Catalog and view the list of configured languages/locales; for at least Arabic, English, and one other language (or locale), the relevant language-specific settings (e.g. Arabic RTL/plural/gender, English regional variant and time format, other locale options) are visible and editable so that the project’s localization set and behavior can be managed from the Catalog.
- **SC-010**: A developer can make a representative small change (e.g. add a button, change a label, or adjust a layout) in a localized way without rewriting unrelated parts; the Catalog’s structure and use of the design system support easy implementation and editing.
- **SC-011**: Users can add a new translation key from the Catalog; the default language string is required, and one input per other enabled locale is offered (optional). The Catalog shows a warning for any locale left empty. The new entry is created; missing locale values fall back to the default at runtime.
- **SC-012**: Users can add a new localization language to the project by selecting from a list in the Catalog; at least Arabic and English are available in the list; after selection, the language is added as an enabled locale and the user can enter or edit content for it (e.g. in add-new-key and entry editing).
- **SC-013**: Users can view and edit an optional note per entry (per key) in the Catalog; the note allows them to write details or keep notes related to that key, and note content is included in list search and filter.
- **SC-014**: When the entry list is empty, the Catalog shows an empty state with quick actions (e.g. add key, add new language) and a package-related slogan or message to motivate users.
- **SC-015**: When the Catalog opens, the key list is visible with a detail area next to it; the detail area shows a Quickstart or actions panel when no key is selected and shows the selected key’s details when the user selects a key from the list.
- **SC-016**: After a successful save that adds or changes keys, the dictionary model is regenerated so the new or updated keys are available in the generated type-safe API.
