# File Structure Reference

**Feature**: `008-lib-structure-consolidation`
**Date**: 2026-06-19

## Overview

This document describes the canonical file structure for the `anas_localization` package. It defines folder roles, module placement rules, and import direction rules.

## Folder Roles

### `lib/src/features/`

Contains feature-specific code organized by domain. Each feature has its own folder with subfolders for different layers:

- `data/` - Data sources, repositories, and DTOs
- `domain/` - Business logic, entities, and contracts
- `presentation/` - UI widgets, screens, and controllers
- `use_cases/` - Application-specific business logic
- `config/` - Feature configuration
- `server/` - Server-related code
- `client/` - Client-related code
- `api/` - API definitions
- `l10n/` - Feature-specific localization

### `lib/src/shared/`

Contains code shared across multiple features:

- `utils/` - Utility functions and helpers
- `core/` - Core functionality shared across features
  - `formatters/` - Date, number, and text formatters
- `services/` - Shared services (e.g., logging)
- `data_type.dart` - Shared data type definitions

### `lib/src/core/`

Contains runtime infrastructure that is used by all features:

- `sdk_utils.dart` - SDK utility functions
- `http_client_adapter.dart` - HTTP client adapter
- `key_value_storage.dart` - Key-value storage abstraction

### Shim Directories (Legacy)

These directories contain export-only shims that re-export code from canonical locations:

- `lib/src/utils/` - Shims for `shared/utils/` and `features/migration/data/helpers/`
- `lib/src/catalog/` - Shims for `features/catalog/`
- `lib/src/core/` - Shims for `features/localization/` and `shared/core/`
- `lib/src/widgets/` - Shims for `features/localization/presentation/widgets/`
- `lib/src/services/` - Shims for `shared/services/`
- `lib/src/api/` - Shims for `features/catalog/api/`

## Module Placement Rules

| Rule | Condition | Canonical Location |
|------|-----------|-------------------|
| Single-feature code | Used by exactly 1 feature | `features/<feature>/` |
| Cross-feature code | Used by 2+ features | `shared/` |
| Infrastructure | Runtime infra (sdk_utils, http, storage) | `core/` |
| Presentation widgets | Feature-specific UI widgets | `features/<feature>/presentation/` |
| Feature barrel | Public API surface for a feature | `features/<feature>/<feature>.dart` |

## Import Direction Rules

```
presentation/ → domain/ → data/
         ↓           ↓
       shared/     shared/

Cross-feature: domain/ ↔ domain/ only
```

| From | To | Allowed |
|------|----|---------|
| `features/X/presentation/` | `features/X/domain/` | ✅ |
| `features/X/presentation/` | `features/X/data/` | ✅ |
| `features/X/data/` | `features/X/domain/` | ✅ |
| `features/X/domain/` | `shared/` | ✅ |
| `features/X/domain/` | `features/Y/domain/` | ✅ |
| `features/X/presentation/` | `features/Y/data/` | ❌ |
| `features/X/presentation/` | `features/Y/presentation/` | ❌ |
| `shared/` | `features/` | ❌ |

## Module Inventory (Canonical Locations)

### Catalog Feature

| Module | Canonical Location |
|--------|-------------------|
| `CatalogRepository` | `features/catalog/data/repositories/catalog_repository.dart` |
| `CatalogStateStore` | `features/catalog/data/repositories/catalog_state_store.dart` |
| `CatalogService` | `features/catalog/use_cases/catalog_service.dart` |
| `CatalogBackend` | `features/catalog/server/catalog_backend.dart` |
| `CatalogConfig` | `features/catalog/config/catalog_config.dart` |
| `CatalogModels` | `features/catalog/domain/entities/catalog_models.dart` |
| `CatalogFlatten` | `features/catalog/domain/services/catalog_flatten.dart` |
| `CatalogStatusEngine` | `features/catalog/domain/services/catalog_status_engine.dart` |
| `CatalogFlutterApp` | `features/catalog/presentation/screens/catalog_flutter_app.dart` |
| `CatalogUiLogic` | `features/catalog/presentation/controllers/catalog_ui_logic.dart` |
| `CatalogUiTemplate` | `features/catalog/server/catalog_ui_template.dart` |
| `CatalogClient` | `features/catalog/client/catalog_client.dart` |
| `FallbackConfigurationApi` | `features/catalog/api/fallback_configuration_api.dart` |

