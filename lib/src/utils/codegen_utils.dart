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
String sanitizeDartIdentifier(String name) {
  // First convert to camelCase
  var id = snakeToCamel(name);

  // Then sanitize
  if (RegExp(r'^[0-9]').hasMatch(id)) {
    id = '_$id';
  }
  const reservedWords = {
    'abstract','else','import','show','as','enum','in','static','assert','export','interface',
    'super','async','extends','is','switch','await','extension','late','sync','break','external',
    'library','this','case','factory','mixin','throw','catch','false','new','true','class','final',
    'null','try','const','finally','on','typedef','continue','for','operator','var','covariant',
    'Function','part','void','default','get','required','while','deferred','hide','rethrow','with',
    'do','if','return','yield','dynamic','implements','set','String'
  };
  if (reservedWords.contains(id)) {
    id = '${id}Text';
  }
  return id;
}

/// Generates a Dart doc comment for a field/method based on its translation.
String generateDocComment(String translation) {
  return '/// $translation';
}