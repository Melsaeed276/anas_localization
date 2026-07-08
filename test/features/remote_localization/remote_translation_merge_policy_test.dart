import 'package:anas_localization/src/features/remote_localization/domain/services/remote_translation_merge_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('US3: Merge Policy - unprotected precedence', () {
    test('package < app < remote for simple keys', () {
      final result = RemoteTranslationMergePolicy.merge(
        packageData: {'hello': 'bonjour', 'fixed': 'pkg_only'},
        appData: {'hello': 'hola', 'bye': 'adios'},
        remoteData: {'hello': 'ni hao', 'bye': 'zai jian'},
      );

      expect(result['hello'], 'ni hao');
      expect(result['bye'], 'zai jian');
      expect(result['fixed'], 'pkg_only');
    });

    test('empty remote keeps app values', () {
      final result = RemoteTranslationMergePolicy.merge(
        packageData: {},
        appData: {'key': 'app_val'},
        remoteData: {},
      );

      expect(result['key'], 'app_val');
    });

    test('null remote keeps app values', () {
      final result = RemoteTranslationMergePolicy.merge(
        packageData: {},
        appData: {'key': 'app_val'},
        remoteData: null,
      );

      expect(result['key'], 'app_val');
    });

    test('nested maps merge correctly', () {
      final result = RemoteTranslationMergePolicy.merge(
        packageData: {
          'section': {'a': 'pkg_a'},
        },
        appData: {
          'section': {'a': 'app_a', 'b': 'app_b'},
        },
        remoteData: {
          'section': {'a': 'remote_a', 'c': 'remote_c'},
        },
      );

      expect(result, {
        'section': {'a': 'remote_a', 'b': 'app_b', 'c': 'remote_c'},
      });
    });
  });

  group('US3: Merge Policy - override: false protection', () {
    test('override: false prevents remote replacement', () {
      final result = RemoteTranslationMergePolicy.merge(
        packageData: {},
        appData: {
          'protected_key': {'value': 'app_protected', '__override__': false},
        },
        remoteData: {'protected_key': 'remote_value'},
      );

      expect(result['protected_key'], 'app_protected');
    });

    test('override: false in nested maps', () {
      final result = RemoteTranslationMergePolicy.merge(
        packageData: {},
        appData: {
          'section': {
            'nested_key': {
              'value': 'nested_protected',
              '__override__': false,
            },
          },
        },
        remoteData: {
          'section': {
            'nested_key': 'remote_nested',
          },
        },
      );

      expect(result['section'], {
        'nested_key': 'nested_protected',
      });
    });

    test('override: false does not block other keys in same map', () {
      final result = RemoteTranslationMergePolicy.merge(
        packageData: {},
        appData: {
          'protected_key': {'value': 'stay', '__override__': false},
          'normal_key': 'change_me',
        },
        remoteData: {
          'protected_key': 'should_not_apply',
          'normal_key': 'remote_value',
        },
      );

      expect(result['protected_key'], 'stay');
      expect(result['normal_key'], 'remote_value');
    });
  });

  group('US3: Merge Policy - missing override defaults to true', () {
    test('wrapper without __override__ allows remote override', () {
      final result = RemoteTranslationMergePolicy.merge(
        packageData: {},
        appData: {
          'key': {'value': 'app_val'},
        },
        remoteData: {'key': 'remote_val'},
      );

      expect(result['key'], 'remote_val');
    });

    test('wrapper without __override__ but no remote keeps app value', () {
      final result = RemoteTranslationMergePolicy.merge(
        packageData: {},
        appData: {
          'key': {'value': 'app_val'},
        },
        remoteData: {},
      );

      expect(result['key'], 'app_val');
    });

    test('explicit override: true allows remote replacement', () {
      final result = RemoteTranslationMergePolicy.merge(
        packageData: {},
        appData: {
          'key': {'value': 'app_val', '__override__': true},
        },
        remoteData: {'key': 'remote_val'},
      );

      expect(result['key'], 'remote_val');
    });
  });

  group('US3: Merge Policy - metadata stripping', () {
    test('override wrapper keys are stripped from result', () {
      final result = RemoteTranslationMergePolicy.merge(
        packageData: {},
        appData: {
          'key': {'value': 'visible', '__override__': false},
        },
        remoteData: {},
      );

      expect(result, {'key': 'visible'});
      expect(result['key'], isNot(contains('__override__')));
    });

    test('nested wrappers are stripped', () {
      final result = RemoteTranslationMergePolicy.merge(
        packageData: {},
        appData: {
          'section': {
            'title': {
              'value': 'Section Title',
              '__override__': false,
            },
          },
        },
        remoteData: {},
      );

      expect(result, {
        'section': {
          'title': 'Section Title',
        },
      });
    });

    test('mixed wrappers and regular nested maps are handled', () {
      final result = RemoteTranslationMergePolicy.merge(
        packageData: {},
        appData: {
          'simple': 'plain text',
          'wrapped': {'value': 'wrapped text', '__override__': false},
          'nested': {
            'child': 'child text',
          },
        },
        remoteData: {},
      );

      expect(result, {
        'simple': 'plain text',
        'wrapped': 'wrapped text',
        'nested': {
          'child': 'child text',
        },
      });
    });
  });
}
