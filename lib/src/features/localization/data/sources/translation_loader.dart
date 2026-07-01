library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/http_client_adapter.dart';
import '../../../../core/sdk_utils.dart';
import '../../../../shared/core/localization_exceptions.dart';
import '../../../../shared/utils/arb_interop.dart';
import '../../../../shared/utils/translation_file_parser.dart';

typedef TranslationMap = Map<String, dynamic>;

abstract class TranslationLoader {
  const TranslationLoader();

  String get id;

  List<String> get fileExtensions;

  Future<TranslationMap?> load(String basePath);
}

class TranslationLoaderRegistry {
  TranslationLoaderRegistry([Iterable<TranslationLoader>? loaders]) {
    final source = loaders ?? const [JsonTranslationLoader()];
    for (final loader in source) {
      register(loader);
    }
  }

  factory TranslationLoaderRegistry.withDefaults() {
    return TranslationLoaderRegistry(const [
      JsonTranslationLoader(),
      ArbTranslationLoader(),
      YamlTranslationLoader(),
      CsvTranslationLoader(),
    ]);
  }

  final List<TranslationLoader> _orderedLoaders = <TranslationLoader>[];

  List<TranslationLoader> get loaders => List<TranslationLoader>.unmodifiable(_orderedLoaders);

  void register(TranslationLoader loader, {bool highestPriority = false}) {
    _orderedLoaders.removeWhere((existing) => existing.id == loader.id);
    if (highestPriority) {
      _orderedLoaders.insert(0, loader);
    } else {
      _orderedLoaders.add(loader);
    }
  }

  bool unregister(String loaderId) {
    final before = _orderedLoaders.length;
    _orderedLoaders.removeWhere((loader) => loader.id == loaderId);
    return _orderedLoaders.length != before;
  }

  void resetToDefaults() {
    _orderedLoaders
      ..clear()
      ..addAll(const [
        JsonTranslationLoader(),
        ArbTranslationLoader(),
        YamlTranslationLoader(),
        CsvTranslationLoader(),
      ]);
  }

  Future<TranslationMap?> loadFirst(String basePath) async {
    for (final loader in _orderedLoaders) {
      final loaded = await loader.load(basePath);
      if (loaded != null) {
        return loaded;
      }
    }
    return null;
  }
}

class JsonTranslationLoader extends TranslationLoader {
  const JsonTranslationLoader();

  @override
  String get id => 'json';

  @override
  List<String> get fileExtensions => const ['json'];

  @override
  Future<TranslationMap?> load(String basePath) async {
    final content = await _loadFirstContent(basePath, fileExtensions);
    if (content == null) return null;
    try {
      return TranslationFileParser.parseJsonContent(content);
    } catch (error) {
      debugPrint('Failed to parse JSON translation ($basePath): $error');
    }
    return null;
  }
}

class ArbTranslationLoader extends TranslationLoader {
  const ArbTranslationLoader();

  @override
  String get id => 'arb';

  @override
  List<String> get fileExtensions => const ['arb'];

  @override
  Future<TranslationMap?> load(String basePath) async {
    final content = await _loadFirstContent(basePath, fileExtensions);
    if (content == null) return null;
    try {
      final document = ArbInterop.parseArb(content, fileName: '$basePath.arb');
      return Map<String, dynamic>.from(document.translations);
    } catch (error) {
      debugPrint('Failed to parse ARB translation ($basePath): $error');
    }
    return null;
  }
}

class YamlTranslationLoader extends TranslationLoader {
  const YamlTranslationLoader();

  @override
  String get id => 'yaml';

  @override
  List<String> get fileExtensions => const ['yaml', 'yml'];

  @override
  Future<TranslationMap?> load(String basePath) async {
    final content = await _loadFirstContent(basePath, fileExtensions);
    if (content == null) return null;
    try {
      return TranslationFileParser.parseYamlContent(content);
    } catch (error) {
      debugPrint('Failed to parse YAML translation ($basePath): $error');
    }
    return null;
  }
}

class CsvTranslationLoader extends TranslationLoader {
  const CsvTranslationLoader();

  @override
  String get id => 'csv';

  @override
  List<String> get fileExtensions => const ['csv'];

  @override
  Future<TranslationMap?> load(String basePath) async {
    final content = await _loadFirstContent(basePath, fileExtensions);
    if (content == null) return null;

    try {
      return TranslationFileParser.parseCsvContent(content);
    } catch (error) {
      debugPrint('Failed to parse CSV translation ($basePath): $error');
      return null;
    }
  }
}

class HttpTranslationLoader extends TranslationLoader {
  HttpTranslationLoader({
    required this.baseUrl,
    this.client,
    this.requestHeaders,
    List<String>? fileExtensions,
  }) : _fileExtensions = fileExtensions ?? const ['json'];

  final String baseUrl;
  final HttpClientAdapter? client;
  final Map<String, String>? requestHeaders;
  final List<String> _fileExtensions;

  @override
  String get id => 'http';

  @override
  List<String> get fileExtensions => _fileExtensions;

  @override
  Future<TranslationMap?> load(String basePath) async {
    final normalizedBasePath = _stripExtension(basePath);
    final localeCode = normalizedBasePath.split('/').last;
    final requestClient = client ?? DefaultHttpClient();
    final ownsClient = client == null;

    try {
      Object? lastError;
      int? lastStatusCode;

      for (final extension in fileExtensions) {
        final uri = Uri.parse('$baseUrl/$localeCode.$extension');
        try {
          final response = await requestClient.get(uri, headers: requestHeaders);
          if (!response.isOk) {
            lastStatusCode = response.statusCode;
            continue;
          }

          final body = response.body;
          try {
            return _parseRemoteBody(body, extension);
          } catch (error) {
            throw RemoteTranslationLoadException(
              'Failed to parse remote $extension translation for "$localeCode": $error',
            );
          }
        } on RemoteTranslationLoadException {
          rethrow;
        } catch (error) {
          lastError = error;
        }
      }

      if (lastError != null) {
        throw RemoteTranslationLoadException(
          'Failed to load remote translation for "$localeCode": $lastError',
        );
      }

      if (lastStatusCode != null) {
        debugPrint(
          'Remote translation not found for "$localeCode" (last status: $lastStatusCode).',
        );
      }
      return null;
    } finally {
      if (ownsClient) {
        requestClient.close();
      }
    }
  }
}

TranslationMap _parseRemoteBody(String body, String extension) {
  switch (extension.toLowerCase()) {
    case 'json':
      return TranslationFileParser.parseJsonContent(body);
    case 'yaml':
    case 'yml':
      return TranslationFileParser.parseYamlContent(body);
    case 'csv':
      return TranslationFileParser.parseCsvContent(body);
    case 'arb':
      return Map<String, dynamic>.from(
        ArbInterop.parseArb(body).translations,
      );
    default:
      throw FormatException('Unsupported remote translation extension: $extension');
  }
}

Future<String?> _loadFirstContent(String basePath, List<String> fileExtensions) async {
  final normalizedBasePath = _stripExtension(basePath);
  for (final extension in fileExtensions) {
    final candidatePath = '$normalizedBasePath.$extension';
    try {
      return await rootBundle.loadString(candidatePath);
    } on FlutterError {
      continue;
    } catch (error) {
      debugPrint('Failed to read translation asset ($candidatePath): $error');
      continue;
    }
  }
  return null;
}

String _stripExtension(String basePath) {
  final extensionPattern = RegExp(r'\.(json|arb|yaml|yml|csv)$');
  return basePath.replaceFirst(extensionPattern, '');
}
