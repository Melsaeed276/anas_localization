import 'package:flutter/material.dart';
import 'package:anas_localization/localization.dart' hide Dictionary;

/// Demo page showcasing all the enhanced localization features
class FeaturesPage extends StatefulWidget {
  const FeaturesPage({super.key});

  @override
  State<FeaturesPage> createState() => _FeaturesPageState();
}

class _FeaturesPageState extends State<FeaturesPage> {
  int _counter = 5;
  double _amount = 1234.56;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localization Features'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnasLanguageToggle(
              primaryLocale: context.supportedLocales.firstWhere(
                (locale) => locale.languageCode == 'en',
                orElse: () => context.supportedLocales.first,
              ),
              secondaryLocale: context.supportedLocales.firstWhere(
                (locale) => locale.languageCode == 'ar',
                orElse: () =>
                    context.supportedLocales.length > 1 ? context.supportedLocales[1] : context.supportedLocales.first,
              ),
            ),
          ),
        ],
      ),
      body: AnasDirectionalityWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'Basic Translations',
                [
                  _buildFeatureCard(
                    'App Name',
                    'Anas Localization',
                    Icons.apps,
                  ),
                  _buildFeatureCard(
                    'Welcome Message',
                    'Welcome, Ahmed!',
                    Icons.waving_hand,
                  ),
                  _buildFeatureCard(
                    'With Parameters',
                    'Musa has 5000 USD',
                    Icons.attach_money,
                  ),
                ],
              ),
              _buildSection(
                'Smart Pluralization',
                [
                  _buildFeatureCard(
                    'Car Count (Current: $_counter)',
                    '$_counter cars',
                    Icons.directions_car,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => setState(() => _counter = (_counter - 1).clamp(0, 100)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _counter++),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildSection(
                'Number & Currency Formatting',
                [
                  _buildFeatureCard(
                    'Currency',
                    context.numberFormatter.formatCurrency(_amount, currencyCode: 'USD'),
                    Icons.monetization_on,
                    trailing: Slider(
                      value: _amount,
                      min: 0,
                      max: 10000,
                      onChanged: (value) => setState(() => _amount = value),
                    ),
                  ),
                  _buildFeatureCard(
                    'Percentage',
                    context.numberFormatter.formatPercentage(0.85),
                    Icons.percent,
                  ),
                  _buildFeatureCard(
                    'Compact Numbers',
                    context.numberFormatter.formatCompact(1234567),
                    Icons.numbers,
                  ),
                  _buildFeatureCard(
                    'File Size',
                    AnasNumberFormatter(context.locale).formatFileSize(1024 * 1024 * 2),
                    Icons.storage,
                  ),
                ],
              ),
              _buildSection(
                'Date & Time Formatting',
                [
                  _buildFeatureCard(
                    'Current Date',
                    AnasDateTimeFormatter(context.locale).formatDate(_selectedDate),
                    Icons.calendar_today,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_calendar),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                    ),
                  ),
                  _buildFeatureCard(
                    'Current Time',
                    AnasDateTimeFormatter(context.locale).formatTime(DateTime.now()),
                    Icons.access_time,
                  ),
                  _buildFeatureCard(
                    'Date & Time',
                    AnasDateTimeFormatter(context.locale).formatDateTime(DateTime.now()),
                    Icons.schedule,
                  ),
                  _buildFeatureCard(
                    'Relative Time',
                    AnasDateTimeFormatter(context.locale).formatRelativeTime(
                      DateTime.now().subtract(const Duration(hours: 2)),
                    ),
                    Icons.history,
                  ),
                ],
              ),
              _buildSection(
                'Text Direction & RTL',
                [
                  _buildFeatureCard(
                    'Current Direction',
                    context.isRTL ? 'RTL' : 'LTR',
                    context.isRTL ? Icons.format_textdirection_r_to_l : Icons.format_textdirection_l_to_r,
                  ),
                  _buildFeatureCard(
                    'Language Code',
                    context.locale.languageCode.toUpperCase(),
                    Icons.language,
                  ),
                  _buildFeatureCard(
                    'Auto Currency',
                    'USD',
                    Icons.payments,
                  ),
                ],
              ),
              _buildSection(
                'Theme-Aware',
                [
                  _buildFeatureCard(
                    'Theme Brightness',
                    Theme.of(context).brightness.name,
                    Icons.brightness_6,
                  ),
                ],
              ),
              _buildSection(
                'Rich Text',
                [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rich Text Demo',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          AnasRichText(
                            'This text has bold, italic, and underlined formatting!',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              _buildSection(
                'Pre-built Language Widgets',
                [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Language Selector Widget',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          AnasLanguageSelector(
                            supportedLocales: context.supportedLocales,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Language Dialog Demo',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          AnasLanguageDialog(
                            supportedLocales: context.supportedLocales,
                            showDescription: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Anas Localization Features',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Zero-configuration setup\n• Advanced pluralization\n• Built-in RTL support\n• Date/time and number formatting\n• Rich text support\n• Pre-built UI widgets',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFeatureCard(
    String title,
    String value,
    IconData icon, {
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (trailing != null) ...[
              const SizedBox(height: 12),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
