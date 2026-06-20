# Import Rules Contract

**Feature**: `008-lib-structure-consolidation`
**Date**: 2026-06-17

## Public API Surface Contract

The following export paths MUST remain stable for external consumers:

```dart
// lib/anas_localization.dart exports:
package:anas_localization/...           // barrel file
package:anas_localization/src/core/... // infrastructure
package:anas_localization/src/utils/... // utilities (via shims)
package:anas_localization/src/widgets/... // widgets (via shims)
package:anas_localization/src/api/...  // API (via shim)
```

```dart
// lib/catalog.dart exports:
package:anas_localization/src/catalog/... // catalog (via shims)
```

## Shim File Contract

Every legacy shim file MUST:
1. Contain only `library;` declaration (optional) and `export` directives
2. Export the canonical path with a relative import
3. Not contain any implementation code, classes, functions, or variables

**Template**:
```dart
export '../features/<feature>/<subpath>/<file>.dart';
```

## Internal Import Contract

Within `lib/src/`, canonical implementations use relative imports:

```dart
// Within features/
import '../../../../shared/utils/translation_file_parser.dart';

// Cross-feature (domain → domain only)
import '../../../localization/domain/services/fallback_resolver.dart';
```

Test files use package imports:

```dart
// Within test/
import 'package:anas_localization/src/features/catalog/domain/entities/catalog_models.dart';
```

## Boundary Rules

| Import Direction | Allowed |
|-----------------|---------|
| `features/X/presentation/` → `features/X/domain/` | ✅ |
| `features/X/presentation/` → `features/X/data/` | ✅ |
| `features/X/data/` → `features/X/domain/` | ✅ |
| `features/X/domain/` → `shared/` | ✅ |
| `features/X/domain/` → `features/Y/domain/` | ✅ |
| `features/X/presentation/` → `features/Y/data/` | ❌ |
| `features/X/presentation/` → `features/Y/presentation/` | ❌ |
| `features/X/domain/` → `features/Y/domain/` (contracts only) | ✅ |
| `shared/` → `features/` | ❌ |

## Regression Guard

`tool/check_shim_exports.dart` enforces:
- All files in `lib/src/utils/`, `lib/src/catalog/`, `lib/src/widgets/`, `lib/src/services/`, `lib/src/api/` contain only `export` directives
- All files in `lib/src/core/` except `sdk_utils.dart`, `http_client_adapter.dart`, `key_value_storage.dart` contain only `export` directives
- Exit code 1 if any legacy file contains implementation code

**CI integration**: Script MUST run in GitHub Actions after `flutter test` (or as a dedicated lint step). Phase 1 establishes baseline (expected failures until Phase 2 completes); Phase 8 requires exit code 0.

**Supplemental test**: `test/shared/lib_structure_shim_exports_test.dart` asserts key public shim paths resolve expected types.
