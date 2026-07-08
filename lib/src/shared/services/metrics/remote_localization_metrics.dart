import 'dart:ui' show Locale;

enum RemoteLocalizationMetric {
  check,
  download,
  cacheHit,
  cacheMiss,
  failure,
}

abstract interface class RemoteLocalizationMetrics {
  void increment(RemoteLocalizationMetric metric, {Locale? locale});
}

class NoOpRemoteLocalizationMetrics implements RemoteLocalizationMetrics {
  const NoOpRemoteLocalizationMetrics();

  @override
  void increment(RemoteLocalizationMetric metric, {Locale? locale}) {}
}
