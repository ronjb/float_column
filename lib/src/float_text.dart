// Copyright 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'shared.dart';

///
/// An immutable span of inline content which forms a paragraph. Only useful as a child
/// of a `FloatColumn`, which provides the capability of wrapping the paragraph around
/// child widgets that "float" to the right and/or left.
///
@immutable
class FloatText {
  /// Creates a paragraph of rich text.
  ///
  /// The [text], [clear], [textAlign], [indent], and [textScaleFactor] arguments
  /// must not be null.
  ///
  /// The [textDirection], if null, defaults to the ambient `Directionality`,
  /// which in that case must not be null.
  const FloatText({
    required this.text,
    this.clear = FCClear.none,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textScaleFactor = 1.0,
    this.locale,
    this.strutStyle,
    this.textHeightBehavior,
    this.indent = 0,
  })  : assert(text != null), // ignore: unnecessary_null_comparison
        assert(textAlign != null), // ignore: unnecessary_null_comparison
        assert(textScaleFactor != null); // ignore: unnecessary_null_comparison

  /// The text to display in this widget.
  final TextSpan text;

  /// Should this paragraph "clear" (i.e. be placed below) floating siblings?
  /// And if so, should it be placed below floating siblings on just one side
  /// (`start` or `end`) or `both`? The default is `none`.
  final FCClear clear;

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

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  final double textScaleFactor;

  /// Used to select a font when the same Unicode character can be rendered
  /// differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderParagraph.locale] for more information.
  final Locale? locale;

  /// {@macro flutter.painting.textPainter.strutStyle}
  final StrutStyle? strutStyle;

  /// {@macro flutter.dart:ui.textHeightBehavior}
  final ui.TextHeightBehavior? textHeightBehavior;

  /// First line indent value. Defaults to zero. If it is negative, the text is
  /// formatted with a hanging indent.
  final double indent;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is FloatText &&
        other.text == text &&
        other.clear == clear &&
        other.textAlign == textAlign &&
        other.textDirection == textDirection &&
        other.textScaleFactor == textScaleFactor &&
        other.locale == locale &&
        other.strutStyle == strutStyle &&
        other.textHeightBehavior == textHeightBehavior &&
        other.indent == indent;
  }

  @override
  int get hashCode => hashValues(text, clear, textAlign, textDirection, textScaleFactor, locale,
      strutStyle, textHeightBehavior, indent);
}
