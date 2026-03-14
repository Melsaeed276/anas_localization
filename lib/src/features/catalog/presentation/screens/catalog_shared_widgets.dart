import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// CatalogRadioGroup<T> — InheritedWidget scope for RadioListTile groups
//
// Usage:
//   CatalogRadioGroup<MyEnum>(
//     groupValue: selected,
//     onChanged: (v) => setState(() => selected = v!),
//     child: Column(children: [
//       RadioListTile<MyEnum>(value: MyEnum.a, title: Text('A')),
//       RadioListTile<MyEnum>(value: MyEnum.b, title: Text('B')),
//     ]),
//   )
//
// CatalogRadioGroup walks the immediate children of the first Column found in
// `child` and re-instantiates any RadioListTile<T> widgets with the shared
// groupValue / onChanged injected. Tiles that already provide groupValue are
// left unchanged.
// ---------------------------------------------------------------------------

class CatalogRadioGroup<T extends Object> extends StatelessWidget {
  const CatalogRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.child,
  });

  final T groupValue;
  final ValueChanged<T?> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _RadioGroupScope<T>(
      groupValue: groupValue,
      onChanged: onChanged,
      child: _RadioGroupInjector<T>(
        groupValue: groupValue,
        onChanged: onChanged,
        child: child,
      ),
    );
  }
}

/// InheritedWidget that exposes [groupValue] and [onChanged] to the subtree.
class _RadioGroupScope<T extends Object> extends InheritedWidget {
  const _RadioGroupScope({
    required this.groupValue,
    required this.onChanged,
    required super.child,
  });

  final T groupValue;
  final ValueChanged<T?> onChanged;

  @override
  bool updateShouldNotify(_RadioGroupScope<T> old) {
    return groupValue != old.groupValue;
  }
}

/// Walks direct Column children and injects groupValue/onChanged into any
/// `RadioListTile<T>` that does not already specify groupValue.
class _RadioGroupInjector<T extends Object> extends StatelessWidget {
  const _RadioGroupInjector({
    required this.groupValue,
    required this.onChanged,
    required this.child,
  });

  final T groupValue;
  final ValueChanged<T?> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (child is Column) {
      final col = child as Column;
      final injected = col.children.map((w) => _inject(w)).toList();
      return Column(
        key: col.key,
        mainAxisAlignment: col.mainAxisAlignment,
        mainAxisSize: col.mainAxisSize,
        crossAxisAlignment: col.crossAxisAlignment,
        textDirection: col.textDirection,
        verticalDirection: col.verticalDirection,
        textBaseline: col.textBaseline,
        children: injected,
      );
    }
    return child;
  }

  Widget _inject(Widget w) {
    if (w is RadioListTile<T>) {
      // Only inject if groupValue was not already provided (it defaults to
      // null for RadioListTile when type is nullable, but for non-nullable T
      // the field is required — so we always inject to be safe).
      return RadioListTile<T>(
        key: w.key,
        value: w.value,
        // ignore: deprecated_member_use
        groupValue: groupValue,
        // ignore: deprecated_member_use
        onChanged: onChanged,
        title: w.title,
        subtitle: w.subtitle,
        isThreeLine: w.isThreeLine,
        dense: w.dense,
        secondary: w.secondary,
        selected: w.selected,
        controlAffinity: w.controlAffinity,
        autofocus: w.autofocus,
        contentPadding: w.contentPadding,
        toggleable: w.toggleable,
        activeColor: w.activeColor,
        fillColor: w.fillColor,
        overlayColor: w.overlayColor,
        splashRadius: w.splashRadius,
        materialTapTargetSize: w.materialTapTargetSize,
        visualDensity: w.visualDensity,
      );
    }
    return w;
  }
}

// ---------------------------------------------------------------------------
// Motion constants (moved from catalog_flutter_app.dart)
// ---------------------------------------------------------------------------

const Duration catalogMotionDuration = Duration(milliseconds: 220);
const Curve catalogMotionCurve = Curves.easeOutCubic;

// ---------------------------------------------------------------------------
// Gradient / shadow helpers (moved from catalog_flutter_app.dart)
// ---------------------------------------------------------------------------

LinearGradient catalogShellGradient(ColorScheme scheme) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      scheme.surfaceContainerLowest,
      scheme.surfaceContainerLow,
      scheme.surface,
    ],
    stops: const <double>[0, 0.3, 1],
  );
}

