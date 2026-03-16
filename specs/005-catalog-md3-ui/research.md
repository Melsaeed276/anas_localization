# Research: Catalog UI Design and Stability

## Decision 1: Apply Material Design 3 via Flutter ThemeData and useMaterial3

**Decision**: Use Flutter’s built-in Material 3 support: set `ThemeData.useMaterial3: true`, build `ColorScheme` (e.g. from `ColorScheme.fromSeed` or a tonal palette), and use `ThemeData` color roles, `TextTheme`, and component themes so the Catalog consistently uses MD3 hierarchy, spacing, and components.

**Rationale**:
- The spec designates Material Design 3 as the design system; Flutter’s Material 3 support is the standard path.
- Using theme tokens (e.g. `colorScheme.surfaceContainer`, `colorScheme.primary`) avoids hardcoded colors and keeps the Catalog maintainable and accessible.
- The Flutter MD3 design system skill and M3 documentation align on ThemeData, ColorScheme, and component patterns.

**Alternatives considered**:
- Custom design tokens outside ThemeData: rejected because it duplicates Flutter’s MD3 theming and increases maintenance.
- Staying on Material 2: rejected because the spec explicitly requires Material Design 3.

## Decision 2: Use list virtualization for entry list at scale (up to ~5,000 entries)

**Decision**: Render the Catalog entry list with a virtualized list (e.g. `ListView.builder` or equivalent) so that only visible items are built; support search/filter over the in-memory or loaded set so list and search remain responsive up to ~5,000 entries without loading all rows into the widget tree at once.

**Rationale**:
- The spec requires list and search to stay responsive at that scale; building thousands of list tiles without virtualization causes jank and memory pressure.
- Flutter’s standard approach for long lists is lazy building via `ListView.builder`; the existing Catalog can adopt or confirm this pattern.
- Pagination is an alternative but adds navigation complexity; virtualization keeps a single scrollable list and matches user expectations for a catalog.

**Alternatives considered**:
- Pagination (e.g. 100 entries per page): rejected for first iteration because it adds UI complexity and the spec does not require it; can be revisited if 5k proves insufficient.
- Load-all without virtualization: rejected because it does not meet the performance assumption for ~5,000 entries.

## Decision 3: Multi-tab/session: last save wins with optional stale-data prompt

**Decision**: Define multi-tab behavior as last-write-wins when the same file is saved from multiple tabs. Optionally, when the Catalog detects that the underlying file was modified on disk (e.g. by another tab or external edit), show a prompt to reload so the user is not left with stale or silently overwritten data; if the user dismisses without reloading, subsequent save still overwrites (last save wins).

**Rationale**:
- The spec requires a “defined way” and data integrity without silent corruption; last save wins is simple and deterministic.
- Detecting external file changes and offering reload improves UX when the same user has multiple tabs and avoids confusion from stale form state.
- Full merge or locking would add significant complexity and is out of scope for “single user, multiple tabs” on the same machine.

**Alternatives considered**:
- Strict locking (only one tab can edit): rejected because the spec allows multiple tabs/sessions for the same user.
- Automatic merge of concurrent edits: rejected because it requires conflict UI and merge rules beyond the current scope.

## Decision 4: Validation UI: inline indicator for current entry plus dedicated panel for all messages

**Decision**: Implement validation display in two places: (1) an inline summary or indicator (e.g. icon + short text or expandable line) next to or above the current entry’s form when that entry has validation issues, and (2) a dedicated list or panel (e.g. sidebar or bottom sheet) that lists all validation messages across entries, with grouping or pagination when there are many warnings so the user can act on them without leaving the Catalog.

**Rationale**:
- The clarified spec explicitly chose “both”: inline for current entry, dedicated list/panel for all messages.
- This balances context at point of edit (inline) with overview and navigation (panel).
- MD3 components (e.g. list tiles, chips, bottom sheet) can be used for the panel and inline indicator.

**Alternatives considered**:
- Inline only: rejected because the spec requires a dedicated list/panel for all messages.
- Panel only: rejected because the spec requires an inline summary/indicator for the current entry.

## Decision 5: Responsive breakpoint for minimum 360px using MediaQuery and layout variants

**Decision**: Use Flutter’s `MediaQuery` (and optionally `LayoutBuilder`) to adapt layout so that at viewport width ≥ 360px the core Catalog workflow (list, select, edit, save) is usable without horizontal scroll blocking critical controls. Use a single minimum-width breakpoint (360px) for “compact” behavior; wider widths can use the same layout or a medium/expanded variant if the existing or new design calls for it.

**Rationale**:
- The spec sets 360px as the minimum supported width; the implementation must enforce this in layout and tests.
- Material 3 breakpoints (e.g. compact / medium / expanded) can align with 360px as the lower bound for compact; no need to support 320px unless product scope changes.
- Testing at 360px width validates SC-005 and FR-007.

**Alternatives considered**:
- Supporting 320px: rejected because the spec clarified 360px as minimum.
- Desktop-only (840px+): rejected because the spec requires 360px minimum.

## Decision 6: Structure the UI for easy implementation and editing

**Decision**: Build the Catalog UI so that it is easy to implement and easy to edit: use MD3 standard components and theme tokens everywhere so that styling and behavior are consistent and changes are localized; keep a clear screen structure (list, detail, edit, configuration) so that new or changed features slot in without duplicate or tangled logic; and avoid one-off widgets or deep coupling so that changing copy, layout, or a single control does not require large refactors.

**Rationale**:
- The spec explicitly requires the UI to be easy to implement and edit (User Story 5, FR-017, SC-010).
- Design-system-driven UI and a clear structure reduce implementation effort and keep future edits localized and predictable.
- This aligns with the constitution’s Simplicity and YAGNI principle and supports long-term maintainability.

**Alternatives considered**:
- Maximize feature density per screen: rejected because it tends to increase coupling and make edits riskier.
- Custom components per screen: rejected in favor of reusing MD3 components so that theme and behavior changes apply consistently and edits stay localized.
