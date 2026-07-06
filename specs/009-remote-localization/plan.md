# Implementation Plan: Remote Localization V1

**Branch**: `009-remote-localization` | **Date**: 2026-07-06 | **Spec**: (to be created)  
**Input**: User-provided feature description and decision pass in chat. V1 focuses on runtime remote pull; CLI/Catalog push and history are split into `v2-plan.md`.

## Summary

Add an optional runtime **Remote Localization** feature that lets app code check whether remote translations changed, download updated locale data, cache it locally, and apply it without blocking app startup. Remote data is used only as a runtime cache; V1 must not write remote pull results back into app asset files.

The runtime remains safe by default: when remote localization is not configured or startup checking is disabled, current localization behavior is unchanged. If a remote check/download fails, the package keeps the last cached remote data if available, otherwise it falls back to local locale assets.

## Goal

Enable package consumers to:

- Configure remote localization directly on `AnasLocalization(...)`.
- Provide a runtime bridge that maps their backend into normalized package types.
- Support either global bundle checks or per-locale checks depending on backend design.
- Trigger remote check/update on startup when explicitly enabled.
- Trigger manual check/update anytime through a static/package API.
- Preserve app asset hotfixes for selected keys with inline `override: false` metadata.

## Success Criteria

- **Runtime**
  - Existing apps have no behavior change unless remote localization is explicitly configured.
  - Startup remote check is available but defaults to disabled.
  - Startup remote work is non-blocking and never prevents initial asset-based rendering.
  - Manual API supports global checks with `checkAndUpdateRemoteLocalization()` and per-locale checks with `checkAndUpdateRemoteLocalization(locale: 'en')`.
  - Global bridge check returning `hasUpdate: false` performs no download.
  - Global bridge check returning `hasUpdate: true` downloads a list/bundle of locale payloads.
  - Per-locale bridge check returning `hasUpdate: true, locale: 'en'` downloads only that locale.
  - Per-locale bridge check returning `hasUpdate: false` performs no download.
  - Bridge exceptions/timeouts return structured failure results with error messages and do not crash the app.
  - Cached remote payloads are used at runtime; app locale asset files are not modified by runtime pulls.
  - If cache is empty or invalid, local locale assets continue to work.
- **Merge behavior**
  - Default precedence is `package assets < app assets < remote cache`.
  - App asset keys marked with `override: false` cannot be overridden by remote data.
  - Missing `override` metadata behaves as `override: true`.
  - `override` metadata is stripped before dictionary creation and never appears in rendered strings.
- **Quality**
  - `dart analyze` has 0 issues and formatting passes.
  - Unit tests cover bridge mode dispatch, cache fallback, merge precedence, protected keys, failure results, timeout/retry behavior, and reload notification.

## Constraints

- **No breaking changes** to existing runtime localization flows.
- **No new dependencies by default**: use existing `shared_preferences`/`KeyValueStorage` and current parsing utilities.
- Must work across Flutter mobile, web, and desktop.
- Remote checks/downloads must have explicit timeouts.
- V1 includes one automatic retry after a failed remote operation; further retry behavior is owned by the package user or their bridge.
- Runtime bridge functions own authentication and backend DTO mapping; `anas_localization` must not store or log tokens/secrets.
- CLI/Catalog remote push, API config, and history are not part of V1 implementation scope; see `v2-plan.md`.

## Technical Context

**Language/Version**: Dart `>=3.3.0 <4.0.0`, Flutter `>=3.19.0`  
**Primary Dependencies**: `shared_preferences` (existing), translation parsers (existing), optional user-owned HTTP/auth inside bridge implementations  
**Storage**: `RemoteLocalizationCache` abstraction; default implementation backed by `KeyValueStorage`/`SharedPreferences`  
**Testing**: `flutter_test` / `package:test` (existing)  
**Target Platform**: Flutter (iOS, Android, Web, Desktop)  
**Project Type**: Flutter/Dart package runtime feature

## Dependencies

