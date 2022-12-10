// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/material.dart';

import 'shared.dart';

///
/// An immutable span of inline content which forms a paragraph. Only useful as
/// a child of a `FloatColumn`, which provides the capability of wrapping the
/// paragraph around child widgets that "float" to the right or left.
///
@immutable
class WrappableText {
  /// Creates a paragraph of rich text, that when used in a `FloatColumn` can
  /// wrap around floated siblings.
  ///
  /// The [text], [clear], [textAlign], [indent], and [textScaleFactor]
  /// arguments must not be null.
  ///
  /// The [textDirection], if null, defaults to the ambient `Directionality`,
  /// which in that case must not be null.
  const WrappableText({
    this.key,
    required this.text,
    this.clear = FCClear.none,
    this.textAlign,
    this.textDirection,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.textHeightBehavior,
    this.indent = 0.0,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
  })  : assert(
          // ignore: unnecessary_null_comparison
          text != null,
          'A non-null TextSpan must be provided to a WrappableText.',
        ),
        assert(maxLines == null || maxLines > 0);

  WrappableText.fromText(Text text)
      :
        // ignore: unnecessary_null_comparison
        assert(text != null),
        key = text.key,
        text = _textSpanFrom(text.textSpan, text.data, text.style),
        clear = FCClear.none,
        textAlign = text.textAlign,
        textDirection = text.textDirection,
        overflow = text.overflow,
        textScaleFactor = text.textScaleFactor,
        maxLines = text.maxLines,
        locale = text.locale,
        strutStyle = text.strutStyle,
        textHeightBehavior = text.textHeightBehavior,
        indent = 0.0,
        margin = EdgeInsets.zero,
        padding = EdgeInsets.zero;

  WrappableText.fromRichText(RichText text)
      :
        // ignore: unnecessary_null_comparison
        assert(text != null),
        key = text.key,
        text = _textSpanFrom(text.text, null, null),
        clear = FCClear.none,
        textAlign = text.textAlign,
        textDirection = text.textDirection,
        overflow = text.overflow,
        textScaleFactor = text.textScaleFactor,
        maxLines = text.maxLines,
        locale = text.locale,
        strutStyle = text.strutStyle,
        textHeightBehavior = text.textHeightBehavior,
        indent = 0.0,
        margin = EdgeInsets.zero,
        padding = EdgeInsets.zero;

  WrappableText copyWith({
    Key? key,
    TextSpan? text,
    FCClear? clear,
    TextAlign? textAlign,
    TextDirection? textDirection,
    TextOverflow? overflow,
    double? textScaleFactor,
    int? maxLines,
    Locale? locale,
    StrutStyle? strutStyle,
    ui.TextHeightBehavior? textHeightBehavior,
    double? indent,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) =>
      WrappableText(
        key: key ?? this.key,
        text: text ?? this.text,
        clear: clear ?? this.clear,
        textAlign: textAlign ?? this.textAlign,
        textDirection: textDirection ?? this.textDirection,
        overflow: overflow ?? this.overflow,
        textScaleFactor: textScaleFactor ?? this.textScaleFactor,
        maxLines: maxLines ?? this.maxLines,
        locale: locale ?? this.locale,
        strutStyle: strutStyle ?? this.strutStyle,
        textHeightBehavior: textHeightBehavior ?? this.textHeightBehavior,
        indent: indent ?? this.indent,
        margin: margin ?? this.margin,
        padding: padding ?? this.padding,
      );

  /// Unique key for this object.
  final Key? key;

  /// The text to display in this widget.
  final TextSpan text;

  /// Should this paragraph "clear" (i.e. be placed below) floated siblings?
  /// And if so, should it be placed below floated siblings on just one side
  /// (`left`, `right`, `start`, or `end`) or `both`? The default is `none`.
  final FCClear clear;

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [text] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase
  /// on its left.
  ///
  /// Defaults to the ambient `Directionality`, if any. If there is no ambient
  /// `Directionality`, then this must not be null.
  final TextDirection? textDirection;

  /// How visual overflow should be handled.
  final TextOverflow? overflow;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger
  /// than the specified font size.
  ///
  /// The value given to the constructor as textScaleFactor. If null, will
  /// use the [MediaQueryData.textScaleFactor] obtained from the ambient
  /// [MediaQuery], or 1.0 if there is no [MediaQuery] in scope.
  final double? textScaleFactor;

  /// An optional maximum number of lines for the text to span, wrapping if
  /// necessary. If the text exceeds the given number of lines, it will be
  /// truncated according to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  final int? maxLines;

  /// Used to select a font when the same Unicode character can be rendered
  /// differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with Localizations.localeOf(context).
  final Locale? locale;

  /// {@macro flutter.painting.textPainter.strutStyle}
  final StrutStyle? strutStyle;

  /// {@macro flutter.dart:ui.textHeightBehavior}
  final ui.TextHeightBehavior? textHeightBehavior;

  /// First line indent value. Defaults to zero. If it is negative, the text is
  /// laid out with a hanging indent.
  final double indent;

  /// Empty space to surround the paragraph. Similar to CSS, the top overlaps
  /// the previous sibling's bottom margin, the bottom overlaps the next
  /// sibling's top margin, and the left and right overlap floated siblings.
  final EdgeInsetsGeometry margin;

  /// Empty space to surround the paragraph that does not overlap siblings.
  final EdgeInsetsGeometry padding;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is WrappableText &&
        other.key == key &&
        other.text == text &&
        other.clear == clear &&
        other.textAlign == textAlign &&
        other.textDirection == textDirection &&
        other.overflow == overflow &&
        other.textScaleFactor == textScaleFactor &&
        other.maxLines == maxLines &&
        other.locale == locale &&
        other.strutStyle == strutStyle &&
        other.textHeightBehavior == textHeightBehavior &&
        other.indent == indent &&
        other.margin == margin &&
        other.padding == padding;
  }

  @override
  int get hashCode => Object.hash(
      key,
      text,
      clear,
      textAlign,
      textDirection,
      overflow,
      textScaleFactor,
      maxLines,
      locale,
      strutStyle,
      textHeightBehavior,
      indent,
      margin,
      padding);
}

TextSpan _textSpanFrom(InlineSpan? span, String? data, TextStyle? style) {
  final inlineSpan = span ?? TextSpan(style: style, text: data);
  final textSpan = inlineSpan is TextSpan
      ? inlineSpan
      : TextSpan(style: style, children: [inlineSpan]);
  return style == null || span == null || inlineSpan is! TextSpan
      ? textSpan
      : TextSpan(style: style, children: [textSpan]);
}
