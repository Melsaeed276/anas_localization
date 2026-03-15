# Setup and guidelines

Short reference for getting anas_localization running and where to find detailed steps.

## Core setup

- **[Install and First Run](install-and-first-run.md)** — Add the package, run codegen, and see a localized screen.
- **[Add Translations and Assets](translations-and-assets.md)** — Configure locale files and asset paths.
- **[Generate and Wrap Your App](generate-and-wrap.md)** — Generate the dictionary and wrap your app with `AnasLocalization`.

## Validation and CLI

- **Validate** — Run `dart run anas_localization:anas_cli validate assets/lang` (or your locale path). See [CLI Validate](../cli/validate.md) and [Common Workflows](../cli/common-workflows.md).
- **Import/export** — ARB/CSV/JSON import and export: [CLI Import and Export](../cli/import-export.md).

## Catalog (sidecar UI)

- **Catalog setup and serve** — [Catalog Setup and Serve](../catalog/setup-and-serve.md) and [Catalog Overview](../catalog/index.md).

## Right-to-left (RTL) and Arabic

When using Arabic (or another RTL language), wrap your app or Arabic screens with [AnasDirectionalityWrapper](https://pub.dev/documentation/anas_localization/latest/anas_localization/AnasDirectionalityWrapper-class.html) so layout and text flow are right-to-left. Use the current locale (e.g. `Localizations.localeOf(context)` or your app’s locale) so that when Arabic is active, `Directionality` is set to RTL. Mixed content (numbers, URLs, emails) will then follow Flutter’s bidirectional behavior. See [Quickstart: Arabic](https://github.com/Melsaeed276/anas_localization/blob/main/specs/002-arabic-localization-support/quickstart.md) for full steps.

**Supported Arabic regions**: The package supports full locale (e.g. `ar_SA`, `ar_EG`, `ar_MA`, `ar_AE`, `ar_DZ`, `ar_TN`, `ar_LB`, `ar_JO`, `ar_IQ`) for resolution and formatting. Use full locale so number and date formatting follow the region (e.g. Eastern Arabic numerals in Saudi, Western in Morocco).

**Numbers and dates**: Pass the full locale to `AnasNumberFormatter` and `AnasDateTimeFormatter` (or to `NumberFormat`/`DateFormat`). Eastern vs Western Arabic numerals and separators are determined by the locale via `intl`; no extra configuration is required.

## Next steps

- [Get Started overview](index.md)
- [Package features](../reference/features.md) — What the package does and how to enable each capability.
