// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

part of 'render_float_column.dart';

extension on RenderFloatColumn {
  bool get isLTR => textDirection == TextDirection.ltr;
  bool get isRTL => textDirection == TextDirection.rtl;

  Size _performLayout() {
    final BoxConstraints childConstraints;
    if (crossAxisAlignment == CrossAxisAlignment.stretch) {
      childConstraints = BoxConstraints.tightFor(width: constraints.maxWidth);
    } else {
      childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    }

    final rc = _RenderCursor(this, childConstraints, firstChild);

    // This gets updated to the previous non-floated child's bottom margin.
    var prevBottomMargin = 0.0;

    for (var i = 0; i < childManager.textAndWidgets.length; i++) {
      assert(rc.index == i);
      rc.index = i;
      final el = childManager.textAndWidgets[i];

      // If this a floated child widget of a WrappableText, it has already
      // been laid out, so skip it.
      if (el is MetaData &&
          el.metaData is FloatData &&
          (el.metaData as FloatData).wrappableTextIndex != null &&
          rc.maybeChild != null &&
          rc.child.hasSize) {
        // Nothing to do here...
      } else {
        // If it is a Widget...
        if (el is Widget) {
          // All widgets are wrapped in a MetaData widget with FloatData.
          final floatData =
              ((rc.child as RenderMetaData).metaData as FloatData);

          // If not floated, resolve the margin and update `rc.y` and
          // `prevBottomMargin`.
          if (floatData.float == FCFloat.none) {
            final margin = floatData.margin.resolve(textDirection);
            final topMargin = math.max(prevBottomMargin, margin.top);
            rc.y += topMargin;
            prevBottomMargin = margin.bottom;
          }

          _layoutWidget(rc, childConstraints, floatData);
        }

        // Else, if it is a WrappableText...
        else if (el is WrappableText) {
          // Resolve the margin and update `rc.y` and `prevBottomMargin`.
          final textDirection = el.textDirection ?? this.textDirection;
          final margin = el.margin.resolve(textDirection);
          final topMargin = math.max(prevBottomMargin, margin.top);
          rc.y += topMargin;
          prevBottomMargin = margin.bottom;

          // If the child is a RenderStack, set it back to the original
          // WrappableText widget.
          if (rc.child is RenderStack) {
            rc.updateCurrentChildWidget(el.toWidget(defaultTextStyle));
          }

          _layoutWrappableText(el, rc, childConstraints, textDirection);
        } else {
          assert(false);
        }
      }

      rc.moveNext();
    }

    rc.y += prevBottomMargin;
    final totalHeight =
        math.max(rc.floatL.maxYBelow(rc.y), rc.floatR.maxYBelow(rc.y));
    return Size(constraints.maxWidth, totalHeight);
  }

