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

## Next

- [Catalog Commands](../cli/catalog.md)
- [Catalog Architecture](../catalog/architecture.md)
- [Common Workflows](../cli/common-workflows.md)
- [Validate](../cli/validate.md)
