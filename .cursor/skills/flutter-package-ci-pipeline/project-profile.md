# Project Profile Template

Copy this block when adapting the pipeline to a new project. Replace all `{{PLACEHOLDER}}` values.

```yaml
# ── Identity ──────────────────────────────────────────
package_name: "{{PACKAGE_NAME}}"           # e.g. my_flutter_pkg
pub_dev_package: "{{PUB_DEV_NAME}}"        # usually same as package_name
github_owner: "{{GITHUB_OWNER}}"
github_repo: "{{GITHUB_REPO}}"
default_branch: "main"                     # or master

# ── README hygiene grep (package-hygiene action) ─────
readme_usage_patterns:
  - "{{PACKAGE_NAME}}"
  - "{{PascalCaseName}}"                    # e.g. MyFlutterPkg

# ── Workspaces (directories with pubspec.yaml) ───────
workspaces:
  root: true
  example: true                            # example/
  extra:                                   # list additional paths
    - "tool/catalog_app"
    # - "packages/foo"

# ── CI toggles ────────────────────────────────────────
features:
  multi_os_pr_matrix: true                 # ubuntu + macos + windows
  semantic_pr: true
  pana_gate: true
  pana_min_score: 130
  license_checker: true
  license_checker_config: "tool/license_checker.yaml"
  changelog_on_version_bump: true
  paths_ignore_docs_only: true             # skip CI on md/doc/specs only
  nightly_cron: false
  github_pages: false
  codecov: false                           # needs CODECOV_TOKEN secret

# ── Code generation drift (riverpod pattern) ─────────
codegen:
  enabled: false
  generate_command: "bash tool/build.sh"   # or dart run build_runner build
  diff_paths:
    - "lib/generated/"
  watch_paths:                             # check-generation.yml path filters
    - "lib/src/**"
    - "tool/build.sh"

# ── Release ───────────────────────────────────────────
release:
  tag_pattern: "v[0-9]+.[0-9]+.[0-9]+*"
  pub_dev_tag_pattern: "v{{version}}"      # pub.dev admin setting
  oidc_publish: true
  github_release: true
  cli_artifacts:                           # empty = no binary release
  #   - bin/my_cli.dart:my_cli-linux-x64
  smoke_checks:                            # release-gate custom steps
    # - "dart run my_pkg:gen --dry-run"

# ── Dependabot ────────────────────────────────────────
dependabot:
  interval: weekly
  day: monday
  pub_directories:
    - "/"
    - "/example"
    # - "/tool/catalog_app"
  github_actions_grouped: true

# ── Docs / ignore paths ───────────────────────────────
paths_ignore:
  - "**.md"
  - "doc/**"
  - "specs/**"
```

## Decision guide

| Question | If yes | If no |
|----------|--------|-------|
| Package publishes to pub.dev? | Add `release-tags.yml` + OIDC setup | Skip publish job |
| Has `example/` app? | `install_example: true` in setup-flutter | Remove example steps |
| Commits generated files? | Add `check-generation.yml` | Skip |
| Ships CLI binaries? | Add `dart compile exe` to github-release job | Skip artifact step |
| Monorepo (3+ packages)? | Consider melos + paths-filter (bloc pattern) | Use single-package composites |
| Private package (no pub.dev)? | Skip pana + publish workflows | Keep analyze/test only |
