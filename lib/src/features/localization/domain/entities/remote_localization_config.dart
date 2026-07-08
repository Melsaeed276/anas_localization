import '../contracts/remote_localization_connector.dart';
import '../contracts/remote_localization_cache_store.dart';
import 'remote_localization_metrics.dart';

class RemoteLocalizationConfig {
  const RemoteLocalizationConfig({
    required this.connector,
    this.checkOnStartup = false,
    this.cacheStore,
    this.metrics,
  });

  final RemoteLocalizationConnector connector;
  final bool checkOnStartup;
  final RemoteLocalizationCacheStore? cacheStore;
  final RemoteLocalizationMetrics? metrics;

  Duration get timeout => const Duration(seconds: 10);
  int get retryCount => 1;
  Duration get retryBackoff => const Duration(seconds: 2);
}
