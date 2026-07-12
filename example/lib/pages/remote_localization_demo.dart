import 'package:flutter/material.dart';
import 'package:anas_localization/anas_localization.dart' hide Dictionary;

class RemoteLocalizationDemo extends StatefulWidget {
  const RemoteLocalizationDemo({super.key});

  @override
  State<RemoteLocalizationDemo> createState() => _RemoteLocalizationDemoState();
}

class _RemoteLocalizationDemoState extends State<RemoteLocalizationDemo> {
  final _connector = _DemoConnector();
  RemoteLocalizationUpdateResult? _lastResult;
  RemoteLocalizationCacheSnapshot? _cacheSnapshot;
  bool _loading = false;

  static final _supportedLocales = [
    const Locale('en'),
    const Locale('ar'),
    const Locale('tr'),
  ];

  @override
  void initState() {
    super.initState();
    _setupRemote();
  }

  void _setupRemote() {
    AnasLocalization.of(context);
    LocalizationService.configure(
      appAssetPath: 'assets/lang',
      locales: _supportedLocales.map(LocalizationService.localeToCode).toList(),
      fallbackLocaleCode: 'en',
      remote: RemoteLocalizationConfig(
        connector: _connector,
        checkOnStartup: false,
        metrics: null,
      ),
    );
  }

