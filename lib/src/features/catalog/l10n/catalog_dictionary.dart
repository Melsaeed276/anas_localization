/// Type-safe Dictionary wrapper for Catalog UI localization
///
/// This class extends [Dictionary] and provides typed getters for all
/// Catalog UI translation keys. It replaces the gen_l10n-generated
/// CatalogLocalizations with the custom Dictionary system.
library;

import '../../localization/domain/entities/dictionary.dart';

class CatalogDictionary extends Dictionary {
  CatalogDictionary.fromMap(
    super.map, {
    required super.locale,
    super.dataTypes,
  }) : super.fromMap();

  // Simple getters (no parameters)
  String get appTitle => getString('appTitle');
  String get refresh => getString('refresh');
  String get newString => getString('newString');
  String get createNewString => getString('createNewString');
  String get createNewStringSubtitle => getString('createNewStringSubtitle');
  String get keyPathLabel => getString('keyPathLabel');
  String get keyPathHint => getString('keyPathHint');
  String get noteLabel => getString('noteLabel');
  String get noteHint => getString('noteHint');
  String get create => getString('create');
  String get confirm => getString('confirm');
  String get cancel => getString('cancel');
  String get themeLabel => getString('themeLabel');
  String get themeSystem => getString('themeSystem');
  String get themeLight => getString('themeLight');
  String get themeDark => getString('themeDark');
  String get catalogLanguage => getString('catalogLanguage');
  String get searchLabel => getString('searchLabel');
  String get searchHint => getString('searchHint');
  String get filterAll => getString('filterAll');
  String get filterReady => getString('filterReady');
  String get filterNeedsReview => getString('filterNeedsReview');
  String get filterMissing => getString('filterMissing');
  String get keysLabel => getString('keysLabel');
  String get readyRowsLabel => getString('readyRowsLabel');
  String get reviewRowsLabel => getString('reviewRowsLabel');
  String get missingRowsLabel => getString('missingRowsLabel');
  String get noKeys => getString('noKeys');
  String get noSelection => getString('noSelection');
  String get sourceLabel => getString('sourceLabel');
  String get sourceImpact => getString('sourceImpact');
  String get sourceImpactBody => getString('sourceImpactBody');
  String get editorLabel => getString('editorLabel');
  String get done => getString('done');
  String get deleteKey => getString('deleteKey');
  String get deleteValue => getString('deleteValue');
  String get advancedJson => getString('advancedJson');
  String get advancedJsonHelp => getString('advancedJsonHelp');
  String get syncClean => getString('syncClean');
  String get syncDirty => getString('syncDirty');
  String get syncSaving => getString('syncSaving');
  String get syncSaved => getString('syncSaved');
  String get syncError => getString('syncError');
  String get statusReady => getString('statusReady');
  String get statusNeedsReview => getString('statusNeedsReview');
  String get statusMissing => getString('statusMissing');
  String get reasonSourceChanged => getString('reasonSourceChanged');
  String get reasonSourceAdded => getString('reasonSourceAdded');
  String get reasonSourceDeleted => getString('reasonSourceDeleted');
  String get reasonSourceDeletedReviewRequired => getString('reasonSourceDeletedReviewRequired');
  String get reasonTargetMissing => getString('reasonTargetMissing');
  String get reasonNewKeyNeedsReview => getString('reasonNewKeyNeedsReview');
  String get reasonTargetUpdatedNeedsReview => getString('reasonTargetUpdatedNeedsReview');
  String get blockerTranslationEmpty => getString('blockerTranslationEmpty');
  String get blockerWaitAutosave => getString('blockerWaitAutosave');
  String get blockerFillBranches => getString('blockerFillBranches');
  String get blockerMissingPlaceholders => getString('blockerMissingPlaceholders');
  String get typeWarningTitle => getString('typeWarningTitle');
  String get notesSection => getString('notesSection');
  String get backLabel => getString('backLabel');
  String get loading => getString('loading');
  String get retry => getString('retry');
  String get pendingLabel => getString('pendingLabel');
  String get missingLabel => getString('missingLabel');
  String get allTargetsReady => getString('allTargetsReady');
  String get reviewed => getString('reviewed');
  String get optionalValueLabel => getString('optionalValueLabel');
  String get addBranchLabel => getString('addBranchLabel');
  String get saveFailed => getString('saveFailed');
  String get selectLocaleLabel => getString('selectLocaleLabel');
  String get displayOnlyLabel => getString('displayOnlyLabel');
  String get invalidKeyPath => getString('invalidKeyPath');
  String get confirmCreateWithoutSource => getString('confirmCreateWithoutSource');
  String get deleteKeyConfirmation => getString('deleteKeyConfirmation');
  String get deleteSourceValueConfirmation => getString('deleteSourceValueConfirmation');
  String get deleteLocaleValueConfirmation => getString('deleteLocaleValueConfirmation');
  String get translationLabel => getString('translationLabel');
  String get sourcePreviewLabel => getString('sourcePreviewLabel');
  String get noteIndicator => getString('noteIndicator');
  String get noNote => getString('noNote');
  String get bootstrapError => getString('bootstrapError');
  String get noteSaved => getString('noteSaved');
  String get noteAutosave => getString('noteAutosave');
  String get queueTitle => getString('queueTitle');
  String get sortLabel => getString('sortLabel');
  String get sortAlphabetical => getString('sortAlphabetical');
  String get sortNamespace => getString('sortNamespace');
  String get noKeysTitle => getString('noKeysTitle');
  String get noKeysBody => getString('noKeysBody');
  String get noResultsTitle => getString('noResultsTitle');
  String get noResultsBody => getString('noResultsBody');
  String get selectionPlaceholderTitle => getString('selectionPlaceholderTitle');
  String get selectionPlaceholderBody => getString('selectionPlaceholderBody');
  String get sectionEmpty => getString('sectionEmpty');
  String get overviewSection => getString('overviewSection');
  String get sourceContextSection => getString('sourceContextSection');
  String get localesSection => getString('localesSection');
  String get detailsSection => getString('detailsSection');
  String get contextSection => getString('contextSection');
  String get activitySection => getString('activitySection');
  String get namespaceLabel => getString('namespaceLabel');
  String get placeholdersLabel => getString('placeholdersLabel');
  String get noPlaceholders => getString('noPlaceholders');
  String get reviewPendingLocales => getString('reviewPendingLocales');
  String get sourceLocaleMeta => getString('sourceLocaleMeta');
  String get fallbackLocaleMeta => getString('fallbackLocaleMeta');
  String get formatMeta => getString('formatMeta');
  String get stateFileMeta => getString('stateFileMeta');
  String get activityEmpty => getString('activityEmpty');
  String get activityKeyCreated => getString('activityKeyCreated');
  String get activitySourceUpdated => getString('activitySourceUpdated');
  String get activityTargetUpdated => getString('activityTargetUpdated');
  String get activityNoteUpdated => getString('activityNoteUpdated');
  String get activityLocaleReviewed => getString('activityLocaleReviewed');
  String get activityValueDeleted => getString('activityValueDeleted');
  String get projectLocales => getString('projectLocales');
  String get defaultLabel => getString('defaultLabel');
  String get changeDefaultLocale => getString('changeDefaultLocale');
  String get deleteLocale => getString('deleteLocale');
  String get addNewLocale => getString('addNewLocale');
  String get cannotDeleteDefaultLocale => getString('cannotDeleteDefaultLocale');
  String get localeCodeHint => getString('localeCodeHint');
  String get invalidLocaleCode => getString('invalidLocaleCode');
  String get selectDefaultLocale => getString('selectDefaultLocale');

  // Parametrized methods
  String localeProgress(int ready, int total) {
    return getStringWithParams('localeProgress', {'ready': ready, 'total': total});
  }

  String reviewPendingSuccess(int count) {
    return getStringWithParams('reviewPendingSuccess', {'count': count});
  }

  String confirmDeleteLocale(String locale) {
    return getStringWithParams('confirmDeleteLocale', {'locale': locale});
  }

  String localeAlreadyExists(String locale) {
    return getStringWithParams('localeAlreadyExists', {'locale': locale});
  }
}