  /// Lays out child widget.
  void _layoutWidget(
    _RenderCursor rc,
    BoxConstraints childConstraints,
    FloatData floatData,
  ) {
    final margin = floatData.margin.resolve(textDirection);
    final padding = floatData.padding.resolve(textDirection);
    final maxWidth = childConstraints.maxWidth;

    // For floated children the margin box is what sibling content wraps
    // around, like CSS, so the margins act as additional padding. For
    // non-floated children the vertical margins are handled by the caller,
    // and the horizontal margins are handled below via `minX` and `maxX`.
    final isFloated = floatData.float != FCFloat.none;
    final inset = isFloated ? margin + padding : padding;

    final maxWidthMinusPadding = math.max(0.0,
        maxWidth - margin.left - margin.right - padding.left - padding.right);
    final childMaxWidth =
        math.min(maxWidthMinusPadding, maxWidth * floatData.maxWidthPercentage);

    var widgetConstraints = childConstraints;
    if (childMaxWidth != childConstraints.maxWidth) {
      widgetConstraints = childConstraints.copyWith(
        maxWidth: childMaxWidth,
        minWidth: math.min(widgetConstraints.minWidth, childMaxWidth),
      );
    }

    rc.child.layout(widgetConstraints, parentUsesSize: true);

    var alignment = crossAxisAlignment;

    // Should this child widget be floated to the left or right?
    List<Rect>? addToFloatRects;
    if (floatData.float != FCFloat.none) {
      final float = resolveFloat(floatData.float, withDir: textDirection);
      assert(float == FCFloat.left || float == FCFloat.right);
      if (float == FCFloat.left) {
        addToFloatRects = rc.floatL;
        alignment = isLTR ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      } else {
        addToFloatRects = rc.floatR;
        alignment = isRTL ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      }
    }

    var yPosNext = rc.y;

    // Check for `clear` and adjust `yPosNext` accordingly.
    final clear = resolveClear(floatData.clear, withDir: textDirection);
    final spacing = floatData.clearMinSpacing;
    if (clear == FCClear.left || clear == FCClear.both) {
      yPosNext = rc.floatL.nextY(yPosNext, spacing);
    }
    if (clear == FCClear.right || clear == FCClear.both) {
      yPosNext = rc.floatR.nextY(yPosNext, spacing);
    }

    final totalMinWidth = rc.child.size.width + inset.left + inset.right;
    final minX = isFloated ? 0.0 : margin.left;
    final maxX = math.max(
        minX + totalMinWidth, maxWidth - (isFloated ? 0.0 : margin.right));

    // Find space for this widget...
    var rect = findSpaceFor(
      startY: yPosNext,
      width: math.min(maxWidth, totalMinWidth),
      height: rc.child.size.height + inset.top + inset.bottom,
      minX: minX,
      maxX: maxX,
      floatL: rc.floatL,
      floatR: rc.floatR,
    );

    // Adjust rect for the inset.
    if (inset != EdgeInsets.zero) {
      rect = Rect.fromLTRB(
        rect.left + inset.left,
        rect.top + inset.top,
        rect.right - inset.right,
        rect.bottom - inset.bottom,
      );
    }

    // Calculate `xPos` based on alignment and available space.
    final xPos = _xPosForChildWithWidth(
        rc.child.size.width, alignment, rect.left, rect.right);
    (rc.child.parentData! as FloatColumnParentData).offset =
        Offset(xPos, rect.top);

    if (addToFloatRects != null) {
      // Include the inset (padding and margins) for the floated rect.
      addToFloatRects.add(Rect.fromLTRB(
        xPos - inset.left,
        rect.top - inset.top,
        xPos + rc.child.size.width + inset.right,
        rect.top + rc.child.size.height + inset.bottom,
      ));
      // This widget was floated, so set `yPosNext` back to `rc.y`.
      yPosNext = rc.y;
    } else {
      yPosNext = rect.top + rc.child.size.height + inset.bottom;
    }

    rc.y = yPosNext;
  }

