import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/contracts/remote_localization_cache_store.dart';
import '../../domain/entities/remote_localization_cache_snapshot.dart';
import '../../domain/entities/remote_localization_payload.dart';
import 'remote_localization_cache_codec.dart';

class RemoteLocalizationFileCacheStore implements RemoteLocalizationCacheStore {
  RemoteLocalizationFileCacheStore({
    RemoteLocalizationCacheCodec? codec,
    String? directoryPath,
  })  : _codec = codec ?? const RemoteLocalizationCacheCodec(),
        _directoryPath = directoryPath;

  final RemoteLocalizationCacheCodec _codec;
  final String? _directoryPath;

  RemoteLocalizationCacheSnapshot? _memoryFallback;

  Future<String> _getCacheDirPath() async {
    final dirPath = _directoryPath ??
        p.join(
          (await getApplicationCacheDirectory()).path,
          'anas_localization',
          'remote_cache',
        );
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dirPath;
  }

  String _cacheFilePath(String dirPath) {
    return p.join(dirPath, 'remote_cache.json');
  }

  @override
  Future<RemoteLocalizationCacheSnapshot?> read() async {
    final dirPath = await _getCacheDirPath();
    final file = File(_cacheFilePath(dirPath));

    try {
      if (await file.exists()) {
        final data = await file.readAsString();
        final decoded = _codec.decodeCacheSnapshot(data);
        if (decoded != null) {
          _memoryFallback = decoded;
          return decoded;
        }
      }
    } catch (_) {}

    return _memoryFallback;
  }

  @override
  Future<bool> write(RemoteLocalizationPayload payload) async {
    final dirPath = await _getCacheDirPath();
    final file = File(_cacheFilePath(dirPath));

    try {
      final existing = await read();
      final payloads = Map<String, RemoteLocalizationPayload>.from(
        existing?.payloads ?? {},
      );
      payloads[payload.locale] = payload;

      final snapshot = RemoteLocalizationCacheSnapshot(
        payloads: payloads,
        lastWriteAt: DateTime.now(),
      );

      await file.writeAsString(_codec.encodeCacheSnapshot(snapshot));
      _memoryFallback = snapshot;
      return true;
    } catch (_) {
      _memoryFallback ??= RemoteLocalizationCacheSnapshot(
        payloads: {payload.locale: payload},
        fallbackMode: 'memory',
      );
      return false;
    }
  }

  @override
  Future<void> clear() async {
    _memoryFallback = null;
    try {
      final dirPath = await _getCacheDirPath();
      final file = File(_cacheFilePath(dirPath));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  @override
  Future<RemoteLocalizationCacheSnapshot> snapshot() async {
    final cached = await read();
    return cached ?? const RemoteLocalizationCacheSnapshot(payloads: {});
  }
}
