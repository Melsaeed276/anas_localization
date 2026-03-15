# File Structure

Use this page when you want a recommended project layout or need to verify where generated and source files should live.

## Recommended layout

```text
assets/
  lang/
    en.json
    ar.json
lib/
  generated/
    dictionary.dart
  main.dart
anas_catalog.yaml
```

## Notes

- keep source locale files in `assets/lang` unless you need a custom `assetPath`
- generated dictionary output typically lives in `lib/generated/dictionary.dart`
- catalog state stays outside runtime code under `.anas_localization/`
- **locale notation**: asset file names use underscored locale codes (e.g. `en_US.json`, `en_GB.json`); user-facing text may use hyphenated forms (e.g. en-US). Regional English overlays (`en_US`, `en_GB`, `en_CA`, `en_AU`) layer on top of a shared `en.json` base

## Next

- [Generate and Wrap Your App](../get-started/generate-and-wrap.md)
- [Config Reference](config-reference.md)
