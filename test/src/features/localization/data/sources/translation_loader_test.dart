import 'package:anas_localization/anas_localization.dart';
import 'package:anas_localization/src/core/sdk_utils.dart';
import 'package:anas_localization/src/features/localization/domain/repositories/localization_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _MapTranslationLoader extends TranslationLoader {
  _MapTranslationLoader(this._data);

  final Map<String, Map<String, dynamic>> _data;

  @override
  String get id => 'test_map';

  @override
  List<String> get fileExtensions => const ['json'];

  @override
  Future<Map<String, dynamic>?> load(String basePath) async {
    return _data[basePath];
  }
}

class _PresetTranslationLoader extends TranslationLoader {
  const _PresetTranslationLoader({
    required String id,
    required List<String> extensions,
    required Map<String, dynamic>? result,
  })  : _id = id,
        _extensions = extensions,
        _result = result;

  final String _id;
  final List<String> _extensions;
  final Map<String, dynamic>? _result;

  @override
  String get id => _id;

  @override
  List<String> get fileExtensions => _extensions;

  @override
  Future<Map<String, dynamic>?> load(String basePath) async => _result;
}

class _MockHttpClient implements HttpClientAdapter {
  _MockHttpClient(this._handler);

  final Future<SimpleHttpResponse> Function(Uri uri) _handler;

  @override
  Future<SimpleHttpResponse> delete(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) =>
      throw UnimplementedError();

  @override
  Future<SimpleHttpResponse> get(Uri uri, {Map<String, String>? headers}) => _handler(uri);

  @override
  Future<SimpleHttpResponse> patch(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) =>
      throw UnimplementedError();

