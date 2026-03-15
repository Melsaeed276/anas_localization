# Contract: Features Document Outline

**Feature**: 001-package-features-doc  
**Type**: Document structure contract

This contract defines the required structure of the canonical package features document (`doc/reference/features.md`) so that it meets the spec (FR-001–FR-006) and stays maintainable.

## Required sections (in order)

1. **Document title**  
   - One H1 (e.g. "Package features" or "anas_localization features").

2. **Short overview** (optional but recommended)  
   - One short paragraph for evaluators: what the package is, who it is for, link to Get Started.  
   - Ensures "both evaluators and adopters" (clarification) and SC-001 (decide in 5 minutes).

3. **Theme groups** (required)  
   - Each theme is a top-level section (H2).  
   - Required theme groups (order fixed):
     - Access modes (typed dictionary, raw string keys)
     - CLI and tooling
     - Locale and fallback
     - Migration
     - Catalog
     - Platforms and system locale
   - Optional: Loaders and formats (if distinct from CLI/locale).

4. **Per-feature content** (within each theme)  
   - Each feature MUST have:
     - A heading (H3 or equivalent) with the feature name.
     - "What it is / when to use it": prose or bullets, clear to non-experts.
     - "How to enable": one line or one link to setup/guideline.
     - If in development: a short note (e.g. "In development" or "Planned").
   - Order within a group: by importance or alphabetically (maintainer choice).

5. **Links**  
   - The document MUST link to the setup/guideline target (e.g. Get Started overview or `get-started/setup-and-guidelines.md`).  
   - Individual features MAY link to specific get-started/catalog/cli pages.

## Out of scope for this document

- Step-by-step setup instructions (belong in Get Started / setup-and-guidelines).
- API or code reference (belong in reference/cli-reference, config-reference, etc.).
- Migration walkthroughs (belong in Migrate section).
- Troubleshooting (belong in Troubleshooting).

## Compliance

- **FR-001**: All current package features listed → every capability from constitution/README covered in theme groups.
- **FR-002**: Each feature has "what it is / when to use it" + minimal "how to enable" + link to setup/guideline.
- **FR-003**: Grouping by theme + clear headings enable quick find.
- **FR-004**: Content reflects constitution and public docs; no implementation-only detail.
- **FR-005**: One file in repo; published page reflects it.
- **FR-006**: Features in development explicitly marked.
