# Research: Package Features and Details Document

**Feature**: 001-package-features-doc  
**Phase**: 0

## Decisions

### 1. Document location and published page

- **Decision**: One main file at `doc/reference/features.md`; add it to MkDocs `nav` (e.g. under Reference or as "Features" at top level) so the published site has a dedicated Features page.
- **Rationale**: Repo already uses `doc/` and MkDocs; `reference/` holds Concepts, Glossary, Config, etc. A Features page fits there and stays a single source of truth. The published URL will be something like `.../anas_localization/reference/features/`.
- **Alternatives considered**: Root-level `FEATURES.md` (would not be in MkDocs nav by default); separate `docs/` folder (repo uses `doc/`).

### 2. Theme groups for feature grouping

- **Decision**: Group features into these themes (order can follow constitution): (1) Access modes (typed dictionary, raw string keys), (2) CLI and tooling, (3) Locale and fallback, (4) Migration, (5) Catalog, (6) Platforms and system locale. Optional: (7) Loaders and formats.
- **Rationale**: Aligns with constitution principles and README; keeps "find quickly" (FR-003) and supports both evaluators and adopters.
- **Alternatives considered**: Single flat list (harder to scan); grouping by user journey only (evaluators vs adopters) would duplicate feature descriptions across sections.

### 3. Setup/guideline link target

- **Decision**: Use Get Started as the primary "how to use" target. Add a single entry in nav: either link to `get-started/index.md` from the features doc, or create `doc/get-started/setup-and-guidelines.md` that aggregates setup and links to install, generate, wrap, and validate. Prefer creating `setup-and-guidelines.md` only if the spec or tasks require a single consolidated "setup and guideline" page; otherwise link to existing Get Started overview and key pages.
- **Rationale**: Get Started already covers install, first run, translations, generate, wrap. A dedicated "setup and guidelines" page can avoid duplication by summarizing and linking. If it does not exist, create it so the features doc has one clear link target.
- **Alternatives considered**: Linking only to multiple get-started subpages (acceptable but more links); creating a long single "how to use" doc that duplicates get-started (rejected — spec says link to setup/guideline, not duplicate).

### 4. README and doc site home updates

- **Decision**: After the features doc is written, update README to add a short "Features" subsection or bullet that links to the features document (or the published Features page). Update doc home (`doc/index.md`) to include a link to the Features page so evaluators and adopters can find it.
- **Rationale**: Spec requires this document to be the canonical source and README to link or summarize briefly; doc home should surface it.
- **Alternatives considered**: Leaving README unchanged (would violate spec); duplicating feature list in README (would violate single source of truth).

## Summary

All NEEDS CLARIFICATION from Technical Context are resolved: document location (`doc/reference/features.md`), theme grouping (six to seven groups aligned with constitution), setup/guideline target (Get Started or new `setup-and-guidelines.md` as needed), and README/doc home updates. No further research required for Phase 1.