- Existing `AnasLocalization` runtime initialization and locale reload flow.
- Existing `LocalizationService` merge and dictionary creation behavior.
- Existing loader/parsing utilities for JSON/YAML/ARB/CSV normalization.
- Existing local persistence abstraction: `KeyValueStorage` and `DefaultKeyValueStorage`.
- Existing listener notification path used after `LocalizationService.loadLocale`.

## Owners

- **Runtime**: anas_localization package maintainers
- **Bridge implementations**: package users
- **Docs/tests**: anas_localization package maintainers

## Milestones

- **M1 — Runtime Contracts & Config**
  - Define `RemoteLocalizationConfig` and configure it directly on `AnasLocalization(...)`.
  - Define a common base `RemoteLocalizationBridge` plus `GlobalRemoteLocalizationBridge` and `PerLocaleRemoteLocalizationBridge`.
  - Define normalized check, payload, result, version, and cache model types.
- **M2 — Cache & Merge Semantics**
  - Add `RemoteLocalizationCache` with a default `SharedPreferences` implementation.
  - Save last applied global/per-locale version metadata and cached locale payloads.
  - Implement `package assets < app assets < remote cache` merge behavior.
  - Implement local app asset key protection using `override: false`.
- **M3 — Runtime Pull Orchestration**
  - Add non-blocking startup check gated by `checkRemoteOnStart`, default `false`.
  - Add static/package manual API `checkAndUpdateRemoteLocalization({String? locale})`.
  - Dispatch global vs per-locale checks based on bridge type and method arguments.
  - Reload the active locale and notify listeners when remote data changes the current dictionary.
- **M4 — Resilience**
  - Add default timeouts: 5 seconds for check and 10 seconds for download.
  - Allow timeout overrides through `RemoteLocalizationConfig`.
  - Add exactly one automatic retry after a failed check/download.
  - Return structured failure results while preserving cached/local data.
- **M5 — Tests & Docs**
  - Add focused unit tests for contracts, orchestration, cache, merge, protected keys, and failures.
  - Document runtime bridge setup, global vs per-locale modes, cache behavior, manual check API, and `override` metadata.

## Design Decisions

### Runtime Bridge / Protocol

Remote backends can use any raw payload shape. The package user owns backend calls, authentication, token refresh, DTO parsing, and null checking inside their bridge implementation. `anas_localization` only receives normalized, non-null results.

V1 defines one common bridge base and two concrete mode interfaces:

- `RemoteLocalizationBridge`: marker/common base interface.
- `GlobalRemoteLocalizationBridge`: checks and downloads a full locale bundle.
- `PerLocaleRemoteLocalizationBridge`: checks and downloads one locale at a time.

The user configures one bridge implementation based on backend setup. If a global bridge is configured and the caller requests a per-locale manual check, the package returns a structured failure result such as “per-locale check is not configured”. The same applies in reverse when a global manual check is requested but only a per-locale bridge is configured.

### Check Result Types

Global checks:

- `RemoteLocalizationCheckResult(hasUpdate: bool)`
- `hasUpdate: false`: do not call `getRemoteLocalization()`.
- `hasUpdate: true`: call `getRemoteLocalization()` and expect a list/bundle of locale payloads.

Per-locale checks:

- `RemoteLocaleCheckResult(hasUpdate: bool, locale: String?)`
- `hasUpdate: false`: do not call `getRemoteLocalization(locale)`.
- `hasUpdate: true, locale: 'en'`: call `getRemoteLocalization('en')` and expect only that locale payload.

### Remote Payloads & Versions

Downloaded payloads must include normalized locale data and version metadata so the package can persist the last applied state.

Recommended normalized payload shape:

- `RemoteLocalizationPayload`
  - `locale`: normalized locale code
  - `data`: `Map<String, dynamic>` in the same shape as local assets
  - `version`: `RemoteLocalizationVersion`

Version model supports both global and per-locale use:

- Require `updatedAt` for ordering and “newer than cache” decisions.
- Allow optional `etag`/`hash` for equality and optimistic concurrency.
- Interpret timestamps as UTC using ISO-8601.
- Treat remote as newer only when `updatedAt` is strictly newer than the cached version.

### Runtime Configuration

Remote localization is configured directly on `AnasLocalization(...)`:

