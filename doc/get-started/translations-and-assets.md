# Add Translations and Assets

Use this page when you want a clean starting translation layout and the correct asset registration.

## Recommended folder structure

```text
assets/lang/en.json
assets/lang/ar.json
assets/lang/tr.json
```

## Example locale file

```json
{
  "app_name": "My App",
  "welcome_user": "Welcome {name}",
  "home": {
    "title": "Home"
  }
}
```

## Register the folder in `pubspec.yaml`

```yaml
flutter:
  assets:
    - assets/lang/
```

## Notes

- Use JSON as the app runtime format unless you have a strong reason to load something else.
- Keep keys stable before generating your dictionary API.

## Next

- [Generate and Wrap Your App](generate-and-wrap.md)
- [Read Translations](../use-in-app/read-translations.md)