  /// Lays out the given WrappableText object, and returns the y position for
  /// the next child.
  void _layoutWrappableText(
    WrappableText wt,
    _RenderCursor rc,
    BoxConstraints childConstraints,
    TextDirection textDirection,
  ) {
    final margin = wt.margin.resolve(textDirection);
    final padding = wt.padding.resolve(textDirection);

    // Is the paragraph justified? If so, when it is split into chunks, the
    // chunks need special handling so that the lines at chunk boundaries are
    // justified. See [_TextChunk.justifySpan].
    final justified =
        (wt.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start) ==
            TextAlign.justify;

    var yPosNext = rc.y + padding.top;

    // Check for `clear` and adjust `yPosNext` accordingly.
    final clear = resolveClear(wt.clear, withDir: textDirection);
    if (clear == FCClear.left || clear == FCClear.both) {
      yPosNext = rc.floatL.maxYBelow(yPosNext);
    }
    if (clear == FCClear.right || clear == FCClear.both) {
      yPosNext = rc.floatR.maxYBelow(yPosNext);
    }

    // Does this WrappableText have any floated inline widget children?
    final wrappableTextIndex = rc.index;

    // Does this WrappableText have any floated inline widget children? This
    // is checked once here so the render tree walk in `layoutFloatedChildren`
    // can be skipped entirely for paragraphs without them (the common case).
    final hasFloatedChildren = wt.text._hasFloatedChildren(wrappableTextIndex);

    // Keep track of the indices of the floated widget children that have
    // already been laid out, because should only be laid out once.
    final laidOutFloaterIndices = <int>{};

    final textChunks = <_TextChunk>[];
    WrappableText? remaining = wt.copyWith(
        text: TextSpan(style: defaultTextStyle.style, children: [wt.text]));
    while (remaining != null) {
      // Get the estimated line height for the first line. We want to find
      // space for at least the first line of text.
      final estLineHeight =
          remaining.text.initialLineHeight(wt.textScaler ?? defaultTextScaler);

      // While the text starts with a line feed and more than one line
      // remains, remove the line feed, add the line height to `yPosNext`,
      // then re-run the loop. If `maxLines` is down to one line, the leading
      // line feed is left in the text so it renders as a single empty line,
      // the same as it would in a Text widget.
      if ((remaining.maxLines == null || remaining.maxLines! > 1) &&
          remaining.text.initialText().startsWith('\n')) {
        do {
          remaining = remaining!.copyWith(
              text: remaining.text.skipChars(1),
              maxLines:
                  remaining.maxLines == null ? null : remaining.maxLines! - 1);
          yPosNext += estLineHeight;
        } while ((remaining.maxLines == null || remaining.maxLines! > 1) &&
            remaining.text.initialText().startsWith('\n'));

        // Update the widget, and re-run the loop...
        rc.updateCurrentChildWidget(remaining.toWidget(defaultTextStyle));
        continue; //-------------------------------------------->
      }

      final indent = textChunks.isEmpty ? wt.indent : 0.0;
      final estScaledFontSize = remaining.text
          .initialScaledFontSize(wt.textScaler ?? defaultTextScaler);
      final lineMinWidth =
          estScaledFontSize * 4.0 + padding.left + indent + padding.right;

      // Find space for a width of at least `estLineHeight * 4.0`. This may
      // need to be tweaked, or it could be an option passed in, or we could
      // layout the text and find the actual width of the first word, and that
      // could be the minimum width?
      var rect = findSpaceFor(
          startY: yPosNext,
          width: lineMinWidth,
          height: estLineHeight,
          minX: margin.left,
          maxX: math.max(margin.left + lineMinWidth,
              childConstraints.maxWidth - margin.right),
          floatL: rc.floatL,
          floatR: rc.floatR);

      // Adjust rect for padding.
      rect = Rect.fromLTRB(
        rect.left + padding.left + indent,
        rect.top,
        rect.right - padding.right,
        rect.bottom,
      );

      final subConstraints = childConstraints.copyWith(
        maxWidth: rect.width,
        minWidth: math.min(childConstraints.minWidth, rect.width),
      );

      // Layout the text and inline widget children.
      rc.child.layout(subConstraints, parentUsesSize: true);

      // If this is the first line of the paragraph, and the indent value is
      // not zero, the second line has a different width and needs to be
      // laid out separately, so set the `bottom` value accordingly.
      final bottom = math.min(rect.bottom,
          indent == 0.0 ? rect.bottom : rect.top + estLineHeight / 2.0);

      // `findSpaceFor` just checked for space for the first line of text.
      // Now that the text has been laid out, we need to see if the available
      // space extends to the full height of the text.
      final startY = rect.top + estLineHeight;
      final nextFloatTop = math.min(
        rc.floatL.topOfTopMostRectAtOrBelow(startY),
        rc.floatR.topOfTopMostRectAtOrBelow(startY),
      );
      final yChange = math.min(bottom, nextFloatTop);

      // If the text extends past `yChange`, we need to split the text
      // and layout each part individually...
      if (rect.top + rc.child.size.height > yChange + precisionErrorTolerance) {
        final renderParagraph = rc.childRenderParagraph();
        if (renderParagraph == null) {
          assert(false);
        } else {
          // Calculate the approximate x, y to split the text at, which
          // depends on the text direction.
          //
          // ⦿ Shows the x, y offsets the text should be split at:
          //
          // LTR example:
          //  | This is what you   ┌──────────┐
          //  | shall do; Love the ⦿          │
          //  ├────────┐ earth and ⦿──────────┤
          //  │        │ sun and the animals, |
          //  ├────────┘ despise riches, give ⦿
          //  │ alms to every one that asks...|
          //
          // RTL example:
          //  |   you what is This ┌──────────┐
          //  ⦿ the Love ;do shall │          │
          //  ├────────⦿ and earth └──────────┤
          //  │        │ ,animals the and sun |
          //  ├────────⦿ give ,riches despise |
          //  │...asks that one every to alms |
          //

          final x = textDirection == TextDirection.ltr ? rect.width : 0.0;
          final y = math.min(yChange, nextFloatTop - estLineHeight) - rect.top;
          final (parts, splitAtHardBreak) = remaining.text.splitAt(
              renderParagraph.getPositionForOffset(Offset(x, y)).offset);

          // If it was split into two spans...
          if (parts.length == 2) {
            final part1 = remaining.copyWith(
                text: parts.first, clearKey: textChunks.isNotEmpty);

            // Update the current child's widget and re-layout it.
            rc.updateCurrentChildWidget(part1.toWidget(defaultTextStyle));
            rc.child.layout(subConstraints, parentUsesSize: true);

            // Does [part1] have any floated child widgets that needed to be
            // laid out?
            if (part1.text._hasFloatedChildren(wrappableTextIndex) &&
                rc.layoutFloatedChildren(
                    laidOutFloaterIndices, wrappableTextIndex, rect.top)) {
              // If so, we need to re-run the loop...
              continue;
            }

            // If [maxLines] was set, [remainingLines] needs to be set to
            // [maxLines] minus the number of lines in [part1].
            int? remainingLines;
            if (remaining.maxLines != null) {
              // Estimate the number of lines in [part1].
              final lines = (rc.child.size.height / estLineHeight).round();
              remainingLines = remaining.maxLines! - lines;
            }

            // Only add [part2] if [remainingLines] is null or greater
            // than zero.
            if (remainingLines == null || remainingLines > 0) {
              // Calculate `xPos` based on alignment and available space.
              final xPos = _xPosForChildWithWidth(rc.child.size.width,
                  _alignment(wt.textAlign), rect.left, rect.right);
              yPosNext = rect.top + rc.child.size.height;

              // Justified chunks use the full available width so that a
              // chunk whose natural width is less than the available width
              // (e.g. a single-line chunk) justifies across all of it.
              final chunkWidth = justified ? rect.width : rc.child.size.width;
              final textChunk = _TextChunk(
                  Rect.fromLTWH(
                      xPos, rect.top, chunkWidth, rc.child.size.height),
                  part1,
                  justifySpan: justified && !splitAtHardBreak
                      ? _leadingWordSpan(parts.last)
                      : null);

              textChunks.add(textChunk);

              remaining = remaining.copyWith(
                  text: parts.last,
                  maxLines: remainingLines,
                  clearKey: textChunks.isNotEmpty);

              rc.updateCurrentChildWidget(remaining.toWidget(defaultTextStyle));

              // Re-run the loop...
              continue; //------------------------------------>
            }
          }
        }
      }

      // Are there any floated child widgets that needed to be laid out?
      if (hasFloatedChildren &&
          rc.layoutFloatedChildren(
              laidOutFloaterIndices, wrappableTextIndex, rect.top)) {
        // If so, we need to re-run the loop...
        continue;
      }

      final double xPos;
      if (textChunks.isNotEmpty) {
        // Calculate `xPos` based on alignment and available space.
        final x = _xPosForChildWithWidth(rc.child.size.width,
            _alignment(wt.textAlign), rect.left, rect.right);
        final chunkWidth = justified ? rect.width : rc.child.size.width;
        textChunks.add(_TextChunk(
          Rect.fromLTWH(x, rect.top, chunkWidth, rc.child.size.height),
          remaining,
        ));

        rc.updateCurrentChildWidget(
            textChunks.toWidget(childConstraints.maxWidth, defaultTextStyle));
        rc.child.layout(childConstraints, parentUsesSize: true);

        final top = textChunks.first.rect.top;
        rect = Rect.fromLTRB(
            0, top, childConstraints.maxWidth, top + rc.child.size.height);
        xPos = 0.0;
      } else {
        // Calculate `xPos` based on alignment and available space.
        xPos = _xPosForChildWithWidth(rc.child.size.width,
            _alignment(wt.textAlign), rect.left, rect.right);
      }

      (rc.child.parentData! as FloatColumnParentData).offset =
          Offset(xPos, rect.top);

      yPosNext = rect.top + rc.child.size.height;
      remaining = null;
      break;
    }

    rc.y = yPosNext + padding.bottom;
  }

