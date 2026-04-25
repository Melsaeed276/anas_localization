# Quickstart: Regenerate & Validate Typed Dictionary

## Regenerate the example’s typed dictionary
From the repo root:
`dart run anas_localization:anas update --gen`

This should regenerate:
`example/lib/generated/dictionary.dart`

If you ever need to force override input explicitly (for debugging), you can also run:
`APP_LANG_DIR=example/assets/lang dart run anas_localization:anas update --gen`

## Validate
1. Static analysis:
   - `dart analyze`
2. Tests:
   - `flutter test`
3. Example app compile-time sanity:
   - ensure `example/lib/main.dart` no longer has missing typed accessor errors

## Expected results
- Generated `dictionary.dart` contains typed accessors for the keys present in `example/assets/lang/*.json`.
- Runtime-lookup behavior remains covered by existing tests.

