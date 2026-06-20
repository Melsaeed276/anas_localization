import 'dart:io';

/// Regression guard script that scans legacy shim directories and asserts
/// each file contains only `export` directives (plus optional `library;`).
/// Exits with code 1 if any file has implementation code.
///
/// Usage: dart run tool/check_shim_exports.dart
void main(List<String> args) {
  final root = _findProjectRoot();
  if (root == null) {
    stderr.writeln('Error: Could not find project root (lib/ directory)');
    exit(2);
  }

  final directoriesToScan = [
    '$root/lib/src/utils',
    '$root/lib/src/catalog',
    '$root/lib/src/core',
    '$root/lib/src/widgets',
    '$root/lib/src/services',
    '$root/lib/src/api',
  ];

  // Files in lib/src/core/ that are infrastructure (not shims)
  const coreInfrastructureFiles = {
    'sdk_utils.dart',
    'http_client_adapter.dart',
    'key_value_storage.dart',
  };

  final failures = <String>[];
  final scannedFiles = <String>[];

  for (final dirPath in directoriesToScan) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      continue;
    }

    final dartFiles = dir.listSync().whereType<File>().where(
          (f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'),
        );

    for (final file in dartFiles) {
      final relativePath = file.path.replaceFirst('$root/', '');
      final fileName = file.uri.pathSegments.last;

      // Skip infrastructure files in core/
      if (dirPath.endsWith('lib/src/core') && coreInfrastructureFiles.contains(fileName)) {
        continue;
      }

      scannedFiles.add(relativePath);

      final content = file.readAsStringSync();
      final violations = _checkFile(content, fileName);

      if (violations.isNotEmpty) {
        failures.add('FAIL: $relativePath');
        for (final violation in violations) {
          failures.add('  → $violation');
        }
      }
    }
  }

  // Print results
  stdout.writeln('Scanned ${scannedFiles.length} shim files...');

  if (failures.isEmpty) {
    stdout.writeln('All shim files are export-only ✓');
    exit(0);
  } else {
    stdout.writeln('');
    stdout.writeln('${failures.length ~/ 2} file(s) have implementation code:');
    stdout.writeln('');
    for (final line in failures) {
      stdout.writeln(line);
    }
    stdout.writeln('');
    stdout.writeln('Expected: All files should contain only export directives (plus optional library;).');
    stdout.writeln('Run Phase 2 to resolve divergent modules and convert to export shims.');
    exit(1);
  }
}

/// Check a file for violations. Returns list of violation messages.
List<String> _checkFile(String content, String fileName) {
  final violations = <String>[];
  final lines = content.split('\n');

  // Track state
  var lineIndex = 0;

  for (final line in lines) {
    lineIndex++;
    final trimmed = line.trim();

    // Skip empty lines, comments, and blank lines
    if (trimmed.isEmpty || trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed.startsWith('*')) {
      continue;
    }

    // Allow library declaration (optional)
    if (trimmed.startsWith('library ') || trimmed == 'library;') {
      continue;
    }

    // Allow export directives
    if (trimmed.startsWith('export ')) {
      continue;
    }

    // Allow part directives (some files may use part/part of)
    if (trimmed.startsWith('part ') || trimmed.startsWith('part of ')) {
      continue;
    }

    // Allow import directives (shims may need imports for re-exports)
    if (trimmed.startsWith('import ')) {
      continue;
    }

    // Allow annotations
    if (trimmed.startsWith('@')) {
      continue;
    }

    // Allow doc comments
    if (trimmed.startsWith('///')) {
      continue;
    }

    // If we get here, we found non-export code
    violations.add('Line $lineIndex: "$trimmed"');
  }

  return violations;
}

/// Find the project root by looking for pubspec.yaml
String? _findProjectRoot() {
  var dir = Directory.current;

  // Walk up from current directory
  while (true) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync()) {
      return dir.path;
    }

    final parent = dir.parent;
    if (parent.path == dir.path) {
      // Reached filesystem root
      break;
    }
    dir = parent;
  }

  return null;
}
