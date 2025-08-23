/// Utility functions for code generation scripts in the localization package.
library;

/// Converts a snake_case key to camelCase for Dart identifiers (fields/methods).
String snakeToCamel(String key) {
  final parts = key.split('_');
  if (parts.isEmpty) return key;
  return parts.first +
      parts
          .skip(1)
          .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
          .join();
}

/// Converts a snake_case key to PascalCase (for class/type names if needed).
String toPascalCase(String key) {
  final parts = key.split('_');
  return parts
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join();
}

/// Escapes a Dart single-quoted string literal (handles quotes and newlines).
String escapeDartString(String input) {
  return input.replaceAll("'", r"\'").replaceAll('\n', r'\n');
}

/// Checks if a translation string contains parameter placeholders like {name}.
bool hasPlaceholders(String value) {
  return RegExp(r'\{[a-zA-Z0-9_]+\}').hasMatch(value);
}

/// Heuristic: checks if a translation key is likely for pluralization.
bool isPluralKey(String key) {
  return key.endsWith('_plural') || key.contains('count');
}

/// Extracts named placeholders like `{name}`, and also `{name?}` / `{name!}`.
/// Returns the **cleaned** placeholder names **without** the `?` / `!` markers.
Iterable<String> extractPlaceholders(String template) sync* {
  final re = RegExp(r'\{([a-zA-Z0-9_]+)(?:[!?])?\}');
  final seen = <String>{};
  for (final m in re.allMatches(template)) {
    final name = m.group(1)!; // group(1) excludes the marker
    if (seen.add(name)) yield name;
  }
}

/// Sanitizes a string to be a valid Dart identifier.
/// Also converts snake_case to camelCase automatically.
String sanitizeDartIdentifier(String key) {
  // Convert snake_case to camelCase first
  final camelKey = snakeToCamel(key);

  // Remove invalid characters and ensure it starts with letter/underscore
  final sanitized = camelKey.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');

  if (sanitized.isEmpty) return 'field';

  // Ensure it starts with a letter or underscore
  String result = sanitized;
  if (RegExp(r'^[0-9]').hasMatch(result)) {
    result = 'field$result';
  }

  // Handle Dart reserved keywords by appending 'Text'
  if (_dartReservedKeywords.contains(result)) {
    result = '${result}Text';
  }

  return result;
}

/// Generates a documentation comment for a field
/// or method.
String generateDocComment(String text) {
  if (text.isEmpty) return '';

  // Escape any */ that could break the comment
  final escaped = text.replaceAll('*/', r'*\/');
  return '  /// $escaped';
}

/// Set of Dart reserved keywords that cannot be used as identifiers
const Set<String> _dartReservedKeywords = {
  // Dart keywords
  'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
  'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
  'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
  'factory', 'false', 'final', 'finally', 'for', 'function', 'get', 'hide',
  'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
  'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
  'return', 'set', 'show', 'static', 'super', 'switch', 'sync', 'this',
  'throw', 'true', 'try', 'typedef', 'var', 'void', 'while', 'with', 'yield',

  // Built-in identifiers (contextual keywords)
  'Function', 'Never', 'Object', 'Record', 'String', 'bool', 'double', 'int',
};
