/// Core SDK utilities that replace external package dependencies.
///
/// This file provides SDK-native implementations for common operations
/// that would otherwise require external packages like `path`, `crypto`, etc.
library;

import 'dart:convert';

/// Path manipulation utilities using pure Dart string operations.
///
/// Replaces the `path` package for basic path operations.
/// Uses forward slashes as the canonical separator (works on all platforms).
abstract final class PathUtils {
  /// Joins path segments with forward slashes.
  ///
  /// ```dart
  /// PathUtils.join('assets', 'lang', 'en.json'); // 'assets/lang/en.json'
  /// ```
  static String join(
    String part1, [
    String? part2,
    String? part3,
    String? part4,
    String? part5,
    String? part6,
    String? part7,
    String? part8,
  ]) {
    final parts = [part1, part2, part3, part4, part5, part6, part7, part8].whereType<String>();
    return parts.map(_normalize).where((s) => s.isNotEmpty).join('/');
  }

  /// Joins a list of path segments.
  ///
  /// ```dart
  /// PathUtils.joinAll(['assets', 'lang', 'en.json']); // 'assets/lang/en.json'
  /// ```
  static String joinAll(Iterable<String> parts) {
    return parts.map(_normalize).where((s) => s.isNotEmpty).join('/');
  }

  /// Returns the last component of a path.
  ///
  /// ```dart
  /// PathUtils.basename('/path/to/file.txt'); // 'file.txt'
  /// ```
  static String basename(String path) {
    final normalized = _normalize(path);
    if (normalized.isEmpty) return '';
    final parts = normalized.split('/');
    return parts.lastWhere((p) => p.isNotEmpty, orElse: () => '');
  }

  /// Returns the path without the final component.
  ///
  /// ```dart
  /// PathUtils.dirname('/path/to/file.txt'); // '/path/to'
  /// ```
  static String dirname(String path) {
    final normalized = _normalize(path);
    if (normalized.isEmpty) return '.';
    final lastSlash = normalized.lastIndexOf('/');
    if (lastSlash < 0) return '.';
    if (lastSlash == 0) return '/';
    return normalized.substring(0, lastSlash);
  }