### Localization Feature

| Module | Canonical Location |
|--------|-------------------|
| `TranslationLoader` | `features/localization/data/sources/translation_loader.dart` |
| `LocalizationService` | `features/localization/data/repositories/localization_service.dart` |
| `AnasLocalizationStorage` | `features/localization/data/sources/anas_localization_storage.dart` |
| `Dictionary` | `features/localization/domain/entities/dictionary.dart` |
| `LocaleDetector` | `features/localization/domain/entities/locale_detector.dart` |
| `DictionaryLocalizationsDelegate` | `features/localization/presentation/widgets/dictionary_localizations_delegate.dart` |
| `LanguageSelector` | `features/localization/presentation/widgets/language_selector.dart` |
| `LanguageSetupOverlay` | `features/localization/presentation/widgets/language_setup_overlay.dart` |
| `LocalizationServiceContract` | `features/localization/domain/contracts/localization_service_contract.dart` |
| `LocalizationConfiguratorContract` | `features/localization/domain/contracts/localization_configurator_contract.dart` |
| `DictionaryLocalizationsContract` | `features/localization/domain/contracts/dictionary_localizations_contract.dart` |

### Migration Feature

| Module | Canonical Location |
|--------|-------------------|
| `localization_metadata` | `features/migration/data/helpers/localization_metadata.dart` |
| `migration_helper` | `features/migration/data/helpers/migration_helper.dart` |
| `migration_validation_helper` | `features/migration/data/helpers/migration_validation_helper.dart` |
| `conversion_helper` | `features/migration/data/helpers/conversion_helper.dart` |

### Shared Modules

| Module | Canonical Location |
|--------|-------------------|
| `translation_file_parser` | `shared/utils/translation_file_parser.dart` |
| `translation_validator` | `shared/utils/translation_validator.dart` |
| `arb_interop` | `shared/utils/arb_interop.dart` |
| `codegen_utils` | `shared/utils/codegen_utils.dart` |
| `plural_rules` | `shared/utils/plural_rules.dart` |
| `arabic_text_utils` | `shared/utils/arabic_text_utils.dart` |
| `arabic_input_validation` | `shared/utils/arabic_input_validation.dart` |
| `DateTimeFormatter` | `shared/core/formatters/date_time_formatter.dart` |
| `NumberFormatter` | `shared/core/formatters/number_formatter.dart` |
| `RichTextFormatter` | `shared/core/formatters/rich_text_formatter.dart` |
| `TextDirectionHelper` | `shared/core/formatters/text_direction_helper.dart` |
| `LocalizationExceptions` | `shared/core/localization_exceptions.dart` |
| `LoggingService` | `shared/services/logging/logging_service.dart` |

### Infrastructure (Stays in `core/`)

| Module | Location | Reason |
|--------|----------|--------|
| `sdk_utils` | `core/sdk_utils.dart` | Runtime infrastructure, used by all features |
| `http_client_adapter` | `core/http_client_adapter.dart` | Runtime infrastructure |
| `key_value_storage` | `core/key_value_storage.dart` | Runtime infrastructure |

## Test File Structure

Test files are organized to mirror the lib structure:

- `test/features/catalog/` - Catalog feature tests
- `test/features/localization/` - Localization feature tests
- `test/features/migration/` - Migration feature tests
- `test/shared/` - Shared module tests
- `test/contract/` - Contract tests
- `test/e2e/` - End-to-end tests