  /// Given a child's [width] and [alignment], and the [minX] and [maxX],
  /// returns the x position for the child.
  double _xPosForChildWithWidth(
      double width, CrossAxisAlignment alignment, double minX, double maxX) {
    final double childCrossPosition;
    switch (alignment) {
      case CrossAxisAlignment.start:
        childCrossPosition = isLTR ? minX : maxX - width;
        break;
      case CrossAxisAlignment.end:
        childCrossPosition = isRTL ? minX : maxX - width;
        break;
      case CrossAxisAlignment.center:
        childCrossPosition = (minX + maxX) / 2.0 - width / 2.0;
        break;
      case CrossAxisAlignment.stretch:
      case CrossAxisAlignment.baseline:
        childCrossPosition = minX;
        break;
    }
    return childCrossPosition;
  }

  CrossAxisAlignment _alignment(TextAlign? textAlign) {
    switch (textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start) {
      case TextAlign.left:
        return isLTR ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      case TextAlign.right:
        return isRTL ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.justify:
        return CrossAxisAlignment.stretch;
      case TextAlign.start:
        return CrossAxisAlignment.start;
      case TextAlign.end:
        return CrossAxisAlignment.end;
    }
  }
}

class _RenderCursor {
  _RenderCursor(this.rfc, this.childConstraints, this.maybeChild);

