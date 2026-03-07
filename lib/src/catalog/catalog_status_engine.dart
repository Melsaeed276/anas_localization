library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'catalog_flatten.dart';
import 'catalog_models.dart';

class CatalogStatusReasons {
  static const String sourceChanged = 'source_changed';
  static const String sourceAdded = 'source_added';
  static const String sourceDeleted = 'source_deleted';
  static const String sourceDeletedReviewRequired = 'source_deleted_review_required';
  static const String targetMissing = 'target_missing';
  static const String newKeyNeedsTranslationReview = 'new_key_needs_translation_review';
  static const String targetUpdatedNeedsReview = 'target_updated_needs_review';
}

class CatalogStatusEngine {
  const CatalogStatusEngine();

  String hashSourceValue(dynamic value) {
    final canonical = canonicalizeCatalogValue(value);
    final bytes = utf8.encode(canonical);
    return sha1.convert(bytes).toString();
  }

  CatalogKeyState newKeyState({
    required List<String> locales,
    required String sourceLocale,
    required String sourceHash,
    required bool allLocalesFilled,
    required DateTime now,
  }) {
    final cells = <String, CatalogCellState>{};
    for (final locale in locales) {
      if (allLocalesFilled) {
        cells[locale] = CatalogCellState(
          status: CatalogCellStatus.green,
          lastReviewedSourceHash: sourceHash,
          lastReviewedAt: now,
          lastEditedAt: now,
        );
      } else {
        cells[locale] = CatalogCellState(
          status: CatalogCellStatus.warning,
          reason: CatalogStatusReasons.newKeyNeedsTranslationReview,
          lastEditedAt: now,
        );
      }
    }

    return CatalogKeyState(
      sourceHash: sourceHash,
      cells: cells,
    );
  }

  CatalogCellState markGreen({
    required CatalogCellState? current,
    required String sourceHash,
    required DateTime now,
  }) {
    return (current ?? const CatalogCellState(status: CatalogCellStatus.green)).copyWith(
      status: CatalogCellStatus.green,
      clearReason: true,
      lastReviewedSourceHash: sourceHash,
      lastReviewedAt: now,
      lastEditedAt: now,
    );
  }

  CatalogCellState markWarning({
    required CatalogCellState? current,
    required String reason,
    required DateTime now,
  }) {
    return (current ?? const CatalogCellState(status: CatalogCellStatus.warning)).copyWith(
      status: CatalogCellStatus.warning,
      reason: reason,
      lastEditedAt: now,
    );
  }

  CatalogCellState markRed({
    required CatalogCellState? current,
    required String reason,
    required DateTime now,
  }) {
    return (current ?? const CatalogCellState(status: CatalogCellStatus.red)).copyWith(
      status: CatalogCellStatus.red,
      reason: reason,
      lastEditedAt: now,
    );
  }
}
