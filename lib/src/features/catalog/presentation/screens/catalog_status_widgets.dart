import 'package:flutter/material.dart';

import '../../domain/entities/catalog_models.dart';
import '../controllers/catalog_ui_logic.dart';
import '../../l10n/generated/catalog_localizations.dart';
import 'catalog_label_helpers.dart';

// ---------------------------------------------------------------------------
// QueueSyncIndicator — small dot shown on queue row cards
// ---------------------------------------------------------------------------

class QueueSyncIndicator extends StatelessWidget {
  const QueueSyncIndicator({
    super.key,
    required this.state,
  });

  final CatalogDraftSyncState state;

  @override
  Widget build(BuildContext context) {
    if (state == CatalogDraftSyncState.clean) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: switch (state) {
          CatalogDraftSyncState.saveError => theme.colorScheme.error,
          CatalogDraftSyncState.saving => theme.colorScheme.tertiary,
          CatalogDraftSyncState.saved => theme.colorScheme.primary,
          CatalogDraftSyncState.dirty => theme.colorScheme.secondary,
          CatalogDraftSyncState.clean => theme.colorScheme.outline,
        },
        shape: BoxShape.circle,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// StatusChip — coloured chip for cell status strings ('green'/'red'/other)
// ---------------------------------------------------------------------------

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.status,
  });

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color background = switch (status) {
      'green' => colorScheme.secondaryContainer,
      'red' => colorScheme.errorContainer,
      _ => colorScheme.tertiaryContainer,
    };
    final Color foreground = switch (status) {
      'green' => colorScheme.onSecondaryContainer,
      'red' => colorScheme.onErrorContainer,
      _ => colorScheme.onTertiaryContainer,
    };
    return Chip(
      avatar: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.82),
          shape: BoxShape.circle,
        ),
      ),
      backgroundColor: background,
      side: BorderSide(color: foreground.withValues(alpha: 0.12)),
      labelStyle: TextStyle(color: foreground),
      label: Text(label),
    );
  }
}

// ---------------------------------------------------------------------------
// SyncChip — coloured chip for draft sync state
// ---------------------------------------------------------------------------

class SyncChip extends StatelessWidget {
  const SyncChip({
    super.key,
    required this.label,
    required this.state,
  });

  final String label;
  final CatalogDraftSyncState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (state) {
      CatalogDraftSyncState.clean => (colorScheme.surfaceContainerHigh, colorScheme.onSurfaceVariant),
      CatalogDraftSyncState.saved => (colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
      CatalogDraftSyncState.saveError => (colorScheme.errorContainer, colorScheme.onErrorContainer),
      CatalogDraftSyncState.saving => (colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
      CatalogDraftSyncState.dirty => (colorScheme.surfaceContainerHighest, colorScheme.onSurface),
    };
    return Chip(
      avatar: Icon(
        switch (state) {
          CatalogDraftSyncState.clean => Icons.cloud_done_outlined,
          CatalogDraftSyncState.saved => Icons.check_circle_outline,
          CatalogDraftSyncState.saveError => Icons.error_outline,
          CatalogDraftSyncState.saving => Icons.sync,
          CatalogDraftSyncState.dirty => Icons.edit_outlined,
        },
        size: 16,
        color: foreground,
      ),
      backgroundColor: background,
      side: BorderSide(color: foreground.withValues(alpha: 0.12)),
      labelStyle: TextStyle(color: foreground),
      label: Text(label),
    );
  }
}

// ---------------------------------------------------------------------------
// ErrorPane — full-screen error with retry button
// ---------------------------------------------------------------------------

class ErrorPane extends StatelessWidget {
  const ErrorPane({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ErrorBanner — inline error banner with retry action
// ---------------------------------------------------------------------------

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return BannerContainer(
      icon: Icons.error_outline,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: <Widget>[
          Expanded(child: Text(message)),
          TextButton(
            onPressed: onRetry,
            child: Text(CatalogLocalizations.of(context).retry),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ReasonBanner — informational banner showing cell reason / timestamps
// ---------------------------------------------------------------------------

class ReasonBanner extends StatelessWidget {
  const ReasonBanner({
    super.key,
    required this.controller,
    required this.row,
    required this.locale,
  });

  // CatalogWorkspaceController lives in catalog_flutter_app.dart.
  // Importing it here would create a circular dependency, so we use
  // [dynamic] intentionally. The contract: controller must implement
  // formatTimestamp(DateTime, Locale) → String.
  // ignore: avoid_annotating_with_dynamic
  final dynamic controller;
  final CatalogRow row;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = CatalogLocalizations.of(context);
    final CatalogCellState? cell = row.cellStates[locale];
    if (cell == null) {
      return const SizedBox.shrink();
    }
    final lines = <String>[];
    if (cell.reason != null) {
      lines.add(reasonLabel(l10n, cell.reason!));
    }
    if (cell.lastEditedAt != null) {
      lines.add(
        '${l10n.pendingLabel}: ${controller.formatTimestamp(cell.lastEditedAt, Localizations.localeOf(context))}',
      );
    }
    if (cell.lastReviewedAt != null) {
      lines.add(
        '${l10n.reviewed}: ${controller.formatTimestamp(cell.lastReviewedAt, Localizations.localeOf(context))}',
      );
    }
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }
    return BannerContainer(
      icon: Icons.info_outline,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map(Text.new).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BannerContainer — shared container used by ErrorBanner / ReasonBanner
// ---------------------------------------------------------------------------

class BannerContainer extends StatelessWidget {
  const BannerContainer({
    super.key,
    required this.icon,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}
