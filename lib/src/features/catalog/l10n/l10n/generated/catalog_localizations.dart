import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'catalog_localizations_ar.dart';
import 'catalog_localizations_en.dart';
import 'catalog_localizations_es.dart';
import 'catalog_localizations_hi.dart';
import 'catalog_localizations_tr.dart';
import 'catalog_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of CatalogLocalizations
/// returned by `CatalogLocalizations.of(context)`.
///
/// Applications need to include `CatalogLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/catalog_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: CatalogLocalizations.localizationsDelegates,
///   supportedLocales: CatalogLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the CatalogLocalizations.supportedLocales
/// property.
abstract class CatalogLocalizations {
  CatalogLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static CatalogLocalizations of(BuildContext context) {
    return Localizations.of<CatalogLocalizations>(context, CatalogLocalizations) ?? CatalogLocalizationsEn();
  }

  static const LocalizationsDelegate<CatalogLocalizations> delegate = _CatalogLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('hi'),
    Locale('tr'),
    Locale('zh'),
    Locale('zh', 'CN')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Anas Catalog'**
  String get appTitle;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @newString.
  ///
  /// In en, this message translates to:
  /// **'New String'**
  String get newString;

  /// No description provided for @createNewString.
  ///
  /// In en, this message translates to:
  /// **'Create New String'**
  String get createNewString;

  /// No description provided for @createNewStringSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Source locale goes first. Filled target locales still need review until marked Done.'**
  String get createNewStringSubtitle;

  /// No description provided for @keyPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Key path'**
  String get keyPathLabel;

  /// No description provided for @keyPathHint.
  ///
  /// In en, this message translates to:
  /// **'checkout.summary.title'**
  String get keyPathHint;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Key note'**
  String get noteLabel;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Add translator or reviewer context'**
  String get noteHint;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @catalogLanguage.
  ///
  /// In en, this message translates to:
  /// **'Catalog Language'**
  String get catalogLanguage;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search keys, values, or notes'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get filterReady;

  /// No description provided for @filterNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get filterNeedsReview;

  /// No description provided for @filterMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get filterMissing;

  /// No description provided for @keysLabel.
  ///
  /// In en, this message translates to:
  /// **'keys'**
  String get keysLabel;

  /// No description provided for @readyRowsLabel.
  ///
  /// In en, this message translates to:
  /// **'ready rows'**
  String get readyRowsLabel;

  /// No description provided for @reviewRowsLabel.
  ///
  /// In en, this message translates to:
  /// **'review rows'**
  String get reviewRowsLabel;

  /// No description provided for @missingRowsLabel.
  ///
  /// In en, this message translates to:
  /// **'missing rows'**
  String get missingRowsLabel;

  /// No description provided for @noKeys.
  ///
  /// In en, this message translates to:
  /// **'No keys found.'**
  String get noKeys;

  /// No description provided for @noSelection.
  ///
  /// In en, this message translates to:
  /// **'Select a key to start editing.'**
  String get noSelection;

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceLabel;

  /// No description provided for @sourceImpact.
  ///
  /// In en, this message translates to:
  /// **'Source locale'**
  String get sourceImpact;

  /// No description provided for @sourceImpactBody.
  ///
  /// In en, this message translates to:
  /// **'Editing the source reopens review for target locales.'**
  String get sourceImpactBody;

  /// No description provided for @editorLabel.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editorLabel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @deleteKey.
  ///
  /// In en, this message translates to:
  /// **'Delete Key'**
  String get deleteKey;

  /// No description provided for @deleteValue.
  ///
  /// In en, this message translates to:
  /// **'Delete Value'**
  String get deleteValue;

  /// No description provided for @advancedJson.
  ///
  /// In en, this message translates to:
  /// **'Advanced JSON'**
  String get advancedJson;

  /// No description provided for @advancedJsonHelp.
  ///
  /// In en, this message translates to:
  /// **'Use raw JSON for unsupported shapes.'**
  String get advancedJsonHelp;

  /// No description provided for @syncClean.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncClean;

  /// No description provided for @syncDirty.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get syncDirty;

  /// No description provided for @syncSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get syncSaving;

  /// No description provided for @syncSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get syncSaved;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get syncError;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get statusNeedsReview;

  /// No description provided for @statusMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get statusMissing;

