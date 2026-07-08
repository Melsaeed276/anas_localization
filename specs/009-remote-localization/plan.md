# Implementation Plan: Remote Localization V1

**Branch**: `009-remote-localization` | **Date**: 2026-07-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/009-remote-localization/spec.md`

## Goal

Add optional runtime remote localization pull support without changing default local-first localization behavior for existing package consumers.

## Summary

Remote Localization V1 introduces a consumer-provided remote connector, structured check/update results, a persistent remote payload cache with in-memory fallback, and a merge layer that applies remote cached values after package and app assets while respecting `override: false` protected app keys. The work stays inside the existing `features/localization` clean-architecture area and reuses current parsing, fallback resolution, HTTP adapter, and logging patterns.

## Success Criteria

- Existing apps with no remote configuration keep the same local translation behavior.
- Startup remote checking remains opt-in and never blocks initial localization rendering.
- Manual global and per-locale checks report structured success/failure outcomes.
- Updated payloads are cached and applied only when the connector reports an update.
- Protected app asset keys marked `override: false` always retain the app-provided value.
- Runtime remote pull never writes back to app locale asset files.
- Secret values are not cached, used in cache keys, or emitted in package logs.

## Technical Context

**Language/Version**: Dart `>=3.3.0 <4.0.0`, Flutter `>=3.19.0`  
**Primary Dependencies**: Flutter SDK, `intl`, `flutter_localizations`, `yaml`, `http`, `path`, `shared_preferences`; reuse `HttpClientAdapter`, `TranslationFileParser`, `AnasLoggingService`  
**Storage**: Persistent file-based remote payload cache with in-memory fallback; existing app locale assets remain read-only at runtime  
**Testing**: `flutter test`, focused unit/integration tests under `test/features/localization/`, contract tests under `test/contract/` where public remote APIs are introduced  
**Target Platform**: Flutter package runtime on iOS, Android, web, desktop, and Dart-compatible test environments  
**Project Type**: Dart/Flutter package with runtime library, code generator, CLI, and catalog sidecar; V1 scope is runtime library only  
**Performance Goals**: Local translations render before remote work; remote operations use a 10-second time limit, one retry, 2-second backoff; payloads expected below 1 MB per locale and up to 50 locales  
**Constraints**: Remote localization disabled unless explicitly configured; startup check disabled by default; local asset files never modified; duplicate in-flight checks for the same global/locale scope skipped; remote errors sanitized for secrets  
**Scale/Scope**: Runtime remote pull for all configured locales or one requested locale; CLI remote push, Catalog remote sync, remote history, and local asset update workflows are out of V1 scope

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Dual Access Modes**: PASS. Remote data feeds the same runtime dictionaries used by generated APIs and raw-key access.
- **II. CLI and Tooling**: PASS. V1 is runtime-only and explicitly excludes CLI remote push/sync behavior.
- **III. Deterministic Locale Behavior**: PASS. Existing fallback chain resolution remains canonical; remote cache is an additional data source for resolved locale payloads.
- **IV. Migration-Friendly**: PASS. Remote configuration is opt-in and preserves default behavior for existing consumers.
- **V. Catalog**: PASS. Catalog remote sync is out of scope, avoiding coupling runtime pull to the sidecar UI.
- **VI. Simplicity and YAGNI**: PASS. One remote connector contract and one cache abstraction are added only for specified runtime behavior.
- **VII. Clean Architecture Boundaries**: PASS. Domain entities/contracts stay under `features/localization/domain`, cache/data implementations under `data`, and shared utilities remain reused rather than moved.
- **VIII. Error Handling Standards**: PASS. Remote failures use typed exceptions internally and structured public result objects externally.
- **IX. Testing Discipline**: PASS. Critical merge, cache, retry, queue, and failure paths require focused tests.
- **X. CI/CD Quality Gates**: PASS. Implementation must continue to pass format, analyze, test, and publish dry-run gates.
- **XI. Logging and Observability**: PASS. Runtime events use `AnasLoggingService`; counters are emitted through a new remote metrics interface that avoids sensitive data.
- **XII. Sharia-Compliant Finance**: PASS. Not applicable; feature has no financial or Zakat logic.

## Project Structure

### Documentation (this feature)

```text
specs/009-remote-localization/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── remote-localization-api.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/src/features/localization/
├── data/
│   ├── repositories/
│   │   ├── localization_service.dart
│   │   └── remote_localization_repository_impl.dart
│   └── sources/
│       └── remote_localization_cache_store.dart
├── domain/
│   ├── contracts/
│   │   ├── remote_localization_connector.dart
│   │   └── remote_localization_service_contract.dart
│   ├── entities/
│   │   ├── remote_localization_config.dart
│   │   ├── remote_localization_payload.dart
│   │   ├── remote_localization_result.dart
│   │   └── remote_localization_version.dart
│   ├── repositories/
│   │   └── remote_localization_repository.dart
│   └── services/
│       ├── remote_localization_coordinator.dart
│       └── remote_translation_merge_policy.dart
└── use_cases/
    ├── check_global_remote_localization_update.dart
    └── check_locale_remote_localization_update.dart

