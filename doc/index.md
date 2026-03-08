# anas_localization Docs

This is the primary documentation for `anas_localization`. Use it for setup, migration, testing, catalog workflows, and CLI usage.

## Start with the path that matches your goal

- New package setup: [Get Started](get-started/index.md)
- Runtime usage inside your app: [Use in App](use-in-app/index.md)
- Migrate from another localization package: [Migrate](migrate/index.md)
- Build localized tests and CI checks: [Testing](testing/index.md)
- Manage translations with the sidecar UI: [Catalog](catalog/index.md)
- Find commands and flags quickly: [CLI](cli/index.md)

## Feature spotlight: Catalog UI

This branch ships a standalone Catalog UI sidecar with a browser table, review statuses, and a JSON API. Use it when your team wants to manage translation files outside the app runtime.

```bash
dart run anas_localization:anas_cli catalog init
```

```bash
dart run anas_localization:anas_cli catalog serve
```

Read next:

- [Catalog Overview](catalog/index.md)
- [Catalog Architecture](catalog/architecture.md)

## Fastest path to a working app

```bash
flutter pub add anas_localization
dart run anas_localization:localization_gen
dart run anas_localization:anas_cli validate assets/lang
```

## What the docs optimize for

- copyable code snippets and commands
- short task pages before deep reference
- accurate examples based on the shipped package APIs
- clear next steps so users do not dead-end on a page

## Recommended next pages

- [Install and First Run](get-started/install-and-first-run.md)
- [Generate and Wrap Your App](get-started/generate-and-wrap.md)
- [Catalog Setup and Serve](catalog/setup-and-serve.md)
- [Common CLI Workflows](cli/common-workflows.md)
