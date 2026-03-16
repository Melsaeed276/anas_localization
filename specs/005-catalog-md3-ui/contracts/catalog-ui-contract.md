# Contract: Catalog UI Behavior and Guarantees

## Purpose

Define the behavior contract that the Catalog UI must satisfy for design stability, Material Design 3 compliance, feature exposure, accessibility, responsiveness, and error/multi-tab handling. This contract is used to verify implementation and tests against the feature spec.

## Design System Contract

- The Catalog MUST use Material Design 3: `ThemeData.useMaterial3: true`, theme color roles (e.g. `ColorScheme`), and typography from the design system.
- The Catalog MUST use MD3 component patterns for buttons, fields, cards, navigation, and dialogs so that appearance and behavior are consistent.
- **Button UX priorities**: Buttons MUST use visual emphasis that matches importance: primary action per screen/section = highest emphasis (filled); secondary actions = medium (tonal/outlined); tertiary = lowest (text). Prefer one primary button per section or dialog.
- The Catalog MUST meet the design system’s accessibility requirements (contrast, touch targets, semantics) for the main flows (list, select, edit, save).

## Feature Exposure Contract

- **Data types**: The Catalog MUST allow the user to select an optional data type per entry (string, numerical, gender, date, date and time) and MUST provide type-appropriate value inputs (text field, number field, gender options, date picker, date-time picker).
- **Entry variants**: The Catalog MUST expose plural forms, gender variants, and regional overrides for view and edit where the underlying localization model supports them.
- **Validation**: The Catalog MUST show (1) an inline summary or indicator for the current entry’s validation issues, and (2) a dedicated list or panel with all validation messages; many messages MAY be grouped or paginated.
- **RTL**: The Catalog MUST support right-to-left layout and text direction when the active locale or content requires RTL.
- **Language configuration**: The Catalog MUST expose language configuration so users can view and edit the set of languages/locales in the project and language-specific settings: list of locales and add/remove; Arabic configuration (e.g. RTL, plural categories, gender); English configuration (e.g. base and regional variants, default time format per region); and other languages’ locale list and supported options, so that the Catalog is the single place to manage which languages the project supports and how they behave.
- **Add new key**: The Catalog MUST require the default language string when adding a new key and MUST offer one input per other enabled locale (optional). The default language is the fallbackLocale configured at package initialization (e.g. in main); the Catalog uses it and may display it but does not set it. The Catalog MUST show a warning for any locale left empty. At runtime, missing locale values fall back to the default language. When the user submits a key that already exists in the source, the Catalog MUST warn and offer the choice to overwrite the existing entry or cancel (form data retained if they cancel). Optional data type or variants may be set in the same flow or when editing later.
- **Add new language**: The Catalog MUST allow adding a new localization language by selecting from a list of languages the package supports; the list MUST include at least Arabic and English (grammar rules defined); when a language is added, it becomes an enabled locale and appears in the Catalog for content entry and editing.

## Responsiveness Contract

- The Catalog MUST adapt to viewport widths down to 360px so that core tasks (list, select, edit, save) remain usable without horizontal scroll blocking critical controls.
- Layout and navigation MUST remain consistent across sessions and after updates (no regressions in core flows).

## Performance Contract

- With up to approximately 5,000 entries, the entry list and search MUST remain responsive (e.g. via list virtualization or equivalent); core tasks MUST NOT be blocked by list size.

## Error and Session Contract

- **Save failure**: When save fails, the Catalog MUST show an error message and MUST keep the current form data so the user can fix and save again.
- **Load failure**: When load fails, the Catalog MUST show an error and MUST retain any already-loaded state where applicable.
- **Multi-tab**: When the same localization source is edited in multiple tabs or sessions (same user, same machine), the Catalog MUST behave in a defined way (e.g. last save wins or prompt to reload) so that data integrity is preserved and the user is not left with silently overwritten or corrupted data.

## Accessibility Contract

- Primary actions and content MUST be reachable and activatable via keyboard with logical focus order.
- Controls and content MUST be exposed to assistive technologies with appropriate labels and structure so that screen reader users can complete core tasks.

## Consistency Contract

- The Catalog MUST present a consistent visual and interaction model so that layout, typography, and controls do not change unexpectedly between sessions or after updates.

## Implementability and Editability Contract

- The Catalog UI MUST be easy to implement and easy to edit: use the design system’s standard components and tokens so that styling and behavior are consistent and changes are localized; maintain a clear structure (e.g. list, detail, edit, configuration) so that new or changed features fit without duplicate or tangled logic; and avoid unnecessary complexity so that changing copy, layout, or a single control does not require large refactors.
