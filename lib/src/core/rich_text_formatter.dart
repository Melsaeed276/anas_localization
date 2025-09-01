/// Rich text and advanced interpolation utilities
library;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Advanced interpolation with rich text support
class AnasInterpolation {
  /// Parse text with rich formatting and create TextSpan
  static TextSpan parseRichText(
    String text, {
    TextStyle? defaultStyle,
    Map<String, TextStyle>? styles,
    Map<String, VoidCallback>? actions,
  }) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'<(\w+)>(.*?)</\1>');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before the tag
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: defaultStyle,
        ));
      }

      final tag = match.group(1)!;
      final content = match.group(2)!;

      spans.add(TextSpan(
        text: content,
        style: styles?[tag] ?? defaultStyle,
        recognizer: actions?[tag] != null
            ? (TapGestureRecognizer()..onTap = actions![tag])
            : null,
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: defaultStyle,
      ));
    }

    return TextSpan(children: spans);
  }

  /// Parse markdown-like formatting
  static TextSpan parseMarkdown(String text, {TextStyle? defaultStyle}) {
    final styles = {
      'b': (defaultStyle ?? const TextStyle()).copyWith(fontWeight: FontWeight.bold),
      'i': (defaultStyle ?? const TextStyle()).copyWith(fontStyle: FontStyle.italic),
      'u': (defaultStyle ?? const TextStyle()).copyWith(decoration: TextDecoration.underline),
    };

    return parseRichText(text, defaultStyle: defaultStyle, styles: styles);
  }
}

/// Widget for displaying rich localized text
class AnasRichText extends StatelessWidget {
  const AnasRichText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.onTap,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: AnasInterpolation.parseMarkdown(text, defaultStyle: style),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}
