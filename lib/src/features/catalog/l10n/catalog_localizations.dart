/// Catalog localization accessor wrapping the Dictionary system
///
/// This class provides a familiar `.of(context)` API similar to the old
/// gen_l10n CatalogLocalizations, but uses the custom Dictionary system.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../localization/presentation/widgets/dictionary_localizations_delegate.dart';
import 'catalog_dictionary.dart';

class CatalogLocalizations {
  const CatalogLocalizations._(this._dictionary);

  final CatalogDictionary _dictionary;

  /// Get the current CatalogLocalizations instance from context
  static CatalogLocalizations of(BuildContext context) {
    final dictionaryLocalizations = DictionaryLocalizations.of(context);
    if (dictionaryLocalizations == null) {
      throw FlutterError(
        'CatalogLocalizations.of() called with a context that does not contain '
        'DictionaryLocalizations. Ensure DictionaryLocalizationsDelegate is '
        'included in localizationsDelegates.',
      );
    }

    final dictionary = dictionaryLocalizations.dictionary;
    if (dictionary is! CatalogDictionary) {
      throw FlutterError(
        'DictionaryLocalizations contains a Dictionary that is not a '
        'CatalogDictionary. Ensure LocalizationService is configured with '
        'CatalogDictionary.fromMap as the dictionary factory.',
      );
    }

    return CatalogLocalizations._(dictionary);
  }

