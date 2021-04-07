// Copyright 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

///
/// An immutable span of inline content which forms a paragraph.
///
@immutable
class FlexTextSpan {
  /// Creates a paragraph of rich text.
  ///
  /// The [text], [textAlign], [softWrap], [overflow], and [textScaleFactor]
  /// arguments must not be null.
  ///
  /// The [maxLines] property may be null (and indeed defaults to null), but if
  /// it is not null, it must be greater than zero.
  ///
  /// The [textDirection], if null, defaults to the ambient `Directionality`,
  /// which in that case must not be null.
  const FlexTextSpan({
    required this.text,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.indent = 0,
  })  : assert(text != null), // ignore: unnecessary_null_comparison
        assert(textAlign != null), // ignore: unnecessary_null_comparison
        assert(softWrap != null), // ignore: unnecessary_null_comparison
        assert(overflow != null), // ignore: unnecessary_null_comparison
        assert(textScaleFactor != null), // ignore: unnecessary_null_comparison
        assert(maxLines == null || maxLines > 0),
        assert(textWidthBasis != null); // ignore: unnecessary_null_comparison

  /// The text to display in this widget.
  final TextSpan text;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [text] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// Defaults to the ambient `Directionality`, if any. If there is no ambient
  /// `Directionality`, then this must not be null.
  final TextDirection? textDirection;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  final double textScaleFactor;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  final int? maxLines;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderParagraph.locale] for more information.
  final Locale? locale;

  /// {@macro flutter.painting.textPainter.strutStyle}
  final StrutStyle? strutStyle;

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  final TextWidthBasis textWidthBasis;

  /// {@macro flutter.dart:ui.textHeightBehavior}
  final ui.TextHeightBehavior? textHeightBehavior;

  /// First line indent value. Defaults to zero. If it is negative, the text is
  /// formatted with a hanging indent.
  final double indent;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is FlexTextSpan &&
        other.text == text &&
        other.textAlign == textAlign &&
        other.textDirection == textDirection &&
        other.softWrap == softWrap &&
        other.overflow == overflow &&
        other.textScaleFactor == textScaleFactor &&
        other.maxLines == maxLines &&
        other.locale == locale &&
        other.strutStyle == strutStyle &&
        other.textWidthBasis == textWidthBasis &&
        other.textHeightBehavior == textHeightBehavior &&
        other.indent == indent;
  }

  @override
  int get hashCode => hashValues(text, textAlign, textDirection, softWrap, overflow,
      textScaleFactor, maxLines, locale, strutStyle, textWidthBasis, textHeightBehavior, indent);
}
