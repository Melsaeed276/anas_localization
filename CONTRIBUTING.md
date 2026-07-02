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

## Publishing to pub.dev

Releases are automated when you push a semver tag that matches `pubspec.yaml` (for example tag `v0.1.0` for version `0.1.0`).

### One-time pub.dev setup (OIDC)

1. Sign in to [pub.dev](https://pub.dev) as a package uploader.
2. Open **Admin** for `anas_localization`.
3. Enable **Publishing from GitHub Actions**.
4. Set repository to `Melsaeed276/anas_localization` (or your fork owner/name).
5. Set tag pattern to `v{{version}}`.

After that, pushing a matching tag runs `.github/workflows/release-tags.yml`, which validates the release, publishes to pub.dev, and creates a GitHub Release with CLI binaries.

Manual `workflow_dispatch` on that workflow runs validation only; OIDC publish requires a tag push.
