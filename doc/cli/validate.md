# Validate

Use this page when you want to check translation consistency before generation, testing, or release.

## Basic validation

```bash
dart run anas_localization:anas_cli validate assets/lang
```

## Strict validation

```bash
dart run anas_localization:anas_cli validate assets/lang --profile=strict --fail-on-warnings
```

## Validation with placeholder schema

```bash
dart run anas_localization:anas_cli validate assets/lang --schema-file=assets/lang/placeholder_schema.json
```

## Disable selected rules

```bash
dart run anas_localization:anas_cli validate assets/lang --disable=placeholders,gender
```

## Next

- [CLI Reference](../reference/cli-reference.md)
- [CI Patterns](../testing/ci-patterns.md)
