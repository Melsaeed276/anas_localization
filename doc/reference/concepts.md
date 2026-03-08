# Concepts

Use this page when you want the package model explained without being inside a specific tutorial.

## Core ideas

- `AnasLocalization` is the runtime wrapper that holds locale state
- `Dictionary` is the translation object used at runtime
- generated dictionaries provide typed accessors for your keys
- `previewDictionaries` let you bypass bundled assets in tests and previews
- the catalog is a separate sidecar, not part of your Flutter runtime

## Typical app flow

```text
locale files -> validate -> generate dictionary -> wrap app -> read translations
```

## Runtime access model

- use `getDictionary()` for generated, typed reads
- use `context.dict` for raw key lookups or when you need the scope object
- use `AnasLocalization.of(context).setLocale(...)` for locale changes

## Next

- [Read Translations](../use-in-app/read-translations.md)
- [Config Reference](config-reference.md)