lib/src/shared/
└── services/
    └── metrics/
        └── remote_localization_metrics.dart

test/features/localization/
├── remote_localization_cache_store_test.dart
├── remote_localization_coordinator_test.dart
├── remote_localization_repository_test.dart
├── remote_localization_use_cases_test.dart
├── remote_translation_merge_policy_test.dart
├── remote_localization_security_test.dart
└── remote_localization_integration_test.dart

test/contract/
└── remote_localization_api_contract_test.dart
```

**Structure Decision**: Keep implementation inside `lib/src/features/localization` because remote payloads affect runtime localization loading and merge behavior. Reuse `lib/src/shared` only for cross-feature metrics primitives if they remain generic; do not add implementation logic to `lib/src/core` barrel shims.

## Milestones

1. **Domain contracts and models**: Define configuration, connector, version, payload, result, metrics, and repository contracts.
2. **Cache and merge layer**: Implement file cache with in-memory fallback plus protected-key-aware merge policy.
3. **Coordinator and use cases**: Add queue/dedup, timeout/retry, global/per-locale update orchestration, structured results, and logging/counters.
4. **LocalizationService integration**: Load cached remote data after package/app assets, reload active locale after successful active-locale updates, and preserve local-first startup.
5. **Tests and verification**: Add unit, integration, and contract coverage for default behavior, remote success, failures, concurrency, protected keys, and observability.

## Dependencies

- Existing `LocalizationService` loading path and listener refresh hooks.
- Existing `TranslationFileParser` and ARB/JSON/YAML/CSV normalization behavior.
- Existing `HttpClientAdapter` pattern for consumer-owned backend access where needed.
- Existing `AnasLoggingService` and release-mode sensitive-data logging constraints.
- Persistent file cache location strategy that works across Flutter-supported platforms.

## Owners

- Package runtime owner: localization feature maintainer.
- Public API owner: package API maintainer.
- QA owner: test author for runtime localization and contract coverage.
- Consumer integration owner: app developer implementing the remote connector.

## Next Steps

Run `/speckit.tasks` to break this plan into implementation tasks after reviewing `research.md`, `data-model.md`, `contracts/remote-localization-api.md`, and `quickstart.md`.

## Complexity Tracking

No constitution violations identified. The added connector, cache, queue, and metrics abstractions map directly to explicit V1 requirements and are scoped to runtime remote pull behavior.

## Phase 0 Research

See [research.md](./research.md).

## Phase 1 Design

See [data-model.md](./data-model.md), [contracts/remote-localization-api.md](./contracts/remote-localization-api.md), and [quickstart.md](./quickstart.md).

## Post-Design Constitution Check

- **Architecture boundaries**: PASS. Design places domain contracts/entities separately from data sources and repositories.
- **Typed failures**: PASS. Connector and coordinator failures are represented in result entities and typed exceptions.
- **Tests**: PASS. Planned tests cover merge precedence, cache fallback, retry/timeout, queue/dedup, active-locale reload, and default no-remote behavior.
- **CI gates**: PASS. No generated design artifact requires CI exception.
- **Logging/PII**: PASS. Logs and counters describe lifecycle/status only and exclude connector credentials or backend secrets.
- **Finance**: PASS. Not applicable.