  /// Returns the file extension including the dot.
  ///
  /// ```dart
  /// PathUtils.extension('file.txt'); // '.txt'
  /// PathUtils.extension('file'); // ''
  /// ```
  static String extension(String path) {
    final base = basename(path);
    final dotIndex = base.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == 0) return '';
    return base.substring(dotIndex);
  }

  /// Returns the path without the extension.
  ///
  /// ```dart
  /// PathUtils.withoutExtension('path/to/file.txt'); // 'path/to/file'
  /// ```
  static String withoutExtension(String path) {
    final ext = extension(path);
    if (ext.isEmpty) return path;
    return path.substring(0, path.length - ext.length);
  }

  /// Checks if a path is absolute.
  ///
  /// ```dart
  /// PathUtils.isAbsolute('/path/to/file'); // true
  /// PathUtils.isAbsolute('relative/path'); // false
  /// ```
  static bool isAbsolute(String path) {
    if (path.isEmpty) return false;
    // Unix absolute
    if (path.startsWith('/')) return true;
    // Windows absolute (e.g., C:\)
    if (path.length >= 3 && path[1] == ':' && (path[2] == '/' || path[2] == r'\')) {
      return true;
    }
    return false;
  }

  /// Returns the file name without its extension.
  ///
  /// ```dart
  /// PathUtils.basenameWithoutExtension('path/to/file.txt'); // 'file'
  /// PathUtils.basenameWithoutExtension('file.tar.gz'); // 'file.tar'
  /// ```
  static String basenameWithoutExtension(String path) {
    final base = basename(path);
    final ext = extension(path);
    if (ext.isEmpty) return base;
    return base.substring(0, base.length - ext.length);
  }

  /// Normalizes a path by resolving `.` and `..` segments.
  ///
  /// ```dart
  /// PathUtils.normalize('a/b/../c'); // 'a/c'
  /// PathUtils.normalize('./a/./b'); // 'a/b'
  /// ```
  static String normalize(String path) {
    final normalized = _normalize(path);
    final segments = normalized.split('/');
    final result = <String>[];
    final isAbsolutePath = normalized.startsWith('/');

    for (final segment in segments) {
      if (segment == '.' || segment.isEmpty) {
        continue;
      }
      if (segment == '..') {
        if (result.isNotEmpty && result.last != '..') {
          result.removeLast();
        } else if (!isAbsolutePath) {
          result.add('..');
        }
        continue;
      }
      result.add(segment);
    }

    final joined = result.join('/');
    if (isAbsolutePath) return '/$joined';
    return joined.isEmpty ? '.' : joined;
  }

  /// Computes the relative path from [from] to [path].
  ///
  /// ```dart
  /// PathUtils.relative('/a/b/c', from: '/a'); // 'b/c'
  /// PathUtils.relative('/a/d', from: '/a/b/c'); // '../../d'
  /// ```
  static String relative(String path, {required String from}) {
    final normalizedPath = normalize(path);
    final normalizedFrom = normalize(from);

    final pathSegments = normalizedPath.split('/').where((s) => s.isNotEmpty).toList();
    final fromSegments = normalizedFrom.split('/').where((s) => s.isNotEmpty).toList();

    // Find common prefix
    var commonLength = 0;
    final minLength = pathSegments.length < fromSegments.length ? pathSegments.length : fromSegments.length;
    while (commonLength < minLength && pathSegments[commonLength] == fromSegments[commonLength]) {
      commonLength++;
    }

    // Build relative path
    final upCount = fromSegments.length - commonLength;
    final result = <String>[
      ...List.filled(upCount, '..'),
      ...pathSegments.sublist(commonLength),
    ];

    return result.isEmpty ? '.' : result.join('/');
  }

  /// Normalizes path separators to forward slashes and removes redundant separators.
  static String _normalize(String path) {
    return path.replaceAll(r'\', '/').replaceAll(RegExp(r'/+'), '/').replaceAll(RegExp(r'/$'), '');
  }
}

/// Simple hash utilities using pure Dart.
///
/// Replaces the `crypto` package for non-cryptographic hashing needs.
/// Uses FNV-1a algorithm which is fast and has good distribution.
abstract final class HashUtils {
  /// Computes a 64-bit FNV-1a hash of a string.
  ///
  /// Returns a hex string representation of the hash.
  /// This is suitable for content change detection but NOT for cryptographic purposes.
  ///
  /// ```dart
  /// HashUtils.fnv1a('hello world'); // Returns consistent hex hash
  /// ```
  static String fnv1a(String input) {
    final bytes = utf8.encode(input);
    return fnv1aBytes(bytes);
  }

  /// Computes a 64-bit FNV-1a hash of bytes.
  ///
  /// Returns a hex string representation of the hash.
  static String fnv1aBytes(List<int> bytes) {
    // FNV-1a 64-bit constants
    const int fnvPrime = 0x00000100000001B3;
    const int fnvOffsetBasis = 0xcbf29ce484222325;

    var hash = fnvOffsetBasis;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }

  /// Computes a simple 32-bit hash suitable for basic change detection.
  ///
  /// Faster than FNV-1a but with less distribution quality.
  static int simple32(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }
}

/// HTTP response from [HttpClientAdapter].
class SimpleHttpResponse {
  const SimpleHttpResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;

  bool get isOk => statusCode >= 200 && statusCode < 300;
}

/// Abstract HTTP client interface for cross-platform HTTP requests.
///
/// This abstraction allows dependency injection of HTTP clients,
/// enabling users to use their preferred HTTP implementation
/// (e.g., `http` package, `dio`, or platform-specific clients).
///
/// Example usage:
/// ```dart
/// // Use the default implementation
/// final client = DefaultHttpClient();
///
/// // Or inject a custom implementation
/// final customClient = MyCustomHttpClient();
/// final loader = HttpTranslationLoader(client: customClient);
/// ```
abstract interface class HttpClientAdapter {
  /// Performs a GET request to the specified [uri].
  ///
  /// Optional [headers] can be provided for the request.
  /// Returns a [SimpleHttpResponse] containing the response data.
  Future<SimpleHttpResponse> get(Uri uri, {Map<String, String>? headers});

  /// Performs a POST request to the specified [uri].
  ///
  /// Optional [headers] and [body] can be provided for the request.
  /// Returns a [SimpleHttpResponse] containing the response data.
  Future<SimpleHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  });

  /// Performs a PATCH request to the specified [uri].
  ///
  /// Optional [headers] and [body] can be provided for the request.
  /// Returns a [SimpleHttpResponse] containing the response data.
  Future<SimpleHttpResponse> patch(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  });

  /// Performs a DELETE request to the specified [uri].
  ///
  /// Optional [headers] and [body] can be provided for the request.
  /// Returns a [SimpleHttpResponse] containing the response data.
  Future<SimpleHttpResponse> delete(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  });

  /// Closes the client and releases any resources.
  void close();
}