  RenderFloatColumn rfc;
  final BoxConstraints childConstraints;

  int index = 0;
  RenderBox? previousChild;
  RenderBox? maybeChild;
  double y = 0.0;

  // The rectangles of widgets that are floated to the left or right.
  final floatL = <Rect>[];
  final floatR = <Rect>[];

  RenderBox get child => maybeChild!;

  /// The current child as a RenderParagraph, or the first descendant of the
  /// current child that is a RenderParagraph.
  RenderParagraph? childRenderParagraph() => child is RenderParagraph
      ? child as RenderParagraph
      : child.firstDescendantOfType<RenderParagraph>();

  /// Moves to the next child.
  void moveNext() {
    previousChild = child;
    maybeChild = (child.parentData! as FloatColumnParentData).nextSibling;
    index++;
  }

  /// Attempts to jump to the child at the given [index], returning `true` if
  /// successful. Fails if `childManager.childAt(index)` and
  /// `childManager.childAt(index - 1)` are `null`.
  bool jumpToIndex(int newIndex) {
    final newChild = rfc.childManager.childAt(newIndex);
    if (newChild != null) {
      maybeChild = newChild;
      previousChild =
          (newChild.parentData! as FloatColumnParentData).previousSibling;
      index = newIndex;
      return true;
    } else {
      final newPreviousChild = rfc.childManager.childAt(newIndex - 1);
      if (newPreviousChild != null) {
        previousChild = newPreviousChild;
        maybeChild =
            (newPreviousChild.parentData! as FloatColumnParentData).nextSibling;
        index = newIndex;
        return true;
      }
    }
    return false;
  }

  /// Updates the current child's widget and associated element.
  void updateCurrentChildWidget(Widget widget) {
    maybeChild = rfc._updateWidgetAt(index, widget);
  }

