# Contributing

Thanks for contributing to `anas_localization`.

## Setup

```bash
flutter pub get
cd example && flutter pub get && cd ..
```

## Local Quality Checks

```bash
flutter analyze
flutter test
flutter pub publish --dry-run
```

## Development Workflow

1. Create a branch from the active development milestone branch.
2. Keep changes focused by issue.
3. Add or update tests for behavior changes.
4. Update `CHANGELOG.md` when user-facing behavior changes.
5. Open a pull request with linked issue references.

## Localization-Specific Checks

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=balanced
dart run anas_localization:localization_gen --modules
```

## Documentation Expectations

- Keep `README.md` examples runnable.
- Add migration notes when introducing new APIs.
- For publish-readiness updates, include impact in PR description.
