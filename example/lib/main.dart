import 'package:flutter/material.dart';
import 'package:localization/localization.dart';
import 'package:localization_example/widgets/language_selector.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the saved (or default) locale before running the app
  final provider = LocalizationProvider();
  await provider.loadSavedLocaleOrDefault();

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const ExampleApp(),
    ),
  );
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch provider for changes to dictionary and locale
    final provider = context.watch<LocalizationProvider>();
    final dictionary = provider.dictionary;
    final locale = provider.locale;

    // Wrap MaterialApp in Localization to provide translations and locale to subtree
    return Localization(
      dictionary: dictionary,
      locale: locale,
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          DictionaryLocalizationsDelegate(),
        ],
        supportedLocales: LocalizationService.allSupportedLocales
            .map((code) => Locale(code))
            .toList(),
        home: const HomePage(),
      ),
    );
  }
}


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int itemCount = 1;


  @override
  Widget build(BuildContext context) {
    // Type-safe access to the generated dictionary (never null)
    final dict = Localization.of(context).dictionary!;

     // Example count for demonstration

    return Scaffold(
      appBar: AppBar(title: Text(dict.appName )),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Language selector dropdown
            const LanguageSelector(),

            const SizedBox(height: 24),

            // Display a few localized strings
            Text(dict.welcomeUser(name: "Ahmed"), style: Theme.of(context).textTheme.headlineMedium),
            Text(dict.itemsCount(count: itemCount), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(dict.pleaseWait),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  itemCount = itemCount + 1;
                  print(itemCount);
                });


              },
              child: Text(dict.ok),
            ),
          ],
        ),
      ),
    );
  }
}