  /// Lays out the first floated child widget of the current WrappableText
  /// that has not already been laid out, if any. Returns `true` if a floated
  /// child widget was laid out.
  bool layoutFloatedChildren(
    Set<int> laidOutFloaterIndices,
    int wrappableTextIndex,
    double top,
  ) {
    final renderParagraph = childRenderParagraph();
    assert(renderParagraph != null);
    if (renderParagraph != null) {
      var rpChild = renderParagraph.firstChild;
      while (rpChild != null) {
        final renderMetaData = rpChild is RenderMetaData
            ? rpChild
            : rpChild.firstDescendantOfType<RenderMetaData>();
        if (renderMetaData != null && renderMetaData.metaData is FloatData) {
          final fd = renderMetaData.metaData as FloatData;
          if (fd.wrappableTextIndex == wrappableTextIndex &&
              !laidOutFloaterIndices.contains(fd.placeholderIndex)) {
            final savedIndex = index;
            assert(savedIndex == wrappableTextIndex);

            // Jump to the index of the floated child widget.
            if (jumpToIndex(fd.index)) {
              final widget = rfc.childManager.textAndWidgets[index];
              assert(widget is Widget);
              var laidOutFloatingWidget = false;
              if (widget is Widget) {
                final offset = (rpChild.parentData! as TextParentData).offset;
                if (offset == null) {
                  // The placeholder was not laid out — e.g. it is beyond the
                  // point where the text was truncated by `maxLines` — so
                  // hide the floated child by laying it out with zero size.
                  child.layout(BoxConstraints.tight(Size.zero),
                      parentUsesSize: true);
                  (child.parentData! as FloatColumnParentData).offset =
                      Offset.zero;
                  laidOutFloaterIndices.add(fd.placeholderIndex);
                } else {
                  final savedY = y;
                  // dmPrint('wrappableTextIndex ${fd.wrappableTextIndex}, '
                  //     'index: $index, placeholderIndex: '
                  //     '${fd.placeholderIndex} offset: $offset');
                  y = top + offset.dy;
                  rfc._layoutWidget(this, childConstraints, fd);
                  y = savedY;
                  laidOutFloaterIndices.add(fd.placeholderIndex);
                  laidOutFloatingWidget = true;
                }
              }

              jumpToIndex(savedIndex);
              if (laidOutFloatingWidget) return true; //-------------------->
            }
          }
        }

        rpChild = renderParagraph.childAfter(rpChild);
      }
    }

    return false;
  }
}

@immutable
class _TextChunk {
  const _TextChunk(this.rect, this.text, {this.justifySpan});
  final Rect rect;
  final WrappableText text;

  /// The text engine never justifies the last line of a paragraph, so when a
  /// justified paragraph is split into chunks, the last line of each chunk
  /// would incorrectly render ragged. To fix that, for every chunk except
  /// the last (and except chunks that end at a hard line break), this is set
  /// to a copy of the leading word of the next chunk's text. It is appended
  /// to this chunk's text so its last line ends with a soft line break, which
  /// causes the text engine to justify it. The appended word wraps to an
  /// extra line that is hidden by giving the chunk a tight height and
  /// [TextOverflow.clip]. See `toWidget` below.
  final TextSpan? justifySpan;
}

extension on List<_TextChunk> {
  Widget toWidget(double width, DefaultTextStyle defaultTextStyle) {
    final top = isEmpty ? 0.0 : first.rect.top;
    final height = isEmpty ? 0.0 : last.rect.bottom - top;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(width: width, height: height),
        for (final t in this)
          Positioned(
            left: t.rect.left,
            top: t.rect.top - top,
            child: t.justifySpan == null
                ? SizedBox(
                    width: t.rect.width,
                    child: t.text.toWidget(defaultTextStyle),
                  )
                : SizedBox(
                    width: t.rect.width,
                    height: t.rect.height,
                    child: t.text
                        .copyWith(
                          text:
                              TextSpan(children: [t.text.text, t.justifySpan!]),
                          overflow: TextOverflow.clip,
                        )
                        .toWidget(defaultTextStyle),
                  ),
          ),
      ],
    );
  }
}

