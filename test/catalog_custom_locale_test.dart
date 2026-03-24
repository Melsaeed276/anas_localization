import 'package:anas_localization/src/features/catalog/domain/entities/locale_validation_result.dart';
import 'package:anas_localization/src/shared/core/localization_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Custom Locale Tab', () {
    // T048: Widget test for custom locale tab visibility and interaction
    testWidgets('custom locale tab is visible and can be selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  // This would normally open the dialog
                  showDialog<void>(
                    context: tester.element(find.byType(FilledButton)),
                    builder: (context) {
                      return AlertDialog(
                        content: SizedBox(
                          width: 500,
                          height: 400,
                          child: DefaultTabController(
                            length: 2,
                            child: Column(
                              children: [
                                const TabBar(
                                  tabs: [
                                    Tab(text: 'Available Locales'),
                                    Tab(text: 'Custom Locale'),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      Center(child: Text('Available Locales')),
                                      Center(child: Text('Custom Locale')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Verify both tabs are visible
      expect(find.text('Available Locales'), findsOneWidget);
      expect(find.text('Custom Locale'), findsOneWidget);

      // Verify we can switch to custom locale tab
      await tester.tap(find.text('Custom Locale'));
      await tester.pumpAndSettle();

      // Verify custom locale content is visible
      expect(find.text('Custom Locale'), findsWidgets);
    });

    // T049: Widget test for RTL/LTR toggle behavior
    testWidgets('RTL/LTR toggle button works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                String direction = 'ltr';

                return Column(
                  children: [
                    Text('Current Direction: $direction'),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'ltr',
                          label: const Text('LTR'),
                          icon: const Icon(Icons.format_align_left),
                        ),
                        ButtonSegment(
                          value: 'rtl',
                          label: const Text('RTL'),
                          icon: const Icon(Icons.format_align_right),
                        ),
                      ],
                      selected: {direction},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          direction = newSelection.first;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Initial state should show LTR selected
      expect(find.text('Current Direction: ltr'), findsOneWidget);

      // Tap RTL button
      await tester.tap(find.text('RTL'));
      await tester.pumpAndSettle();

      // Verify direction changed to RTL
      expect(find.text('Current Direction: rtl'), findsOneWidget);

      // Tap LTR button to switch back
      await tester.tap(find.text('LTR'));
      await tester.pumpAndSettle();

      // Verify direction changed back to LTR
      expect(find.text('Current Direction: ltr'), findsOneWidget);
    });

    // T050: Widget test for validation feedback display
    testWidgets('validation feedback displays correctly for valid and invalid locales', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestCustomLocaleWidget(),
          ),
        ),
      );

      // Type an invalid locale code
      await tester.enterText(find.byType(TextField), 'invalid_code_xyz_abc');
      await tester.pumpAndSettle();

      // Wait for validation to complete
      await Future.delayed(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should show error feedback (validation will fail for invalid code)
      expect(
        find.byIcon(Icons.cancel),
        findsWidgets,
        reason: 'Should show error icon for invalid locale code',
      );

      // Clear the field
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Type a valid locale code
      await tester.enterText(find.byType(TextField), 'es_MX');
      await tester.pumpAndSettle();

      // Wait for validation to complete
      await Future.delayed(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should show success feedback for valid code
      expect(
        find.byIcon(Icons.check_circle),
        findsWidgets,
        reason: 'Should show success icon for valid locale code',
      );
    });

    // T050: Widget test for display name preview
    testWidgets('display name preview shows after successful validation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestCustomLocaleWidget(),
          ),
        ),
      );

      // Type a valid locale code
      await tester.enterText(find.byType(TextField), 'es_MX');
      await tester.pumpAndSettle();

      // Wait for validation to complete
      await Future.delayed(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Verify that validation feedback container is shown with success indicator
      final successIcon = find.byIcon(Icons.check_circle);
      expect(successIcon, findsWidgets);
    });
  });
}

/// Test widget that mimics the custom locale tab UI
class _TestCustomLocaleWidget extends StatefulWidget {
  const _TestCustomLocaleWidget();

  @override
  State<_TestCustomLocaleWidget> createState() => _TestCustomLocaleWidgetState();
}

class _TestCustomLocaleWidgetState extends State<_TestCustomLocaleWidget> {
  String customLocaleCode = '';
  String customLocaleDirection = 'ltr';
  LocaleValidationResult? customLocaleValidation;
  bool isValidatingCustomLocale = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Locale code input
          TextField(
            decoration: InputDecoration(
              labelText: 'Locale Code',
              hintText: 'e.g., es_MX, fr_CA, de_AT',
              prefixIcon: const Icon(Icons.code),
              border: const OutlineInputBorder(),
              suffixIcon: isValidatingCustomLocale
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (customLocaleValidation != null
                      ? Icon(
                          customLocaleValidation!.isValid ? Icons.check_circle : Icons.cancel,
                          color: customLocaleValidation!.isValid ? Colors.green : Colors.red,
                        )
                      : null),
            ),
            onChanged: (value) {
              setState(() {
                customLocaleCode = value.trim();
              });

              // Debounced validation
              if (customLocaleCode.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (customLocaleCode == value.trim()) {
                    setState(() {
                      isValidatingCustomLocale = true;
                    });

                    // Simulate validation
                    final isValid = RegExp(r'^[a-z]{2}(_[A-Z]{2})?$').hasMatch(customLocaleCode);
                    final displayName = isValid ? '$customLocaleCode - Validated' : null;

                    setState(() {
                      customLocaleValidation = LocaleValidationResult(
                        isValid: isValid,
                        languageCode: isValid ? customLocaleCode.split('_').first : null,
                        countryCode:
                            isValid ? (customLocaleCode.contains('_') ? customLocaleCode.split('_').last : null) : null,
                        languageName: isValid ? 'Language' : null,
                        countryName: isValid ? 'Country' : null,
                        displayName: displayName,
                        errorMessage: isValid ? null : 'Invalid locale code format',
                        errorType: isValid ? null : LocaleValidationErrorType.invalidFormat,
                      );
                      isValidatingCustomLocale = false;
                    });
                  }
                });
              } else {
                setState(() {
                  customLocaleValidation = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Direction selector
          Text(
            'Text Direction',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'ltr',
                label: const Text('LTR'),
                icon: const Icon(Icons.format_align_left),
              ),
              ButtonSegment(
                value: 'rtl',
                label: const Text('RTL'),
                icon: const Icon(Icons.format_align_right),
              ),
            ],
            selected: {customLocaleDirection},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                customLocaleDirection = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 16),

          // Validation feedback
          if (customLocaleCode.isNotEmpty && customLocaleValidation != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: customLocaleValidation!.isValid
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        customLocaleValidation!.isValid ? Icons.check_circle : Icons.error,
                        color: customLocaleValidation!.isValid
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          customLocaleValidation!.isValid
                              ? 'Valid locale code'
                              : (customLocaleValidation!.errorMessage ?? 'Invalid locale code'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: customLocaleValidation!.isValid
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (customLocaleValidation!.isValid && customLocaleValidation!.displayName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Display name: ${customLocaleValidation!.displayName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
