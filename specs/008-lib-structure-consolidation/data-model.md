# Data Model: Lib Structure Consolidation

**Feature**: `008-lib-structure-consolidation`
**Date**: 2026-06-17

## Overview

This is a structural refactor — no new domain entities are introduced. The data model documents the **module placement rules** and **import contracts** that govern the reorganized codebase.

**Inventory**: 38 modules with legacy→canonical pairs (see table below). As of 2026-06-17: 30 already export-only shims, 8 divergent implementations remaining.

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

| Module | Used By | Canonical Location | Legacy Path |
|--------|---------|-------------------|-------------|
| `CatalogRepository` | catalog | `features/catalog/data/repositories/catalog_repository.dart` | `src/catalog/catalog_repository.dart` |
| `CatalogStateStore` | catalog | `features/catalog/data/repositories/catalog_state_store.dart` | `src/catalog/catalog_state_store.dart` |
| `CatalogService` | catalog | `features/catalog/use_cases/catalog_service.dart` | `src/catalog/catalog_service.dart` |
| `CatalogBackend` | catalog | `features/catalog/server/catalog_backend.dart` | `src/catalog/catalog_backend.dart` |
| `CatalogConfig` | catalog | `features/catalog/config/catalog_config.dart` | `src/catalog/catalog_config.dart` |
| `CatalogModels` | catalog | `features/catalog/domain/entities/catalog_models.dart` | `src/catalog/catalog_models.dart` |
| `CatalogFlatten` | catalog | `features/catalog/domain/services/catalog_flatten.dart` | `src/catalog/catalog_flatten.dart` |
| `CatalogStatusEngine` | catalog | `features/catalog/domain/services/catalog_status_engine.dart` | `src/catalog/catalog_status_engine.dart` |
| `CatalogFlutterApp` | catalog | `features/catalog/presentation/screens/catalog_flutter_app.dart` | `src/catalog/catalog_flutter_app.dart` |
| `CatalogUiLogic` | catalog | `features/catalog/presentation/controllers/catalog_ui_logic.dart` | `src/catalog/catalog_ui_logic.dart` |
| `CatalogUiTemplate` | catalog | `features/catalog/server/catalog_ui_template.dart` | `src/catalog/catalog_ui_template.dart` |
| `CatalogClient` | catalog | `features/catalog/client/catalog_client.dart` | `src/catalog/catalog_client.dart` |
| `translation_file_parser` | catalog, localization, migration, CLI | `shared/utils/translation_file_parser.dart` | `src/utils/translation_file_parser.dart` |
| `translation_validator` | localization, CLI | `shared/utils/translation_validator.dart` | `src/utils/translation_validator.dart` |
| `arb_interop` | catalog, migration, CLI | `shared/utils/arb_interop.dart` | `src/utils/arb_interop.dart` |
| `codegen_utils` | CLI | `shared/utils/codegen_utils.dart` | `src/utils/codegen_utils.dart` |
| `localization_metadata` | migration | `features/migration/data/helpers/localization_metadata.dart` | `src/utils/localization_metadata.dart` |
| `plural_rules` | localization | `shared/utils/plural_rules.dart` | `src/utils/plural_rules.dart` |
| `arabic_text_utils` | localization | `shared/utils/arabic_text_utils.dart` | `src/utils/arabic_text_utils.dart` |
| `arabic_input_validation` | localization | `shared/utils/arabic_input_validation.dart` | `src/utils/arabic_input_validation.dart` |
| `migration_helper` | migration, CLI | `features/migration/data/helpers/migration_helper.dart` | `src/utils/migration_helper.dart` |
| `migration_validation_helper` | migration, CLI | `features/migration/data/helpers/migration_validation_helper.dart` | `src/utils/migration_validation_helper.dart` |
| `conversion_helper` | migration, CLI | `features/migration/data/helpers/conversion_helper.dart` | `src/utils/conversion_helper.dart` |
| `TranslationLoader` | localization | `features/localization/data/sources/translation_loader.dart` | `src/core/translation_loader.dart` |
| `LocalizationService` | localization | `features/localization/data/repositories/localization_service.dart` | `src/core/localization_service.dart` |
| `AnasLocalizationStorage` | localization | `features/localization/data/sources/anas_localization_storage.dart` | `src/core/anas_localization_storage.dart` |
| `Dictionary` | localization | `features/localization/domain/entities/dictionary.dart` | `src/core/dictionary.dart` |
| `LocaleDetector` | localization | `features/localization/domain/entities/locale_detector.dart` | `src/core/locale_detector.dart` |
| `DictionaryLocalizationsDelegate` | localization | `features/localization/presentation/widgets/dictionary_localizations_delegate.dart` | `src/core/dictionary_localizations_delegate.dart` |
| `LanguageSelector` | localization | `features/localization/presentation/widgets/language_selector.dart` | `src/widgets/language_selector.dart` |
| `LanguageSetupOverlay` | localization | `features/localization/presentation/widgets/language_setup_overlay.dart` | `src/widgets/language_setup_overlay.dart` |
| `DateTimeFormatter` | localization | `shared/core/formatters/date_time_formatter.dart` | `src/core/date_time_formatter.dart` |
| `NumberFormatter` | localization | `shared/core/formatters/number_formatter.dart` | `src/core/number_formatter.dart` |
| `RichTextFormatter` | localization | `shared/core/formatters/rich_text_formatter.dart` | `src/core/rich_text_formatter.dart` |
| `TextDirectionHelper` | localization | `shared/core/formatters/text_direction_helper.dart` | `src/core/text_direction_helper.dart` |
| `LocalizationExceptions` | localization | `shared/core/localization_exceptions.dart` | `src/core/localization_exceptions.dart` |
| `LoggingService` | multiple | `shared/services/logging/logging_service.dart` | `src/services/logging_service/logging_service.dart` |
| `FallbackConfigurationApi` | catalog | `features/catalog/api/fallback_configuration_api.dart` | `src/api/fallback_configuration_api.dart` |

## Infrastructure (Stays in `core/`)

| Module | Location | Reason |
|--------|----------|--------|
| `sdk_utils` | `core/sdk_utils.dart` | Runtime infrastructure, used by all features |
| `http_client_adapter` | `core/http_client_adapter.dart` | Runtime infrastructure |
| `key_value_storage` | `core/key_value_storage.dart` | Runtime infrastructure |

## Test File Migration Map

| Test File (current) | Target Location |
|--------------------|-----------------|
| `test/arb_interop_test.dart` | `test/shared/arb_interop_test.dart` |
| `test/tool_workflow_test.dart` | `test/shared/tool_workflow_test.dart` |
| `test/catalog_*_test.dart` (8 files) | `test/features/catalog/` |
| `test/fallback_*_test.dart` (2 files) | `test/features/localization/` |
| `test/locale_*_test.dart` (8 files) | `test/features/localization/` |
| `test/localization_*_test.dart` (3 files) | `test/features/localization/` |
| `test/localization_test.dart` | `test/features/localization/` |
| `test/migration_*_test.dart` (2 files) | `test/features/migration/` |
| `test/translation_loader_*_test.dart` | `test/features/localization/` |
| `test/dictionary_*_test.dart` (2 files) | `test/features/localization/` |
| `test/e2e/` | Unchanged |