LinearGradient catalogSectionGradient(
  ThemeData theme, {
  bool highlighted = false,
}) {
  final scheme = theme.colorScheme;
  if (highlighted) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        scheme.surface,
        scheme.primaryContainer.withValues(alpha: theme.brightness == Brightness.light ? 0.34 : 0.2),
      ],
    );
  }
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      scheme.surface,
      scheme.surfaceContainerLow,
    ],
  );
}

List<BoxShadow> catalogShadows(
  ColorScheme scheme, {
  bool emphasized = false,
}) {
  final baseOpacity = emphasized ? 0.14 : 0.08;
  return <BoxShadow>[
    BoxShadow(
      color: scheme.shadow.withValues(alpha: baseOpacity),
      blurRadius: emphasized ? 28 : 18,
      offset: Offset(0, emphasized ? 14 : 8),
      spreadRadius: emphasized ? -10 : -12,
    ),
  ];
}

// ---------------------------------------------------------------------------
// Layout / section enums (moved from catalog_flutter_app.dart)
// ---------------------------------------------------------------------------

enum CatalogLayout {
  compact,
  medium,
  expanded,
}

enum CatalogInspectorSheetSection {
  sourceContext('source-context', Icons.article_outlined),
  catalogContext('catalog-context', Icons.info_outline),
  activity('activity', Icons.history_outlined);

  const CatalogInspectorSheetSection(this.keyValue, this.icon);

  final String keyValue;
  final IconData icon;
}

// ---------------------------------------------------------------------------
// CatalogSectionCard (moved from catalog_flutter_app.dart)
// ---------------------------------------------------------------------------

class CatalogSectionCard extends StatelessWidget {
  const CatalogSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.highlighted = false,
    this.contentPadding = const EdgeInsets.all(20),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final bool highlighted;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: catalogMotionDuration,
      curve: catalogMotionCurve,
      decoration: BoxDecoration(
        gradient: catalogSectionGradient(theme, highlighted: highlighted),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlighted ? theme.colorScheme.primary.withValues(alpha: 0.24) : theme.colorScheme.outlineVariant,
          width: highlighted ? 1.2 : 1,
        ),
        boxShadow: catalogShadows(
          theme.colorScheme,
          emphasized: highlighted,
        ),
      ),
      child: Padding(
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CatalogEmptyStateCard (moved from catalog_flutter_app.dart)
// ---------------------------------------------------------------------------

class CatalogEmptyStateCard extends StatelessWidget {
  const CatalogEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: compact ? 28 : 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CatalogSelectionPlaceholder (moved from catalog_flutter_app.dart)
// ---------------------------------------------------------------------------

class CatalogSelectionPlaceholder extends StatelessWidget {
  const CatalogSelectionPlaceholder({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: CatalogEmptyStateCard(
        icon: Icons.touch_app_outlined,
        title: title,
        message: message,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CatalogQueueSkeleton (moved from catalog_flutter_app.dart)
// ---------------------------------------------------------------------------

class CatalogQueueSkeleton extends StatelessWidget {
  const CatalogQueueSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List<Widget>.generate(5, (index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SkeletonLine(widthFactor: 0.55, height: 18),
                  SizedBox(height: 12),
                  SkeletonLine(widthFactor: 0.3),
                  SizedBox(height: 16),
                  SkeletonLine(widthFactor: 1),
                  SizedBox(height: 8),
                  SkeletonLine(widthFactor: 0.5),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// CatalogActivitySkeleton (moved from catalog_flutter_app.dart)
// ---------------------------------------------------------------------------

class CatalogActivitySkeleton extends StatelessWidget {
  const CatalogActivitySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(4, (index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Row(
            children: <Widget>[
              CircleAvatar(radius: 12),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SkeletonLine(widthFactor: 0.55),
                    SizedBox(height: 8),
                    SkeletonLine(widthFactor: 0.35),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// SkeletonLine (moved from catalog_flutter_app.dart)
// ---------------------------------------------------------------------------

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    required this.widthFactor,
    this.height = 12,
  });

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MetaPill (moved from catalog_flutter_app.dart)
// ---------------------------------------------------------------------------

class MetaPill extends StatelessWidget {
  const MetaPill({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.82),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MetaLine (moved from catalog_flutter_app.dart)
// ---------------------------------------------------------------------------

class MetaLine extends StatelessWidget {
  const MetaLine({
    super.key,
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueWidget = selectable
        ? SelectableText(
            value,
            style: theme.textTheme.bodyMedium,
          )
        : Text(value, style: theme.textTheme.bodyMedium);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        valueWidget,
      ],
    );
  }
}
