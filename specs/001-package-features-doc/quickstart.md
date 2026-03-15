# Quickstart: Package Features Document

**Feature**: 001-package-features-doc

## Goal

Add or update the canonical package features document and (if needed) the setup/guideline page so that evaluators and adopters have one place to see what the package does and where to go for "how to use" steps.

## Prerequisites

- Feature spec and plan: `specs/001-package-features-doc/spec.md`, `plan.md`
- Document outline contract: `specs/001-package-features-doc/contracts/features-document-outline.md`
- Data model: `specs/001-package-features-doc/data-model.md`
- Constitution: `.specify/memory/constitution.md` (for feature list and principles)

## Steps

### 1. Create or open the features document

- **Path**: `doc/reference/features.md` (repo root relative).
- If the file does not exist, create it with the structure in `contracts/features-document-outline.md`: title, short overview, theme groups (Access modes, CLI and tooling, Locale and fallback, Migration, Catalog, Platforms and system locale), and per-feature subsections with "what it is / when to use it", "how to enable", and status if in development.

### 2. Populate feature list from constitution and README

- List every capability from the constitution (I–VI) and from the README "Features" and "Why this package" sections.
- Assign each to one theme group. Add features that are in development (e.g. Catalog, raw-key access) and mark them as such.
- For each feature, write:
  - What it is / when to use it (clear, non-technical where possible).
  - How to enable (one line or link to Get Started / setup-and-guidelines).
- Ensure the document links to the setup/guideline target (see step 3).

### 3. Setup/guideline target

- If a single "setup and guidelines" page is desired and does not exist, create `doc/get-started/setup-and-guidelines.md` that summarizes setup and links to Install and First Run, Generate and Wrap, Validate, and (if relevant) Catalog and CLI. Add it to `mkdocs.yml` under Get Started.
- If using existing Get Started only: link from the features doc to `get-started/index.md` (or the published equivalent) as the primary "how to use" target.
- Verify every feature entry either includes a one-line "how to enable" or a link to this target (or a more specific get-started/catalog/cli page).

### 4. Add the Features page to the docs site

- Open `mkdocs.yml` in the repo root.
- Add a nav entry for the features document, e.g. under Reference: `Features: reference/features.md`, or a top-level `Features: reference/features.md`.
- Run a local MkDocs build/serve to confirm the page appears and links work: `mkdocs serve` (if available) or rely on CI/publish workflow.

### 5. Update README and doc home

- In the repo README, add a short "Features" subsection or bullet that links to the features document (or the published Features page URL). Do not duplicate the full feature list.
- In `doc/index.md`, add a link to the Features page (e.g. under "Start with the path that matches your goal" or in "Recommended next pages") so evaluators and adopters can find it.

### 6. Validate

- Read through the document as an evaluator: can you tell in under 5 minutes if the package supports your use case?
- Read through as an adopter: can you find one feature and its "how to enable" (or link) without leaving the doc?
- Check that all constitution principles are reflected and that features in development are clearly marked.
- Confirm there are no broken links to the setup/guideline target or Get Started pages.

## Adding a new feature later

1. Open `doc/reference/features.md`.
2. Decide which theme group the feature belongs to (or add a new group if justified).
3. Add a subsection with: feature name, "what it is / when to use it", "how to enable" (one line or link), and status if in development.
4. If the feature is in the constitution or README, ensure wording stays aligned.
5. Re-run validation (step 6 above).

## References

- Spec: `specs/001-package-features-doc/spec.md`
- Plan: `specs/001-package-features-doc/plan.md`
- Document outline contract: `specs/001-package-features-doc/contracts/features-document-outline.md`
- Constitution: `.specify/memory/constitution.md`
