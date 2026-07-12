import '../domain/contracts/remote_localization_service_contract.dart';
import '../domain/entities/remote_localization_result.dart';

class CheckGlobalRemoteLocalizationUpdate {
  const CheckGlobalRemoteLocalizationUpdate({
    required RemoteLocalizationService remoteService,
  }) : _remoteService = remoteService;

  final RemoteLocalizationService _remoteService;

  Future<RemoteLocalizationUpdateResult> call() {
    return _remoteService.checkForUpdates();
  }
}
