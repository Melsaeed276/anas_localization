/// Domain configurator for LocalizationService.
///
/// This class provides a way to configure the localization service
/// without exposing the concrete LocalizationService class to features.
library;

/// Configuration options for the localization service.
class LocalizationConfig {
  const LocalizationConfig({
    this.appAssetPath,
    this.locales,
    this.previewDictionaries,
    this.fallbackLocaleCode,
  });

  final String? appAssetPath;
  final List<String>? locales;
  final Map<String, Map<String, dynamic>>? previewDictionaries;
  final String? fallbackLocaleCode;
}

/// Abstract configurator for localization service.
///
/// Features depend on this interface instead of the concrete LocalizationService
/// to maintain feature boundary compliance.
abstract interface class LocalizationConfiguratorContract {
  /// Configure the localization service with the given options.
  void configureService(LocalizationConfig config);
}
