import 'dart:ui' show Locale;

import '../domain/contracts/remote_localization_service_contract.dart';
import '../domain/entities/remote_localization_result.dart';

class CheckLocaleRemoteLocalizationUpdate {
  const CheckLocaleRemoteLocalizationUpdate({
    required RemoteLocalizationService remoteService,
  }) : _remoteService = remoteService;

  final RemoteLocalizationService _remoteService;

  Future<RemoteLocalizationUpdateResult> call(Locale locale) {
    return _remoteService.checkForLocaleUpdate(locale);
  }
}