- `remoteConfig: RemoteLocalizationConfig(...)`
- `checkRemoteOnStart`: defaults to `false`
- `checkTimeout`: defaults to 5 seconds
- `downloadTimeout`: defaults to 10 seconds
- `cache`: optional custom `RemoteLocalizationCache`
- `bridge`: required when remote config is supplied

Manual check/update is exposed as a static/package API:

- `AnasLocalization.checkAndUpdateRemoteLocalization()`: global check/update.
- `AnasLocalization.checkAndUpdateRemoteLocalization(locale: 'en')`: per-locale check/update.

### Runtime Pull Flow

On app startup:

- Load locale normally from package/app assets and any valid cached remote data so UI can render.
- If `remoteConfig` is absent or `checkRemoteOnStart` is `false`, do no remote work.
- If startup check is enabled, trigger remote check asynchronously after normal initialization.
- Apply the same orchestration as manual checks.

For updates:

- If check says no update, stop.
- If check says update exists, download affected locale payloads.
- Validate/normalize payloads into `Map<String, dynamic>`.
- Persist payload and version metadata in the cache.
- If the active locale changed, reload the active locale dictionary and notify listeners.

### Caching & Persistence

V1 uses a pluggable `RemoteLocalizationCache`.

Default behavior:

- Store metadata and cached payloads with `KeyValueStorage`/`SharedPreferences`.
- Keep runtime remote data separate from app asset files.
- Use cached remote data when available.
- If cached data is missing, corrupt, or cannot be parsed, fall back to local assets.

V1 does not include a built-in file/database cache. Large projects can inject a custom `RemoteLocalizationCache`.

### Merge Precedence & Protected Keys

Default precedence:

1. Package assets
2. App assets
3. Remote cache

Remote data wins by default. App assets can protect individual keys from remote override by adding correctly spelled `override` metadata in the locale asset value:

- `override: false`: app asset value is fixed and cannot be overridden by remote.
- `override: true`: app asset value can be overridden by remote.
- Missing `override`: treated as `override: true`.

Only local app assets can protect keys. Remote payloads cannot mark keys as non-overridable.

The `override` marker is merge metadata only and must be removed before creating the final `Dictionary`.

### Parsing & Data Shape

Remote payloads normalize into the same `Map<String, dynamic>` shape as local assets. This preserves nested maps and existing JSON/YAML/ARB/CSV behavior, including plural/select/data-type patterns already supported by the package.

### Failure Semantics

- If check throws, times out, or returns a structured failure: return a structured failure result with an error message.
- If check fails during startup: log safely, keep current localization, and do not crash.
- If check succeeds but download fails: keep old cached payload and old last applied version.
- If download succeeds but parsing/normalization fails: keep old cached payload and old last applied version.
- If there is no cached remote data, use local locale assets.
- Run one automatic retry after a failed check/download; do not retry indefinitely.
- Do not log secrets or raw auth headers.

### Security

Runtime bridge implementations own auth, token refresh, request signing, and secret storage. `anas_localization` only receives normalized results and error messages. The package must not store credentials in preferences, include credentials in cache keys, or print/log sensitive data.

## Implementation Dependencies

- Existing locale fallback and reload path in `LocalizationService`.
- Existing `AnasLocalization` initialization and listener flow.
- Existing `KeyValueStorage` implementation.
- Existing parsing/normalization utilities.
- Test doubles for bridges, cache, and dictionary creation.

## Open Questions

- Exact public class names and file locations.
- Exact representation for `override` metadata in every supported asset format, especially plain string JSON values versus structured values.
- Whether V1 should expose update progress/status listeners beyond the final structured result.
- Whether remote cache should include a max size guard or leave that entirely to custom cache implementations.

## Next Steps

- [ ] Write `spec.md` for V1 runtime remote localization using these decisions.
- [ ] Define public API surface for config, bridge interfaces, result types, version metadata, and cache interface.
- [ ] Add tests for global and per-locale bridge orchestration.
- [ ] Add tests for merge precedence and `override: false` protected keys.
- [ ] Implement default cache and failure-safe update flow.
- [ ] Document setup examples for global and per-locale bridge implementations.
