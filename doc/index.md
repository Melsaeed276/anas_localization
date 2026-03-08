# anas_localization Docs

This is the primary documentation hub for `anas_localization`. Use it for task-first setup, runtime usage, migration workflows, catalog editing, CLI reference, and cookbook recipes.

## Start with the path that matches your goal

- New package setup: [Get Started](get-started/index.md)
- Runtime usage inside your app: [Use in App](use-in-app/index.md)
- Migrate from another localization package: [Migrate](migrate/index.md)
- Build localized tests and CI checks: [Testing](testing/index.md)
- Manage translations with the sidecar UI: [Catalog](catalog/index.md)
- Find commands and flags quickly: [CLI](cli/index.md)
- Follow shorter recipe-style walkthroughs: [Cookbook](cookbook/index.md)

## Feature spotlight: Catalog UI

The catalog sidecar is a standalone translation workspace with autosave editing, explicit `Done` review for target locales, structured editors for plural and gender values, and a separate JSON API for custom tooling.

```bash
dart run anas_localization:anas_cli catalog init
```

```bash
dart run anas_localization:anas_cli catalog serve
```

Read next:

- [Catalog Overview](catalog/index.md)
- [Catalog Architecture](catalog/architecture.md)
- [Catalog Edit and Review Flow](catalog/edit-and-review-flow.md)

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
- recipe pages for setup, migration, and validation flows

## Recommended next pages

- [Install and First Run](get-started/install-and-first-run.md)
- [Generate and Wrap Your App](get-started/generate-and-wrap.md)
- [Catalog Setup and Serve](catalog/setup-and-serve.md)
- [Common CLI Workflows](cli/common-workflows.md)
- [Cookbook Overview](cookbook/index.md)
- [Migration Validation Flow](cookbook/migration-validation.md)