  Future<void> _checkGlobal() async {
    setState(() => _loading = true);
    try {
      final result = await AnasLocalization.remote.checkForUpdates();
      setState(() {
        _lastResult = result;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkLocale(Locale locale) async {
    setState(() => _loading = true);
    try {
      final result = await AnasLocalization.remote.checkForLocaleUpdate(locale);
      setState(() {
        _lastResult = result;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshCache() async {
    try {
      final snapshot = await AnasLocalization.remote.readCache();
      setState(() => _cacheSnapshot = snapshot);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Localization'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConnectorCard(theme),
            const SizedBox(height: 16),
            _buildControlsCard(theme),
            const SizedBox(height: 16),
            if (_lastResult != null) _buildResultCard(theme),
            const SizedBox(height: 16),
            _buildCacheCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectorCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connector', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _row('Supports global check', _connector.supportsGlobalCheck),
            _row('Supports locale check', _connector.supportsLocaleCheck),
            _row('Check delay', '${_connector.delayMs}ms'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Simulate: Updated'),
                  onPressed: () => _connector.setMode(_DemoMode.updated),
                ),
                ActionChip(
                  label: const Text('Simulate: No Update'),
                  onPressed: () => _connector.setMode(_DemoMode.noUpdate),
                ),
                ActionChip(
                  label: const Text('Simulate: Error'),
                  onPressed: () => _connector.setMode(_DemoMode.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Controls', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _checkGlobal,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_sync),
              label: const Text('Check Global Updates'),
            ),
            const SizedBox(height: 12),
            Text('Check per locale:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _supportedLocales
                  .map(
                    (l) => OutlinedButton(
                      onPressed: _loading ? null : () => _checkLocale(l),
                      child: Text(l.toString()),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    final r = _lastResult!;
    return Card(
      color: _statusColor(r.status, theme).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(r.status), color: _statusColor(r.status, theme)),
                const SizedBox(width: 8),
                Text('Result', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            _row('Status', r.status.name),
            _row('Scope', r.scope.name),
            if (r is RemoteLocalizationUpdateSuccess) ...[
              _row('Applied locales', r.appliedLocales.join(', ')),
            ],
            if (r is RemoteLocalizationFailed) ...[
              _row('Error code', r.failure.code.name),
              _row('Message', r.failure.message),
              _row('Retry attempted', '${r.failure.retryAttempted}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCacheCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Cache', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _refreshCache,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_cacheSnapshot == null)
              Text(
                'Tap "Refresh" to load cache',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else ...[
              _row('Entries', '${_cacheSnapshot!.payloads.length}'),
              _row('Last write', _cacheSnapshot!.lastWriteAt?.toIso8601String() ?? 'N/A'),
              for (final entry in _cacheSnapshot!.payloads.entries)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• ${entry.key}: v${entry.value.version.updatedAtUtc.toIso8601String()}'),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await _connector.clearCache();
                  _cacheSnapshot = null;
                  setState(() {});
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear Cache'),
                style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text('$value')),
        ],
      ),
    );
  }

  Color _statusColor(RemoteLocalizationUpdateStatus status, ThemeData theme) {
    switch (status) {
      case RemoteLocalizationUpdateStatus.updated:
        return Colors.green;
      case RemoteLocalizationUpdateStatus.noUpdate:
        return Colors.blue;
      case RemoteLocalizationUpdateStatus.failed:
        return theme.colorScheme.error;
      case RemoteLocalizationUpdateStatus.unsupported:
      case RemoteLocalizationUpdateStatus.skippedDuplicate:
        return Colors.orange;
    }
  }

  IconData _statusIcon(RemoteLocalizationUpdateStatus status) {
    switch (status) {
      case RemoteLocalizationUpdateStatus.updated:
        return Icons.check_circle;
      case RemoteLocalizationUpdateStatus.noUpdate:
        return Icons.info;
      case RemoteLocalizationUpdateStatus.failed:
        return Icons.error;
      case RemoteLocalizationUpdateStatus.unsupported:
        return Icons.block;
      case RemoteLocalizationUpdateStatus.skippedDuplicate:
        return Icons.skip_next;
    }
  }
}

enum _DemoMode { updated, noUpdate, error }

class _DemoConnector implements RemoteLocalizationConnector {
  _DemoConnector();

  _DemoMode _mode = _DemoMode.updated;
  int delayMs = 500;
  int _counter = 0;
  final _cache = <String, RemoteLocalizationPayload>{};

  @override
  bool get supportsGlobalCheck => true;

  @override
  bool get supportsLocaleCheck => true;

  void setMode(_DemoMode mode) {
    _mode = mode;
  }

  @override
  Future<RemoteCheckResponse> checkForUpdates(RemoteVersionSnapshot cachedVersions) async {
    await Future.delayed(Duration(milliseconds: delayMs));
    _counter++;

    switch (_mode) {
      case _DemoMode.noUpdate:
        return const RemoteCheckResponse(descriptors: []);
      case _DemoMode.error:
        throw const RemoteLocalizationFailure(
          code: RemoteLocalizationFailureCode.checkFailed,
          message: 'Simulated connection error',
        );
      case _DemoMode.updated:
        return RemoteCheckResponse(
          descriptors: [
            RemoteUpdateDescriptor(
              locale: 'en',
              version: RemoteLocalizationVersion(
                updatedAtUtc: DateTime.now().toUtc(),
                etag: 'v$_counter',
                hash: _randomHash(),
              ),
            ),
            RemoteUpdateDescriptor(
              locale: 'ar',
              version: RemoteLocalizationVersion(
                updatedAtUtc: DateTime.now().toUtc(),
                etag: 'v$_counter',
                hash: _randomHash(),
              ),
            ),
          ],
        );
    }
  }

  @override
  Future<RemoteCheckResponse> checkForLocaleUpdate(
    Locale locale,
    RemoteLocalizationVersion? cachedVersion,
  ) async {
    await Future.delayed(Duration(milliseconds: delayMs));
    _counter++;

    switch (_mode) {
      case _DemoMode.noUpdate:
        return const RemoteCheckResponse(descriptors: []);
      case _DemoMode.error:
        throw const RemoteLocalizationFailure(
          code: RemoteLocalizationFailureCode.checkFailed,
          message: 'Simulated connection error',
        );
      case _DemoMode.updated:
        final code = LocalizationService.localeToCode(locale);
        return RemoteCheckResponse(
          descriptors: [
            RemoteUpdateDescriptor(
              locale: code,
              version: RemoteLocalizationVersion(
                updatedAtUtc: DateTime.now().toUtc(),
                etag: 'v$_counter',
                hash: _randomHash(),
              ),
            ),
          ],
        );
    }
  }

  @override
  Future<RemoteLocalizationPayload> downloadPayload(RemoteUpdateDescriptor descriptor) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _counter++;

    return RemoteLocalizationPayload(
      locale: descriptor.locale,
      version: descriptor.version,
      translations: {
        'remote_greeting': 'Hello from remote (check $_counter)',
        'remote_timestamp': DateTime.now().toIso8601String(),
        'nested': {
          'remote_key': 'Remote value #$_counter',
        },
      },
    );
  }

  Future<void> clearCache() async {
    _cache.clear();
  }

  String _randomHash() => DateTime.now().microsecondsSinceEpoch.toRadixString(16);
}
