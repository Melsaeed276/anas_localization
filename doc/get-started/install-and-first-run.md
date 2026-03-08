# Install and First Run

Use this page when you are starting from an existing Flutter app and want the minimum package setup.

## Prerequisites

- Flutter SDK installed
- a Flutter app with a standard `lib/` layout

## 1. Add the package

```bash
flutter pub add anas_localization
```

## 2. Create the locale folder

```bash
mkdir -p assets/lang
```

## 3. Add your first locale file

```json
{
  "app_name": "My App",
  "home": {
    "title": "Home"
  }
}
```

Save that as `assets/lang/en.json`.

## Notes

- `assets/lang` is the default asset folder used by the package.
- You can change the folder later with `assetPath`.

## Next

- [Add Translations and Assets](translations-and-assets.md)
- [Generate and Wrap Your App](generate-and-wrap.md)