  /// No description provided for @reasonSourceChanged.
  ///
  /// In en, this message translates to:
  /// **'Source changed'**
  String get reasonSourceChanged;

  /// No description provided for @reasonSourceAdded.
  ///
  /// In en, this message translates to:
  /// **'Source added'**
  String get reasonSourceAdded;

  /// No description provided for @reasonSourceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Source deleted'**
  String get reasonSourceDeleted;

  /// No description provided for @reasonSourceDeletedReviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Source deleted, review required'**
  String get reasonSourceDeletedReviewRequired;

  /// No description provided for @reasonTargetMissing.
  ///
  /// In en, this message translates to:
  /// **'Target missing'**
  String get reasonTargetMissing;

  /// No description provided for @reasonNewKeyNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'New key needs review'**
  String get reasonNewKeyNeedsReview;

  /// No description provided for @reasonTargetUpdatedNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Target updated, needs review'**
  String get reasonTargetUpdatedNeedsReview;

  /// No description provided for @blockerTranslationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Translation is empty.'**
  String get blockerTranslationEmpty;

  /// No description provided for @blockerWaitAutosave.
  ///
  /// In en, this message translates to:
  /// **'Wait for autosave to finish.'**
  String get blockerWaitAutosave;

  /// No description provided for @blockerFillBranches.
  ///
  /// In en, this message translates to:
  /// **'Fill every visible branch before marking Done.'**
  String get blockerFillBranches;

  /// No description provided for @blockerMissingPlaceholders.
  ///
  /// In en, this message translates to:
  /// **'Missing placeholders'**
  String get blockerMissingPlaceholders;

  /// No description provided for @typeWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Type warning (optional)'**
  String get typeWarningTitle;

  /// No description provided for @notesSection.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesSection;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading catalog…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @pendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingLabel;

  /// No description provided for @missingLabel.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missingLabel;

  /// No description provided for @allTargetsReady.
  ///
  /// In en, this message translates to:
  /// **'All target locales are ready.'**
  String get allTargetsReady;

  /// No description provided for @reviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get reviewed;

  /// No description provided for @optionalValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional initial value'**
  String get optionalValueLabel;

  /// No description provided for @addBranchLabel.
  ///
  /// In en, this message translates to:
  /// **'Add branch'**
  String get addBranchLabel;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @selectLocaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Locale'**
  String get selectLocaleLabel;

  /// No description provided for @displayOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Display only'**
  String get displayOnlyLabel;

  /// No description provided for @invalidKeyPath.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid dotted key path.'**
  String get invalidKeyPath;

  /// No description provided for @confirmCreateWithoutSource.
  ///
  /// In en, this message translates to:
  /// **'Create this key without a source value?'**
  String get confirmCreateWithoutSource;

  /// No description provided for @deleteKeyConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete this key from all locales?'**
  String get deleteKeyConfirmation;

  /// No description provided for @deleteSourceValueConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete the source value?'**
  String get deleteSourceValueConfirmation;

  /// No description provided for @deleteLocaleValueConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete this locale value?'**
  String get deleteLocaleValueConfirmation;

  /// No description provided for @translationLabel.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translationLabel;

  /// No description provided for @sourcePreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Source preview'**
  String get sourcePreviewLabel;

  /// No description provided for @noteIndicator.
  ///
  /// In en, this message translates to:
  /// **'Has note'**
  String get noteIndicator;

  /// No description provided for @noNote.
  ///
  /// In en, this message translates to:
  /// **'No note yet.'**
  String get noNote;

  /// No description provided for @bootstrapError.
  ///
  /// In en, this message translates to:
  /// **'Could not load catalog bootstrap.'**
  String get bootstrapError;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSaved;

  /// No description provided for @noteAutosave.
  ///
  /// In en, this message translates to:
  /// **'Notes autosave after a short delay.'**
  String get noteAutosave;

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'Translation Queue'**
  String get queueTitle;

  /// No description provided for @sortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortLabel;

  /// No description provided for @sortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'A-Z'**
  String get sortAlphabetical;

  /// No description provided for @sortNamespace.
  ///
  /// In en, this message translates to:
  /// **'Namespace'**
  String get sortNamespace;

  /// No description provided for @noKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'No catalog keys yet'**
  String get noKeysTitle;

