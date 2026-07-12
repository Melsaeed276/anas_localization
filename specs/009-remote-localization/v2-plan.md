# Implementation Plan: Remote Localization V2

**Branch**: `009-remote-localization` | **Date**: 2026-07-06 | **Depends On**: `plan.md` V1 runtime remote localization  
**Input**: Follow-up scope for CLI/Catalog remote push, API configuration, optimistic concurrency, and local Catalog history.

## Summary

V2 extends remote localization beyond runtime pulls. It adds CLI and Catalog workflows that can fetch/push locale files through user-provided remote API configuration, update local locale asset files when appropriate, and record local Catalog history for remote sync actions.

Runtime app pulls remain cache-only and do not write app asset files. CLI/Catalog workflows are tooling workflows and may update real locale asset files and remote backend data.

## Goal

Enable package consumers to:

- Configure CLI/Catalog remote API endpoints for public or optionally authenticated localization APIs.
- Push all locales or one locale from local assets to a remote backend.
- Pull remote locale data into Catalog/CLI tooling and update local locale asset files.
- Use optimistic concurrency with last known `updatedAt`/`etag`/`hash` to avoid overwriting newer remote data.
- Track local history for Catalog/CLI pushes and Catalog/dev runtime pull events.

## Success Criteria

- **CLI**
  - `anas remote push` supports all locales by default.
  - `anas remote push --locale <code>` supports single-locale push.
  - CLI reads non-secret remote API configuration from project config.
  - Optional headers/auth are supported when package users configure them.
  - Public unauthenticated APIs are the documented default/common path.
  - Push uses optimistic concurrency with the last known version/hash.
- **Catalog**
  - Catalog UI exposes remote pull/push actions through the Catalog backend.
  - Catalog can select all locales or one locale for push.
  - Catalog updates local locale asset files when remote tooling pull/import succeeds.
  - Catalog records local history for remote push/pull events.
- **Runtime Dev Tooling History**
  - Runtime app pulls write history only when the app is connected to Catalog/dev tooling.
  - Normal production apps do not keep extra runtime history beyond the V1 runtime cache.
- **Quality**
  - `dart analyze` has 0 issues and formatting passes.
  - Tests cover CLI parsing, config loading, optimistic concurrency, Catalog API behavior, and history persistence.

## Constraints

- V2 must not change V1 runtime pull semantics.
- Runtime pulls still update only cache, not asset files.
- CLI/Catalog may update locale asset files because they are developer tooling workflows.
- Do not store secrets directly in project config files.
- Optional headers/auth are allowed, but tokens should be passed through environment variables or caller-provided values.
- Avoid adding dependencies unless config parsing or transport requirements cannot be met with existing package dependencies.

## Technical Context

**Language/Version**: Dart `>=3.3.0 <4.0.0`, Flutter `>=3.19.0`  
**Primary Dependencies**: existing CLI, Catalog backend/client, `http`, `yaml`, file parsers  
**Storage**: locale asset files plus local Catalog state file  
**Testing**: `flutter_test` / `package:test` (existing)  
**Target Platform**: CLI on developer machines, Catalog server/UI sidecar

## Dependencies

- V1 normalized remote payload/version models.
- Existing CLI command dispatch in `bin/anas_cli.dart`.
- Existing Catalog backend endpoints under `/api/catalog/*`.
- Existing Catalog client and state store.
- Existing translation file parser/writer behavior for JSON/YAML/ARB/CSV.

## Owners

- **CLI**: CLI maintainers
- **Catalog backend/UI**: Catalog feature maintainers
- **Runtime dev tooling integration**: anas_localization maintainers
- **Remote backend**: package users

## Milestones

- **M1 — Remote Tooling Config**
  - Define config shape for CLI/Catalog remote API settings.
  - Support public endpoints by default.
  - Support optional headers/auth when configured.
  - Resolve env var references for secrets without storing secret values in project config.
- **M2 — CLI Push/Pull**
  - Add `anas remote push [--all | --locale <code>]`.
  - Add CLI remote pull/import command if needed for Catalog parity.
  - Use optimistic concurrency with last known `updatedAt`/`etag`/`hash`.
  - Return clear structured terminal output for success, conflicts, and failures.
- **M3 — Catalog Backend Integration**
  - Add Catalog API endpoints for remote push/pull.
  - Reuse config loading and remote request code from CLI.
  - Update local locale asset files after successful tooling pull/import.
  - Record local history events in Catalog state.
- **M4 — Catalog UI**
  - Add remote action entry points in the Catalog UI.
  - Support all-locale and single-locale selection.
  - Show success/failure/conflict results.
  - Display local remote-sync history.
- **M5 — Dev Runtime History Hook**
  - When app runtime is connected to Catalog/dev tooling, record runtime remote pull/check events in local Catalog state.
  - Do not add production history storage.
- **M6 — Tests & Docs**
  - Add CLI tests for command parsing and failure cases.
  - Add Catalog backend/client tests for remote sync endpoints.
  - Add docs for config, public endpoints, optional auth, conflicts, and history.

## Design Decisions

### Separate Runtime and Tooling Paths

V1 runtime app pull:

- Uses package-user Dart bridge.
- Updates only runtime cache.
- Never writes locale asset files.

V2 CLI/Catalog:

- Uses remote API config because CLI/Catalog are not directly connected to app runtime code.
- May fetch remote data and update local locale asset files.
- May push local locale asset files to the remote backend.
- Records local Catalog history for developer visibility.

### Remote API Config

CLI/Catalog use a project-level config file with remote endpoint details.

Required capabilities:

- Public unauthenticated API by default.
- Optional request headers when configured.
- Optional auth values sourced from environment variables.
- Separate endpoints or operations for check/get/push if the backend needs them.

The exact file and schema are still open, but config should avoid executable code in V2 unless static config cannot express common backends.

### Optimistic Concurrency

Push defaults to optimistic concurrency using the last known remote version/hash:

- Use `updatedAt` for ordering.
- Use optional `etag`/`hash` for equality/conflict checks.
- If the remote backend reports a conflict, CLI/Catalog must show a conflict result instead of silently overwriting.
- Last-write-wins is not the default.

### Catalog History

History is stored in the local Catalog state file.

Track:

- CLI/Catalog remote pushes.
- CLI/Catalog remote pulls/imports.
- Runtime app pulls/checks only when the app is running with Catalog/dev tooling.

Do not track normal production app pulls in a separate runtime history store.

### Asset File Updates

Tooling pulls may update locale asset files. Runtime pulls may not.

When Catalog/CLI writes locale assets:

- Preserve existing file format where possible.
- Preserve key metadata needed by the package, including local `override` metadata.
- Validate files after writing.
- Optionally trigger dictionary regeneration when existing Catalog settings require it.

## Open Questions

- Exact config file location and schema.
- Whether V2 needs separate `check`, `get`, and `push` endpoint config or one endpoint with operation fields.
- Exact CLI command names for pull/import.
- Exact Catalog UI placement and wording for remote actions.
- Exact history event schema and retention limit.
- How to map backend conflict responses into normalized CLI/Catalog errors.

## Next Steps

- [ ] Finalize remote API config schema for CLI/Catalog.
- [ ] Define normalized tooling remote client API.
- [ ] Add CLI command plan for push and optional pull/import.
- [ ] Add Catalog backend endpoint plan.
- [ ] Add Catalog UI flow plan with history display.
- [ ] Add tests and docs plan for V2.