extension on TextSpan {
  /// Splits this TextSpan at the given character [index], adjusted to skip
  /// past any spaces at the split point. Returns the resulting list of one
  /// or two spans, and a bool indicating whether the split point was at a
  /// hard line break (i.e. the second span originally started with a line
  /// feed, which is removed).
  (List<TextSpan>, bool) splitAt(int index) {
    var i = index;

    if (i > 0) {
      final text = toPlainText(includeSemanticsLabels: false);
      if (i < text.length - 1) {
        // Skip trailing spaces.
        final codeUnits = text.codeUnits;
        while (i < codeUnits.length - 1 && codeUnits[i] == 0x0020) {
          i++;
        }

        // Split the TextSpan at `i`.
        final split = splitAtCharacterIndex(i, ignoreFloatedWidgetSpans: true);

        // If it was split into two spans...
        if (split.length == 2) {
          //
          // This fixes a bug where, if a span is split right before a
          // line feed, and we don't remove the line feed, it is
          // rendered like two line feeds.
          //
          // If the second span starts with a '\n' (line feed), remove
          // the '\n'.
          var splitAtHardBreak = false;
          if (text.codeUnitAt(i) == 0x0a) {
            splitAtHardBreak = true;
            final s2 = split.last
                .splitAtCharacterIndex(1, ignoreFloatedWidgetSpans: true);
            if (s2.length == 2) {
              assert(
                  s2.first.toPlainText(includeSemanticsLabels: false) == '\n');
              split[1] = s2.last;
            }
          }

          return (
            [split.first as TextSpan, split.last as TextSpan],
            splitAtHardBreak
          );
        }
      }
    }

    return ([this], false);
  }
}

extension on TextSpan {
  /// Returns `true` if this TextSpan has any floated WidgetSpan children.
  bool _hasFloatedChildren(int index) =>
      !visitChildren((span) => !(span is WidgetSpan &&
          span.child is MetaData &&
          (span.child as MetaData).metaData is FloatData &&
          ((span.child as MetaData).metaData as FloatData).wrappableTextIndex ==
              index));
}

/// Returns a span containing the leading word of the given [span] (i.e. its
/// text up to, but not including, the first whitespace character or inline
/// widget), sanitized via [_sanitizedJustifySpan]. Returns `null` if the
/// span does not start with at least one word character.
///
/// The result is used as a [_TextChunk.justifySpan]. Using the actual
/// leading word of the next chunk guarantees the appended word wraps to a
/// new (hidden) line at exactly the original split point, because it
/// reconstructs the original text the split point came from.
TextSpan? _leadingWordSpan(TextSpan span) {
  final text = span.toPlainText(includeSemanticsLabels: false);
  var end = 0;
  while (end < text.length && !_endsLeadingWord(text.codeUnitAt(end))) {
    end++;
  }
  if (end == 0) return null;
  final split = span.splitAtCharacterIndex(end, ignoreFloatedWidgetSpans: true);
  return _sanitizedJustifySpan(split.first as TextSpan);
}

/// Returns `true` if the given code unit ends the leading word of a span,
/// i.e. it is whitespace or the object replacement character (which
/// represents an inline widget).
bool _endsLeadingWord(int codeUnit) =>
    codeUnit == 0x0020 /* space */ ||
    codeUnit == 0x0009 /* tab */ ||
    codeUnit == 0x000a /* line feed */ ||
    codeUnit == 0x000d /* carriage return */ ||
    codeUnit == 0xfffc /* object replacement character */;

/// Returns a copy of the given [span] with gesture recognizers and pointer
/// handlers removed, and with empty semantics labels, so it is inert and
/// ignored by assistive technologies. It is only ever hidden text, appended
/// after a chunk's visible text to force justification of the chunk's last
/// line. See [_TextChunk.justifySpan].
TextSpan _sanitizedJustifySpan(TextSpan span) => TextSpan(
      text: span.text,
      children: span.children
          ?.map((c) => c is TextSpan ? _sanitizedJustifySpan(c) : c)
          .toList(),
      style: span.style,
      semanticsLabel: span.text == null ? null : '',
      locale: span.locale,
      spellOut: false,
    );