  /// No description provided for @noKeysBody.
  ///
  /// In en, this message translates to:
  /// **'Create the first string to start the translation queue.'**
  String get noKeysBody;

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching keys'**
  String get noResultsTitle;

  /// No description provided for @noResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or clear the active filters.'**
  String get noResultsBody;

  /// No description provided for @selectionPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a key'**
  String get selectionPlaceholderTitle;

  /// No description provided for @selectionPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Select a queue item to inspect notes, source context, locales, and activity.'**
  String get selectionPlaceholderBody;

  /// No description provided for @sectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No keys in this section.'**
  String get sectionEmpty;

  /// No description provided for @overviewSection.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewSection;

  /// No description provided for @sourceContextSection.
  ///
  /// In en, this message translates to:
  /// **'Source Context'**
  String get sourceContextSection;

  /// No description provided for @localesSection.
  ///
  /// In en, this message translates to:
  /// **'Locales'**
  String get localesSection;

  /// No description provided for @detailsSection.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsSection;

  /// No description provided for @contextSection.
  ///
  /// In en, this message translates to:
  /// **'Catalog Context'**
  String get contextSection;

  /// No description provided for @activitySection.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activitySection;

  /// No description provided for @namespaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Namespace'**
  String get namespaceLabel;

  /// No description provided for @localeProgress.
  ///
  /// In en, this message translates to:
  /// **'{ready} of {total} target locales ready'**
  String localeProgress(int ready, int total);

  /// No description provided for @placeholdersLabel.
  ///
  /// In en, this message translates to:
  /// **'Placeholders'**
  String get placeholdersLabel;

  /// No description provided for @noPlaceholders.
  ///
  /// In en, this message translates to:
  /// **'No placeholders in the source value.'**
  String get noPlaceholders;

  /// No description provided for @reviewPendingLocales.
  ///
  /// In en, this message translates to:
  /// **'Review pending locales'**
  String get reviewPendingLocales;

  /// No description provided for @reviewPendingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reviewed {count} pending locales.'**
  String reviewPendingSuccess(int count);

  /// No description provided for @sourceLocaleMeta.
  ///
  /// In en, this message translates to:
  /// **'Source locale'**
  String get sourceLocaleMeta;

  /// No description provided for @fallbackLocaleMeta.
  ///
  /// In en, this message translates to:
  /// **'Fallback locale'**
  String get fallbackLocaleMeta;

  /// No description provided for @formatMeta.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get formatMeta;

  /// No description provided for @stateFileMeta.
  ///
  /// In en, this message translates to:
  /// **'State file'**
  String get stateFileMeta;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity yet for this key.'**
  String get activityEmpty;

  /// No description provided for @activityKeyCreated.
  ///
  /// In en, this message translates to:
  /// **'Key created'**
  String get activityKeyCreated;

  /// No description provided for @activitySourceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Source updated'**
  String get activitySourceUpdated;

  /// No description provided for @activityTargetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Translation updated'**
  String get activityTargetUpdated;

  /// No description provided for @activityNoteUpdated.
  ///
  /// In en, this message translates to:
  /// **'Note updated'**
  String get activityNoteUpdated;

  /// No description provided for @activityLocaleReviewed.
  ///
  /// In en, this message translates to:
  /// **'Locale marked done'**
  String get activityLocaleReviewed;

  /// No description provided for @activityValueDeleted.
  ///
  /// In en, this message translates to:
  /// **'Value deleted'**
  String get activityValueDeleted;
}

class _CatalogLocalizationsDelegate extends LocalizationsDelegate<CatalogLocalizations> {
  const _CatalogLocalizationsDelegate();

  @override
  Future<CatalogLocalizations> load(Locale locale) {
    return SynchronousFuture<CatalogLocalizations>(lookupCatalogLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'es', 'hi', 'tr', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_CatalogLocalizationsDelegate old) => false;
}

CatalogLocalizations lookupCatalogLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return CatalogLocalizationsZhCn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return CatalogLocalizationsAr();
    case 'en':
      return CatalogLocalizationsEn();
    case 'es':
      return CatalogLocalizationsEs();
    case 'hi':
      return CatalogLocalizationsHi();
    case 'tr':
      return CatalogLocalizationsTr();
    case 'zh':
      return CatalogLocalizationsZh();
  }

  throw FlutterError('CatalogLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
