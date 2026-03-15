# Data Model: Package Features Document

**Feature**: 001-package-features-doc  
**Phase**: 1

This feature is documentation-only. The "data model" describes the structure of the deliverable (the features document) and the conceptual entities it represents.

## Entities

### Document

- **Description**: The canonical package features and details document.
- **Attributes**:
  - **Location**: One main Markdown file in repo (`doc/reference/features.md`).
  - **Published form**: Dedicated page on the docs site (same content, rendered via MkDocs).
  - **Sections**: Short evaluation-oriented overview (optional); theme groups; per-feature entries; links to setup/guideline.
- **Relationships**: Source of truth for feature list and "what it does"; README and other docs link to it or summarize briefly. Links to setup/guideline document(s).

### Feature

- **Description**: A user- or adopter-facing capability of the package (e.g. typed dictionary, raw-key access, CLI validation, Catalog, deterministic fallback, migration).
- **Attributes**:
  - **Name**: Short, stable identifier (e.g. "Typed dictionary", "CLI validation").
  - **What it is / when to use it**: Clear description and "use this when …" guidance.
  - **How to enable**: Minimal (one line or one link to setup/guideline).
  - **Status** (optional): Stable | In development (e.g. Catalog, raw-key access).
- **Relationships**: Belongs to one theme group in the document. May link to setup/guideline or a specific get-started/catalog/cli page.

### Package

- **Description**: anas_localization — the Flutter/Dart localization package.
- **Attributes**: Scope defined by constitution and public docs (platforms: iOS, Android, web, desktop; formats: ARB, CSV, JSON, YAML; workflows: CLI, Catalog, migration, etc.).
- **Relationships**: Document describes the Package's features; Package scope is the boundary for what appears in the document.

### Theme group

- **Description**: A grouping of features by area (e.g. Access modes, CLI and tooling, Locale and fallback).
- **Attributes**:
  - **Title**: Section heading in the document (e.g. "Access modes", "CLI and tooling").
  - **Order**: Fixed order in the document (aligned with constitution/research).
  - **Features**: List of Feature entries; order within group by importance or alphabetically.
- **Relationships**: Contains one or more Features. No cross-references required between groups.

## Document structure (outline)

1. **Title and intro** (optional): One short paragraph for evaluators (what the package is, link to Get Started).
2. **Theme groups** (required): Each group is an H2 (or H3) section; each feature is a subsection with:
   - Feature name
   - What it is / when to use it (paragraph or bullets)
   - How to enable (one line or link)
   - Status if in development
3. **Links**: Each feature or the doc intro links to setup/guideline (Get Started or `setup-and-guidelines.md` if created).
4. **No duplication**: Full feature list and descriptions live only in this document; README and doc home link or summarize briefly.

## Validation rules

- Every capability listed in the constitution and in the current README/public docs MUST appear as a feature or be explicitly out of scope with a one-line reason.
- Every feature entry MUST have "what it is / when to use it" and minimal "how to enable" (or link).
- Features in development (e.g. Catalog, raw-key access) MUST be marked so readers are not misled.
- The document MUST link to a setup/guideline target; that target MUST exist (create if missing).
