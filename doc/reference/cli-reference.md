# CLI Reference

Use this page when you need the available command surface quickly.

## Top-level commands

```text
validate <lang-dir> [options]
add-key <key> <value> [dir]
remove-key <key> [dir]
add-locale <locale> [template-locale] [dir]
translate <key> <locale> <text> [dir]
stats <lang-dir>
catalog <subcommand>
dev --with-catalog -- <cmd>
export <lang-dir> <format> [out]
import <file|dir> <lang-dir>
help
```

## Catalog subcommands

```text
catalog init [--config=<path>]
catalog status [--config=<path>]
catalog serve [--config=<path>] [--host=<host>]
catalog add-key --key=<path> [--value-xx=...]
catalog add-key --values-file=<json>
catalog review --key=<path> --locale=<xx>
catalog delete-key --key=<path>
dev --with-catalog [--config=<path>] -- <cmd> [args]
```

## Notes

- prefer fenced command blocks in task pages when you are following a workflow
- use this page when you only need the command inventory or a quick reminder
- the catalog sidecar on this branch exposes both a browser table UI and a separate JSON API

## Codegen options

```text
localization_gen [--watch] [--modules] [--modules-only] [--module-depth <N>]
                 [--exclude <patterns>]
```

| Option | Description |
|--------|-------------|
| `--watch` | Watch locale files and regenerate on changes |
| `--modules` / `--namespaced` | Generate module classes for namespaced keys |
| `--modules-only` | Only generate module classes (skip root members) |
| `--module-depth <N>` | Depth for module nesting (default: 1) |
| `--exclude <patterns>` | Comma-separated key patterns to exclude (supports `*` glob) |

### Excluding keys from generation

Three ways to exclude keys from the generated dictionary:

1. **CLI flag** — `--exclude "debug,home.*,*_internal"`
2. **Environment variable** — `GEN_EXCLUDE_KEYS="debug,home.*"`
3. **JSON annotation** — add to any locale file:

```json
{
  "@skip": ["internal_key", "debug_info"],
  "welcome": "Welcome"
}
```

Or per-key:

```json
{
  "secret": "Secret",
  "@secret": {"codegen": {"skip": true}}
}
```

Glob patterns: `*` matches any characters. Examples:
- `home.*` — all keys under `home` namespace
- `*_text` — keys ending with `_text`
- `*debug*` — keys containing `debug`

## Next

- [Catalog Commands](../cli/catalog.md)
- [Catalog Architecture](../catalog/architecture.md)
- [Common Workflows](../cli/common-workflows.md)
- [Validate](../cli/validate.md)
