# Import and Export

Use this page when you need to move translations between JSON, CSV, ARB, or `l10n.yaml` driven projects.

## Export JSON

```bash
dart run anas_localization:anas_cli export assets/lang json translations_export.json
```

## Export ARB

```bash
dart run anas_localization:anas_cli export assets/lang arb lib/l10n
```

## Import JSON, CSV, ARB, or `l10n.yaml`

```bash
dart run anas_localization:anas_cli import translations_export.json assets/lang
dart run anas_localization:anas_cli import l10n.yaml assets/lang
```

## Notes

- use these commands to normalize source material before generation
- for migrations, validate the resulting `assets/lang` folder immediately after import

## Next

- [Migration Strategy](../migrate/migration-strategy.md)
- [CLI Reference](../reference/cli-reference.md)
