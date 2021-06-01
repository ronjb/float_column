// Copyright 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the LICENSE file.

import 'package:flutter/rendering.dart';

///
/// Mix this into classes that should mirror the functionality of RenderParagraph.
///
mixin RenderTextMixin {
  /// The render box containing this text.
  RenderBox get renderBox;

  /// The offset of the text in the render box.
  Offset get offset;

  /// The text to display.
  InlineSpan get text;

  /// How the text should be aligned horizontally.
  TextAlign get textAlign;

  /// The directionality of the text.
  ///
  /// This decides how the [TextAlign.start], [TextAlign.end], and
  /// [TextAlign.justify] values of [textAlign] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [text] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// This must not be null.
  TextDirection get textDirection;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  double get textScaleFactor;

  /// An optional maximum number of lines for the text to span, wrapping if
  /// necessary. If the text exceeds the given number of lines, it will be
  /// truncated according to `overflow` and `softWrap`.
  int? get maxLines;

  /// Used by this paragraph's internal [TextPainter] to select a
  /// locale-specific font.
  ///
  /// In some cases, the same Unicode character may be rendered differently
  /// depending on the locale. For example, the '骨' character is rendered
  /// differently in the Chinese and Japanese locales. In these cases, the
  /// [locale] may be used to select a locale-specific font.
  Locale? get locale;

  /// {@macro flutter.painting.textPainter.strutStyle}
  StrutStyle? get strutStyle;

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  TextWidthBasis get textWidthBasis;

  /// {@macro flutter.dart:ui.textHeightBehavior}
  TextHeightBehavior? get textHeightBehavior;

  /// Returns the offset at which to paint the caret.
  ///
  /// Valid only after `layout`.
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype);

  /// {@macro flutter.painting.textPainter.getFullHeightForCaret}
  ///
  /// Valid only after `layout`.
  double? getFullHeightForCaret(TextPosition position);

  /// Returns a list of rects that bound the given selection.
  ///
  /// A given selection might have more than one rect if this text painter
  /// contains bidirectional text because logically contiguous text might not be
  /// visually contiguous.
  ///
  /// Valid only after `layout`.
  List<TextBox> getBoxesForSelection(TextSelection selection);

  /// Returns the position within the text for the given pixel offset.
  ///
  /// Valid only after `layout`.
  TextPosition getPositionForOffset(Offset offset);

  /// Returns the text range of the word at the given offset. Characters not
  /// part of a word, such as spaces, symbols, and punctuation, have word breaks
  /// on both sides. In such cases, this method will return a text range that
  /// contains the given text position.
  ///
  /// Word boundaries are defined more precisely in Unicode Standard Annex #29
  /// <http://www.unicode.org/reports/tr29/#Word_Boundaries>.
  ///
  /// Valid only after `layout`.
  TextRange getWordBoundary(TextPosition position);

  /// Returns the size of the text as laid out.
  ///
  /// This can differ from `size` if the text overflowed or if the `constraints`
  /// provided by the parent [RenderObject] forced the layout to be bigger than
  /// necessary for the given [text].
  ///
  /// This returns the [TextPainter.size] of the underlying [TextPainter].
  ///
  /// Valid only after `layout`.
  Size get textSize;

  /// The horizontal space required to paint the text.
  ///
  /// Valid only after 'layout'.
  double get width;

  /// The vertical space required to paint the text.
  ///
  /// Valid only after `layout`.
  double get height;

  /// Paints the text in the given [context] at the given [offset].
  void paint(PaintingContext context, Offset offset);
}

///
/// Adapts a [RenderParagraph] to support [RenderTextMixin].
///
class RenderParagraphAdapter with RenderTextMixin {
  RenderParagraphAdapter(this.rp);

  final RenderParagraph rp;

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) => rp.getBoxesForSelection(selection);

  @override
  double? getFullHeightForCaret(TextPosition position) => rp.getFullHeightForCaret(position);

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) =>
      rp.getOffsetForCaret(position, caretPrototype);

  @override
  TextPosition getPositionForOffset(Offset offset) => rp.getPositionForOffset(offset);

  @override
  TextRange getWordBoundary(TextPosition position) => rp.getWordBoundary(position);

  @override
  double get height => rp.size.height;

  @override
  Locale? get locale => rp.locale;

  @override
  int? get maxLines => rp.maxLines;

  @override
  Offset get offset => Offset.zero;

  @override
  RenderBox get renderBox => rp;

  @override
  StrutStyle? get strutStyle => rp.strutStyle;

  @override
  InlineSpan get text => rp.text;

  @override
  TextAlign get textAlign => rp.textAlign;

  @override
  TextDirection get textDirection => rp.textDirection;

  @override
  TextHeightBehavior? get textHeightBehavior => rp.textHeightBehavior;

  @override
  double get textScaleFactor => rp.textScaleFactor;

  @override
  Size get textSize => rp.textSize;

  @override
  TextWidthBasis get textWidthBasis => rp.textWidthBasis;

  @override
  void paint(PaintingContext context, Offset offset) => rp.paint(context, offset);

  @override
  double get width => rp.size.width;
}
