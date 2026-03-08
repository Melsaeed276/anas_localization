import 'dart:convert';

import 'package:anas_localization/src/utils/migration_validation_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MigrationValidationHelper', () {
    test('report model serializes and deserializes', () {
      const report = MigrationValidationReport(
        generatedAtUtc: '2026-03-07T00:00:00.000Z',
        os: 'macos',
        runtime: '3.9.0',
        threshold: 0.25,
        results: [
          SourceValidationResult(
            sourcePackage: 'easy_localization',
            workspacePath: '/tmp/demo',
            success: true,
            steps: [
              ValidationStepReport(
                name: 'convert',
                durationMs: 120,
                success: true,
                command: 'dart run ... convert',
              ),
            ],
            totalDurationMs: 120,
            warnings: ['manual follow-up'],
          ),
        ],
        regressions: [
          TimingRegression(
            sourcePackage: 'easy_localization',
            stepName: 'convert',
            baselineMs: 100,
            currentMs: 150,
            threshold: 0.25,
          ),
        ],
        globalWarnings: ['baseline mismatch'],
      );

      final decoded = MigrationValidationReport.fromJson(
        jsonDecode(jsonEncode(report.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.generatedAtUtc, equals(report.generatedAtUtc));
      expect(decoded.os, equals(report.os));
      expect(decoded.results.single.sourcePackage, equals('easy_localization'));
      expect(decoded.results.single.steps.single.durationMs, equals(120));
      expect(decoded.regressions.single.currentMs, equals(150));
      expect(decoded.globalWarnings, contains('baseline mismatch'));
    });

    test('compareReports flags only regressions above threshold', () {
      const current = [
        SourceValidationResult(
          sourcePackage: 'easy_localization',
          workspacePath: '/tmp/current',
          success: true,
          steps: [
            ValidationStepReport(name: 'convert', durationMs: 151, success: true),
            ValidationStepReport(name: 'migrate', durationMs: 80, success: true),
          ],
          totalDurationMs: 231,
          warnings: [],
        ),
      ];
      const baseline = [
        SourceValidationResult(
          sourcePackage: 'easy_localization',
          workspacePath: '/tmp/baseline',
          success: true,
          steps: [
            ValidationStepReport(name: 'convert', durationMs: 100, success: true),
            ValidationStepReport(name: 'migrate', durationMs: 70, success: true),
          ],
          totalDurationMs: 170,
          warnings: [],
        ),
      ];

      final regressions = MigrationValidationHelper.compareReports(
        current: current,
        baseline: baseline,
        threshold: 0.25,
      );

      expect(regressions, hasLength(1));
      expect(regressions.single.sourcePackage, equals('easy_localization'));
      expect(regressions.single.stepName, equals('convert'));
      expect(regressions.single.ratio, closeTo(0.51, 0.001));
    });

    test('report detects functional failures from source results', () {
      const report = MigrationValidationReport(
        generatedAtUtc: '2026-03-07T00:00:00.000Z',
        os: 'linux',
        runtime: '3.9.0',
        threshold: 0.25,
        results: [
          SourceValidationResult(
            sourcePackage: 'gen_l10n',
            workspacePath: '/tmp/demo',
            success: false,
            steps: [
              ValidationStepReport(
                name: 'analyze',
                durationMs: 200,
                success: false,
                error: 'analyze failed',
              ),
            ],
            totalDurationMs: 200,
            warnings: [],
            failureStep: 'analyze',
          ),
        ],
        regressions: [],
        globalWarnings: [],
      );

      expect(report.hasFunctionalFailures, isTrue);
    });
  });
}
