import 'package:flutter/material.dart';
import 'package:anas_localization/localization.dart';
import '../generated/dictionary.dart';

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
    final dict = getDictionary();

    return Scaffold(
      appBar: AppBar(
        title: Text(dict.localizationFeaturesDemo),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Pre-built language selector widget
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnasLanguageToggle(
              primaryLocale: context.supportedLocales.firstWhere(
                (locale) => locale.languageCode == 'en',
                orElse: () => context.supportedLocales.first,
              ),
              secondaryLocale: context.supportedLocales.firstWhere(
                (locale) => locale.languageCode == 'ar',
                orElse: () => context.supportedLocales.length > 1 ? context.supportedLocales[1] : context.supportedLocales.first,
              ),
              onLocaleChanged: (locale) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(dict.languageChangedTo(language: locale.languageCode))),
                );
              },
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
              // Basic translations section
              _buildSection(
                dict.basicTranslations,
                [
                  _buildFeatureCard(
                    dict.appNameTitle,
                    dict.appName,
                    Icons.apps,
                  ),
                  _buildFeatureCard(
                    dict.welcomeMessage,
                    dict.welcomeUser(name: 'Ahmed'),
                    Icons.waving_hand,
                  ),
                  _buildFeatureCard(
                    dict.withParameters,
                    dict.moneyArgs(name: 'Musa', amount: '5000', currency: 'USD'),
                    Icons.attach_money,
                  ),
                ],
              ),

              // Pluralization section
              _buildSection(
                dict.smartPluralization,
                [
                  _buildFeatureCard(
                    dict.carCountCurrent(count: _counter.toString()),
                    dict.car(count: _counter),
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
                  if (context.locale.languageCode == 'ar') ...[
                    _buildFeatureCard(
                      dict.arabicGenderAwareMale,
                      dict.car(count: _counter, gender: 'male'),
                      Icons.male,
                    ),
                    _buildFeatureCard(
                      dict.arabicGenderAwareFemale,
                      dict.car(count: _counter, gender: 'female'),
                      Icons.female,
                    ),
                  ],
                ],
              ),

              // Number & Currency formatting section
              _buildSection(
                dict.numberCurrencyFormatting,
                [
                  _buildFeatureCard(
                    dict.currency,
                    context.numberFormatter.formatCurrency(
                      _amount,
                      currencyCode: AnasLocaleDetector.getCurrencyForLocale(context.locale),
                    ),
                    Icons.monetization_on,
                    trailing: Slider(
                      value: _amount,
                      min: 0,
                      max: 10000,
                      onChanged: (value) => setState(() => _amount = value),
                    ),
                  ),
                  _buildFeatureCard(
                    dict.percentage,
                    context.numberFormatter.formatPercentage(0.85),
                    Icons.percent,
                  ),
                  _buildFeatureCard(
                    dict.compactNumbers,
                    context.numberFormatter.formatCompact(1234567),
                    Icons.numbers,
                  ),
                  _buildFeatureCard(
                    dict.fileSize,
                    AnasNumberFormatter(context.locale).formatFileSize(1024 * 1024 * 2), // 2MB
                    Icons.storage,
                  ),
                ],
              ),

              // Date & Time formatting section
              _buildSection(
                dict.dateTimeFormatting,
                [
                  _buildFeatureCard(
                    dict.currentDate,
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
                    dict.currentTime,
                    AnasDateTimeFormatter(context.locale).formatTime(DateTime.now()),
                    Icons.access_time,
                  ),
                  _buildFeatureCard(
                    dict.dateTimeCombined,
                    AnasDateTimeFormatter(context.locale).formatDateTime(DateTime.now()),
                    Icons.schedule,
                  ),
                  _buildFeatureCard(
                    dict.relativeTime,
                    AnasDateTimeFormatter(context.locale).formatRelativeTime(
                      DateTime.now().subtract(const Duration(hours: 2)),
                    ),
                    Icons.history,
                  ),
                ],
              ),

              // RTL & Text Direction section
              _buildSection(
                dict.textDirectionRtlSupport,
                [
                  _buildFeatureCard(
                    dict.currentDirection,
                    context.isRTL ? dict.rightToLeftRtl : dict.leftToRightLtr,
                    context.isRTL ? Icons.format_textdirection_r_to_l : Icons.format_textdirection_l_to_r,
                  ),
                  _buildFeatureCard(
                    dict.languageCode,
                    context.locale.languageCode.toUpperCase(),
                    Icons.language,
                  ),
                  _buildFeatureCard(
                    dict.autoCurrency,
                    AnasLocaleDetector.getCurrencyForLocale(context.locale),
                    Icons.payments,
                  ),
                ],
              ),

              // Theme-aware section
              _buildSection(
                dict.themeAwareFeatures,
                [
                  _buildFeatureCard(
                    dict.currentTheme,
                    context.themeLocalizer.isDarkMode ? dict.darkMode : dict.lightMode,
                    context.themeLocalizer.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                  _buildFeatureCard(
                    dict.themeBrightness,
                    Theme.of(context).brightness.name,
                    Icons.brightness_6,
                  ),
                ],
              ),

              // Rich text section
              _buildSection(
                dict.richTextFormatting,
                [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dict.richTextDemo,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          AnasRichText(
                            dict.richTextSample,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Language selector section
              _buildSection(
                dict.preBuiltLanguageWidgets,
                [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dict.languageSelectorWidget,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          AnasLanguageSelector(
                            supportedLocales: context.supportedLocales,
                            onLocaleChanged: (locale) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(dict.languageChangedTo(language: locale.languageCode)),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            dict.languageDialogDemo,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          AnasLanguageDialog(
                            supportedLocales: context.supportedLocales,
                            showDescription: true,
                            onLocaleChanged: (locale) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(dict.languageChangedTo(language: locale.languageCode)),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Info section
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
                            dict.anasLocalizationFeatures,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        dict.featuresDescription,
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