  @override
  Future<SimpleHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) =>
      throw UnimplementedError();

  @override
  void close() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocalizationService().clear();
    LocalizationService.clearPreviewDictionaries();
    LocalizationService.resetTranslationLoaders();
    LocalizationService.setFallbackLocaleCode('en');
    LocalizationService.supportedLocales = ['en'];
  });

  test('LocalizationService implements LocalizationRepository', () {
    expect(LocalizationService(), isA<LocalizationRepository>());
  });

  test('app translations override package translations for the same key', () async {
    LocalizationService.setTranslationLoaders([
      _MapTranslationLoader({
        'assets/lang/en': {'greeting': 'from app'},
        'packages/anas_localization/assets/lang/en': {
          'greeting': 'from package',
          'packageOnly': 'pkg',
        },
      }),
    ]);

    await LocalizationService().loadLocale('en');

    final dictionary = LocalizationService().currentDictionary;
    expect(dictionary.getString('greeting'), 'from app');
    expect(dictionary.getString('packageOnly'), 'pkg');
  });

  group('TranslationLoaderRegistry', () {
    test('default constructor registers all built-in loaders', () {
      final registry = TranslationLoaderRegistry();
      expect(
        registry.loaders.map((loader) => loader.id),
        ['json', 'arb', 'yaml', 'csv'],
      );
    });

    test('withDefaults matches the default constructor', () {
      final registry = TranslationLoaderRegistry.withDefaults();
      expect(
        registry.loaders.map((loader) => loader.id),
        TranslationLoaderRegistry().loaders.map((loader) => loader.id),
      );
    });

    test('loadFirst prefers the first loader that returns data', () async {
      final registry = TranslationLoaderRegistry(const [
        _PresetTranslationLoader(
          id: 'json',
          extensions: ['json'],
          result: {'greeting': 'from json'},
        ),
        _PresetTranslationLoader(
          id: 'arb',
          extensions: ['arb'],
          result: {'greeting': 'from arb'},
        ),
      ]);

      final loaded = await registry.loadFirst('assets/lang/en');

      expect(loaded?['greeting'], 'from json');
    });
  });

  group('asset loaders', () {
    test('ArbTranslationLoader exposes ARB extensions and strips metadata', () {
      const loader = ArbTranslationLoader();
      expect(loader.id, 'arb');
      expect(loader.fileExtensions, ['arb']);

      const arbContent = '{"@@locale":"en","greeting":"Hello ARB","@greeting":{"description":"Greeting"}}';
      final document = ArbInterop.parseArb(arbContent, fileName: 'en.arb');
      final translations = Map<String, dynamic>.from(document.translations);

      expect(translations['greeting'], 'Hello ARB');
      expect(translations.containsKey('@greeting'), isFalse);
    });

    test('YamlTranslationLoader prefers .yaml before .yml', () {
      const loader = YamlTranslationLoader();
      expect(loader.fileExtensions, ['yaml', 'yml']);
    });
  });

  group('HttpTranslationLoader', () {
    test('parses YAML responses', () async {
      final loader = HttpTranslationLoader(
        baseUrl: 'https://example.com/lang',
        client: _MockHttpClient((uri) async {
          expect(uri.path, '/lang/en.yaml');
          return const SimpleHttpResponse(
            statusCode: 200,
            body: 'greeting: Hello YAML',
          );
        }),
        fileExtensions: const ['yaml'],
      );

      final loaded = await loader.load('assets/lang/en');
      expect(loaded?['greeting'], 'Hello YAML');
    });

    test('parses CSV responses', () async {
      final loader = HttpTranslationLoader(
        baseUrl: 'https://example.com/lang',
        client: _MockHttpClient((uri) async {
          expect(uri.path, '/lang/en.csv');
          return const SimpleHttpResponse(
            statusCode: 200,
            body: 'key,value\ngreeting,Hello CSV',
          );
        }),
        fileExtensions: const ['csv'],
      );

      final loaded = await loader.load('assets/lang/en');
      expect(loaded?['greeting'], 'Hello CSV');
    });

    test('parses ARB responses', () async {
      final loader = HttpTranslationLoader(
        baseUrl: 'https://example.com/lang',
        client: _MockHttpClient((uri) async {
          expect(uri.path, '/lang/en.arb');
          return const SimpleHttpResponse(
            statusCode: 200,
            body: '{"@@locale":"en","greeting":"Hello ARB","@greeting":{"description":"Greeting"}}',
          );
        }),
        fileExtensions: const ['arb'],
      );

      final loaded = await loader.load('assets/lang/en');
      expect(loaded?['greeting'], 'Hello ARB');
      expect(loaded?.containsKey('@greeting'), isFalse);
    });

    test('throws RemoteTranslationLoadException on transport errors', () async {
      final loader = HttpTranslationLoader(
        baseUrl: 'https://example.com/lang',
        client: _MockHttpClient((uri) async {
          throw Exception('network down');
        }),
      );

      await expectLater(
        loader.load('assets/lang/en'),
        throwsA(isA<RemoteTranslationLoadException>()),
      );
    });

    test('throws RemoteTranslationLoadException on parse errors', () async {
      final loader = HttpTranslationLoader(
        baseUrl: 'https://example.com/lang',
        client: _MockHttpClient((uri) async {
          return const SimpleHttpResponse(statusCode: 200, body: 'not-json');
        }),
        fileExtensions: const ['json'],
      );

      await expectLater(
        loader.load('assets/lang/en'),
        throwsA(isA<RemoteTranslationLoadException>()),
      );
    });

    test('returns null when remote file is missing', () async {
      final loader = HttpTranslationLoader(
        baseUrl: 'https://example.com/lang',
        client: _MockHttpClient((uri) async {
          return const SimpleHttpResponse(statusCode: 404, body: 'not found');
        }),
      );

      final loaded = await loader.load('assets/lang/en');
      expect(loaded, isNull);
    });
  });

  group('default supported locales', () {
    test('bundled defaults match shipped asset locales', () {
      expect(
        LocalizationService.defaultSupportedLocales,
        containsAll([
          'en',
          'en_US',
          'en_AU',
          'tr',
          'ar',
          'ar_SA',
          'es',
          'hi',
          'zh',
          'zh_CN',
        ]),
      );
      expect(LocalizationService.defaultSupportedLocales, isNot(contains('en_GB')));
      expect(LocalizationService.defaultSupportedLocales, isNot(contains('en_CA')));
    });
  });
}