  // Delegate all getters and methods to the underlying CatalogDictionary
  String get appTitle => _dictionary.appTitle;
  String get refresh => _dictionary.refresh;
  String get newString => _dictionary.newString;
  String get createNewString => _dictionary.createNewString;
  String get createNewStringSubtitle => _dictionary.createNewStringSubtitle;
  String get keyPathLabel => _dictionary.keyPathLabel;
  String get keyPathHint => _dictionary.keyPathHint;
  String get noteLabel => _dictionary.noteLabel;
  String get noteHint => _dictionary.noteHint;
  String get create => _dictionary.create;
  String get confirm => _dictionary.confirm;
  String get cancel => _dictionary.cancel;
  String get themeLabel => _dictionary.themeLabel;
  String get themeSystem => _dictionary.themeSystem;
  String get themeLight => _dictionary.themeLight;
  String get themeDark => _dictionary.themeDark;
  String get catalogLanguage => _dictionary.catalogLanguage;
  String get searchLabel => _dictionary.searchLabel;
  String get searchHint => _dictionary.searchHint;
  String get filterAll => _dictionary.filterAll;
  String get filterReady => _dictionary.filterReady;
  String get filterNeedsReview => _dictionary.filterNeedsReview;
  String get filterMissing => _dictionary.filterMissing;
  String get keysLabel => _dictionary.keysLabel;
  String get readyRowsLabel => _dictionary.readyRowsLabel;
  String get reviewRowsLabel => _dictionary.reviewRowsLabel;
  String get missingRowsLabel => _dictionary.missingRowsLabel;
  String get noKeys => _dictionary.noKeys;
  String get noSelection => _dictionary.noSelection;
  String get sourceLabel => _dictionary.sourceLabel;
  String get sourceImpact => _dictionary.sourceImpact;
  String get sourceImpactBody => _dictionary.sourceImpactBody;
  String get editorLabel => _dictionary.editorLabel;
  String get done => _dictionary.done;
  String get deleteKey => _dictionary.deleteKey;
  String get deleteValue => _dictionary.deleteValue;
  String get advancedJson => _dictionary.advancedJson;
  String get advancedJsonHelp => _dictionary.advancedJsonHelp;
  String get syncClean => _dictionary.syncClean;
  String get syncDirty => _dictionary.syncDirty;
  String get syncSaving => _dictionary.syncSaving;
  String get syncSaved => _dictionary.syncSaved;
  String get syncError => _dictionary.syncError;
  String get statusReady => _dictionary.statusReady;
  String get statusNeedsReview => _dictionary.statusNeedsReview;
  String get statusMissing => _dictionary.statusMissing;
  String get reasonSourceChanged => _dictionary.reasonSourceChanged;
  String get reasonSourceAdded => _dictionary.reasonSourceAdded;
  String get reasonSourceDeleted => _dictionary.reasonSourceDeleted;
  String get reasonSourceDeletedReviewRequired => _dictionary.reasonSourceDeletedReviewRequired;
  String get reasonTargetMissing => _dictionary.reasonTargetMissing;
  String get reasonNewKeyNeedsReview => _dictionary.reasonNewKeyNeedsReview;
  String get reasonTargetUpdatedNeedsReview => _dictionary.reasonTargetUpdatedNeedsReview;
  String get blockerTranslationEmpty => _dictionary.blockerTranslationEmpty;
  String get blockerWaitAutosave => _dictionary.blockerWaitAutosave;
  String get blockerFillBranches => _dictionary.blockerFillBranches;
  String get blockerMissingPlaceholders => _dictionary.blockerMissingPlaceholders;
  String get typeWarningTitle => _dictionary.typeWarningTitle;
  String get notesSection => _dictionary.notesSection;
  String get backLabel => _dictionary.backLabel;
  String get loading => _dictionary.loading;
  String get retry => _dictionary.retry;
  String get pendingLabel => _dictionary.pendingLabel;
  String get missingLabel => _dictionary.missingLabel;
  String get allTargetsReady => _dictionary.allTargetsReady;
  String get reviewed => _dictionary.reviewed;
  String get optionalValueLabel => _dictionary.optionalValueLabel;
  String get addBranchLabel => _dictionary.addBranchLabel;
  String get saveFailed => _dictionary.saveFailed;
  String get selectLocaleLabel => _dictionary.selectLocaleLabel;
  String get displayOnlyLabel => _dictionary.displayOnlyLabel;
  String get invalidKeyPath => _dictionary.invalidKeyPath;
  String get confirmCreateWithoutSource => _dictionary.confirmCreateWithoutSource;
  String get deleteKeyConfirmation => _dictionary.deleteKeyConfirmation;
  String get deleteSourceValueConfirmation => _dictionary.deleteSourceValueConfirmation;
  String get deleteLocaleValueConfirmation => _dictionary.deleteLocaleValueConfirmation;
  String get translationLabel => _dictionary.translationLabel;
  String get sourcePreviewLabel => _dictionary.sourcePreviewLabel;
  String get noteIndicator => _dictionary.noteIndicator;
  String get noNote => _dictionary.noNote;
  String get bootstrapError => _dictionary.bootstrapError;
  String get noteSaved => _dictionary.noteSaved;
  String get noteAutosave => _dictionary.noteAutosave;
  String get queueTitle => _dictionary.queueTitle;
  String get sortLabel => _dictionary.sortLabel;
  String get sortAlphabetical => _dictionary.sortAlphabetical;
  String get sortNamespace => _dictionary.sortNamespace;
  String get noKeysTitle => _dictionary.noKeysTitle;
  String get noKeysBody => _dictionary.noKeysBody;
  String get noResultsTitle => _dictionary.noResultsTitle;
  String get noResultsBody => _dictionary.noResultsBody;
  String get selectionPlaceholderTitle => _dictionary.selectionPlaceholderTitle;
  String get selectionPlaceholderBody => _dictionary.selectionPlaceholderBody;
  String get sectionEmpty => _dictionary.sectionEmpty;
  String get overviewSection => _dictionary.overviewSection;
  String get sourceContextSection => _dictionary.sourceContextSection;
  String get localesSection => _dictionary.localesSection;
  String get detailsSection => _dictionary.detailsSection;
  String get contextSection => _dictionary.contextSection;
  String get activitySection => _dictionary.activitySection;
  String get namespaceLabel => _dictionary.namespaceLabel;
  String get placeholdersLabel => _dictionary.placeholdersLabel;
  String get noPlaceholders => _dictionary.noPlaceholders;
  String get reviewPendingLocales => _dictionary.reviewPendingLocales;
  String get sourceLocaleMeta => _dictionary.sourceLocaleMeta;
  String get fallbackLocaleMeta => _dictionary.fallbackLocaleMeta;
  String get formatMeta => _dictionary.formatMeta;
  String get stateFileMeta => _dictionary.stateFileMeta;
  String get activityEmpty => _dictionary.activityEmpty;
  String get activityKeyCreated => _dictionary.activityKeyCreated;
  String get activitySourceUpdated => _dictionary.activitySourceUpdated;
  String get activityTargetUpdated => _dictionary.activityTargetUpdated;
  String get activityNoteUpdated => _dictionary.activityNoteUpdated;
  String get activityLocaleReviewed => _dictionary.activityLocaleReviewed;
  String get activityValueDeleted => _dictionary.activityValueDeleted;
  String get projectLocales => _dictionary.projectLocales;
  String get defaultLabel => _dictionary.defaultLabel;
  String get changeDefaultLocale => _dictionary.changeDefaultLocale;
  String get deleteLocale => _dictionary.deleteLocale;
  String get addNewLocale => _dictionary.addNewLocale;
  String get cannotDeleteDefaultLocale => _dictionary.cannotDeleteDefaultLocale;
  String get localeCodeHint => _dictionary.localeCodeHint;
  String get invalidLocaleCode => _dictionary.invalidLocaleCode;
  String get selectDefaultLocale => _dictionary.selectDefaultLocale;

  // Parametrized methods
  String localeProgress(int ready, int total) => _dictionary.localeProgress(ready, total);
  String reviewPendingSuccess(int count) => _dictionary.reviewPendingSuccess(count);
  String confirmDeleteLocale(String locale) => _dictionary.confirmDeleteLocale(locale);
  String localeAlreadyExists(String locale) => _dictionary.localeAlreadyExists(locale);

  // Static properties for MaterialApp configuration
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('hi'),
    Locale('tr'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    DictionaryLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
}
