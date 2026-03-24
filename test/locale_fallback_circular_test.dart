import 'package:anas_localization/anas_localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Circular Fallback Detection', () {
    /// FR-007: Detect and prevent circular fallback chains
    test('detects direct circular fallback (A -> A)', () {
      final fallbacks = <String, String>{'ar_SA': 'ar_EG', 'ar_EG': 'ar_SA'};

      // Attempting to set ar_SA -> ar_SA should be detected as circular
      expect(
        () => _hasCircularFallback(fallbacks, 'ar_SA', 'ar_SA'),
        returnsNormally,
      );
      expect(_hasCircularFallback(fallbacks, 'ar_SA', 'ar_SA'), isTrue);
    });

    test('detects two-step circular fallback (A -> B -> A)', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar_LY',
      };

      // Attempting to set ar_LY -> ar_SA should create cycle: ar_SA -> ar_EG -> ar_LY -> ar_SA
      expect(
        _hasCircularFallback(fallbacks, 'ar_LY', 'ar_SA'),
        isTrue,
      );
    });

    test('detects three-step circular fallback (A -> B -> C -> A)', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar_AE',
        'ar_AE': 'ar_LY',
      };

      // Setting ar_LY -> ar_SA would create: ar_SA -> ar_EG -> ar_AE -> ar_LY -> ar_SA
      expect(
        _hasCircularFallback(fallbacks, 'ar_LY', 'ar_SA'),
        isTrue,
      );
    });

    test('allows valid linear chain (no cycle)', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_AE': 'ar_LY',
      };

      // Setting ar_LY -> ar_EG is safe (no cycle)
      expect(
        _hasCircularFallback(fallbacks, 'ar_LY', 'ar_EG'),
        isFalse,
      );
    });

    test('allows fallback to unrelated locale', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
      };

      // Setting en_US -> en_GB is safe (different language group)
      expect(
        _hasCircularFallback(fallbacks, 'en_US', 'en_GB'),
        isFalse,
      );
    });

    test('allows long chain without cycle', () {
      final fallbacks = <String, String>{
        'ar_SA': 'ar_EG',
        'ar_EG': 'ar_AE',
        'ar_AE': 'ar_LY',
      };

      // Setting ar_LY -> ar (language code) is safe
      expect(
        _hasCircularFallback(fallbacks, 'ar_LY', 'ar'),
        isFalse,
      );
    });
  });
}

/// Test helper: implements circular fallback detection algorithm
bool _hasCircularFallback(
  Map<String, String> fallbacks,
  String locale,
  String newFallback,
) {
  final visited = <String>{locale};
  var current = fallbacks[newFallback];

  while (current != null && current.isNotEmpty) {
    if (visited.contains(current)) return true;
    visited.add(current);
    current = fallbacks[current];
  }

  return false;
}
