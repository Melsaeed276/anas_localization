import 'remote_localization_failure.dart';

enum RemoteLocalizationScope {
  global,
  locale,
}

enum RemoteLocalizationUpdateStatus {
  updated,
  noUpdate,
  skippedDuplicate,
  unsupported,
  failed,
}

sealed class RemoteLocalizationUpdateResult {
  const RemoteLocalizationUpdateResult({
    required this.scope,
    required this.startedAt,
    required this.completedAt,
  }) : status = RemoteLocalizationUpdateStatus.noUpdate;

  final RemoteLocalizationScope scope;
  final RemoteLocalizationUpdateStatus status;
  final DateTime startedAt;
  final DateTime completedAt;
}

class RemoteLocalizationUpdateSuccess extends RemoteLocalizationUpdateResult {
  const RemoteLocalizationUpdateSuccess({
    required RemoteLocalizationScope scope,
    required DateTime startedAt,
    required DateTime completedAt,
    this.appliedLocales = const [],
  }) : super(scope: scope, startedAt: startedAt, completedAt: completedAt);

  final List<String> appliedLocales;

  @override
  RemoteLocalizationUpdateStatus get status => RemoteLocalizationUpdateStatus.updated;
}

class RemoteLocalizationNoUpdate extends RemoteLocalizationUpdateResult {
  const RemoteLocalizationNoUpdate({
    required RemoteLocalizationScope scope,
    required DateTime startedAt,
    required DateTime completedAt,
  }) : super(scope: scope, startedAt: startedAt, completedAt: completedAt);

  @override
  RemoteLocalizationUpdateStatus get status => RemoteLocalizationUpdateStatus.noUpdate;
}

class RemoteLocalizationSkippedDuplicate extends RemoteLocalizationUpdateResult {
  const RemoteLocalizationSkippedDuplicate({
    required RemoteLocalizationScope scope,
    required DateTime startedAt,
    required DateTime completedAt,
  }) : super(scope: scope, startedAt: startedAt, completedAt: completedAt);

  @override
  RemoteLocalizationUpdateStatus get status => RemoteLocalizationUpdateStatus.skippedDuplicate;
}

class RemoteLocalizationUnsupported extends RemoteLocalizationUpdateResult {
  const RemoteLocalizationUnsupported({
    required RemoteLocalizationScope scope,
    required DateTime startedAt,
    required DateTime completedAt,
  }) : super(scope: scope, startedAt: startedAt, completedAt: completedAt);

  @override
  RemoteLocalizationUpdateStatus get status => RemoteLocalizationUpdateStatus.unsupported;
}

class RemoteLocalizationFailed extends RemoteLocalizationUpdateResult {
  const RemoteLocalizationFailed({
    required RemoteLocalizationScope scope,
    required DateTime startedAt,
    required DateTime completedAt,
    required this.failure,
  }) : super(scope: scope, startedAt: startedAt, completedAt: completedAt);

  final RemoteLocalizationFailure failure;

  @override
  RemoteLocalizationUpdateStatus get status => RemoteLocalizationUpdateStatus.failed;
}
