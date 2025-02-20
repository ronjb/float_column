part of 'render_float_column.dart';

extension on RenderFloatColumn {
  bool get isLTR => textDirection == TextDirection.ltr;
  bool get isRTL => textDirection == TextDirection.rtl;

  Size _performLayout() {
    final constraints = this.constraints;

    final BoxConstraints childConstraints;
    if (crossAxisAlignment == CrossAxisAlignment.stretch) {
      childConstraints = BoxConstraints.tightFor(width: constraints.maxWidth);
    } else {
      childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    }

    final rc = _RenderCursor(this, firstChild);

    // This gets updated to the previous non-floated child's bottom margin.
    var prevBottomMargin = 0.0;

    for (var i = 0; i < childManager.textAndWidgets.length; i++) {
      assert(rc.index == i);
      rc.index = i;
      final el = childManager.textAndWidgets[i];

      // Update the current child's widget and associated element.
      rc.updateCurrentChildsWidget(
          el is Widget ? el : (el as WrappableText).toWidget());
      if (rc.maybeChild == null) {
        assert(false);
        continue;
      }

      // If it is a Widget...
      if (el is Widget) {
        final floatData = FloatData(i, 0, el);

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

        _layoutWrappableText(el, rc, childConstraints, textDirection);
      } else {
        assert(false);
      }

      rc.moveNext();
    }

    // Remove any extra children.
    while (rc.maybeChild != null) {
      final childParentData = rc.child.parentData! as FloatColumnParentData;
      final nextChild = childParentData.nextSibling;
      _removeChild(rc.child);
      rc.maybeChild = nextChild;
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

    final totalMinWidth = rc.child.size.width + padding.left + padding.right;
    final minX = margin.left;
    final maxX = math.max(minX + totalMinWidth, maxWidth - margin.right);

    // Find space for this widget...
    var rect = findSpaceFor(
      startY: yPosNext,
      width: math.min(maxWidth, totalMinWidth),
      height: rc.child.size.height + padding.top + padding.bottom,
      minX: minX,
      maxX: maxX,
      floatL: rc.floatL,
      floatR: rc.floatR,
    );

    // Adjust rect for padding.
    if (padding != EdgeInsets.zero) {
      rect = Rect.fromLTRB(
        rect.left + padding.left,
        rect.top + padding.top,
        rect.right - padding.right,
        rect.bottom - padding.bottom,
      );
    }

    // Calculate `xPos` based on alignment and available space.
    final xPos = _xPosForChildWithWidth(
        rc.child.size.width, alignment, rect.left, rect.right);
    (rc.child.parentData! as FloatColumnParentData).offset =
        Offset(xPos, rect.top);

    if (addToFloatRects != null) {
      // Include padding for the floated rect.
      addToFloatRects.add(Rect.fromLTRB(
        xPos - padding.left,
        rect.top - padding.top,
        xPos + rc.child.size.width + padding.right,
        rect.top + rc.child.size.height + padding.bottom,
      ));
      // This widget was floated, so set `yPosNext` back to `rc.y`.
      yPosNext = rc.y;
    } else {
      yPosNext = rect.top + rc.child.size.height + padding.bottom;
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
    final maxWidth = childConstraints.maxWidth;

    var yPosNext = rc.y + padding.top;

    // Check for `clear` and adjust `yPosNext` accordingly.
    final clear = resolveClear(wt.clear, withDir: textDirection);
    if (clear == FCClear.left || clear == FCClear.both) {
      yPosNext = rc.floatL.maxYBelow(yPosNext);
    }
    if (clear == FCClear.right || clear == FCClear.both) {
      yPosNext = rc.floatR.maxYBelow(yPosNext);
    }

    // Keep track of the indices of the floated inline widget children that
    // have already been laid out, because they can only be laid out once.
    // final laidOutFloaterIndices = <int>{};

    // RenderParagraph? rendererBeforeSplit;
    // RenderParagraph? removedSubTextRenderer;

    final textChunks = <_TextChunk>[];
    WrappableText? remaining = wt.copyWith(
        text: TextSpan(style: defaultTextStyle.style, children: [wt.text]));
    while (remaining != null) {
      // Get the estimated line height for the first line. We want to find
      // space for at least the first line of text.
      final estLineHeight =
          remaining.text.initialLineHeight(wt.textScaler ?? defaultTextScaler);

      // While the text starts with a line feed, remove the line feed, add the
      // line height to `yPosNext`, then re-run the loop.
      if (remaining.text.initialText().startsWith('\n')) {
        do {
          remaining = remaining!.copyWith(
              text: remaining.text.skipChars(1),
              maxLines:
                  remaining.maxLines == null ? null : remaining.maxLines! - 1);
          yPosNext += estLineHeight;
        } while (remaining.text.initialText().startsWith('\n'));

        // Update the widget, and re-run the loop...
        rc.updateCurrentChildsWidget(remaining.toWidget());
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
          maxX: math.max(margin.left + lineMinWidth, maxWidth - margin.right),
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
      if (rect.top + rc.child.size.height > yChange) {
        final renderParagraph = rc.child is RenderParagraph
            ? rc.child as RenderParagraph
            : rc.child.firstDescendantOfType<RenderParagraph>();
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
          final parts = remaining.text.splitAt(
              renderParagraph.getPositionForOffset(Offset(x, y)).offset);

          // If it was split into two spans...
          if (parts.length == 2) {
            final part1 = remaining.copyWith(
                text: parts.first, clearKey: textChunks.isNotEmpty);

            // Update the current child's widget and re-layout it.
            rc.updateCurrentChildsWidget(part1.toWidget());
            rc.child.layout(subConstraints, parentUsesSize: true);

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
              final textChunk = _TextChunk(
                  Rect.fromLTWH(xPos, rect.top, rc.child.size.width,
                      rc.child.size.height),
                  part1);

              if (textChunks.isEmpty) rc.moveNext();
              textChunks.add(textChunk);

              remaining = remaining.copyWith(
                  text: parts.last,
                  maxLines: remainingLines,
                  clearKey: textChunks.isNotEmpty);

              rc.updateCurrentChildsWidget(remaining.toWidget());

              // Re-run the loop...
              continue; //------------------------------------>
            }
          }
        }
      }

      /*
      // At this point renderer wtr[subIndex] has gone through its final
      // layout, so we can now layout its floated widget children, if any.

      var hasFloatedChildren = false;

      if (hasFloatedChildren) {
        /// Local func that lays out the first floated child that has not
        /// already been laid out, if any, and returns true iff a child was
        /// laid out.
        ///
        /// The floated children need to be laid out one at a time because
        /// each time one is laid out the positions of subsequent floated
        /// children will likely be affected.
        bool layoutFloatedChildren(
            TextRenderer renderer, RenderBox? firstChild) {
          if (firstChild == null) return false;
          RenderBox? child = firstChild;
          final paragraphIndex = firstChild.floatData.index;
          while (child != null && child.floatData.index == paragraphIndex) {
            final childParentData = child.parentData! as FloatColumnParentData;
            final i = child.floatData.placeholderIndex -
                renderer.startingPlaceholderIndex;
            if (i >= 0 && i < renderer.placeholderSpans.length) {
              final ctpIndex = child.floatData.placeholderIndex;
              // If this child is floated...
              if (child.floatData.float != FCFloat.none &&
                  !laidOutFloaterIndices.contains(ctpIndex)) {
                laidOutFloaterIndices.add(ctpIndex);
                final boxTop =
                    renderer.placeholderBoxForWidgetIndex(ctpIndex).top;
                _layoutWidget(
                    child,
                    childParentData,
                    childConstraints,
                    boxTop + rect.top - estLineHeight,
                    maxWidth,
                    child.floatData,
                    floatL,
                    floatR);
                return true;
              }
            }
            child = childParentData.nextSibling;
          }
          return false;
        }

        final rerunLoop = layoutFloatedChildren(wtr[subIndex], child);
        if (rerunLoop) {
          // If the original renderer was split, undo the split because it
          // will likely need to be re-split differently.
          if (rendererBeforeSplit != null) {
            if (wtr.subsLength == subIndex + 2 ||
                (rendererBeforeSplit.maxLines != null &&
                    wtr.subsLength == subIndex + 1)) {
              while (wtr.subsLength > subIndex) {
                wtr.subsRemoveLast();
              }

              // If `rendererBeforeSplit` is the base renderer, we don't want
              // to add it as a sub-renderer, so just set `subIndex` back to -1.
              if (rendererBeforeSplit == wtr.renderer) {
                assert(wtr.subsLength == 0 && subIndex == 0);
                subIndex = -1;
              } else {
                wtr.subsAdd(rendererBeforeSplit);
              }
            } else {
              assert(false);
            }
            rendererBeforeSplit = null;
            removedSubTextRenderer = null;
          }

          // Re-run the loop...
          continue; //-------------------------------------------->
        }
      }
      */

      final double xPos;
      if (textChunks.isNotEmpty) {
        // Calculate `xPos` based on alignment and available space.
        final x = _xPosForChildWithWidth(rc.child.size.width,
            _alignment(wt.textAlign), rect.left, rect.right);
        textChunks.add(_TextChunk(
          Rect.fromLTWH(x, rect.top, rc.child.size.width, rc.child.size.height),
          remaining,
        ));

        rc
          ..movePrevious()
          ..updateCurrentChildsWidget(
              textChunks.toWidget(childConstraints.maxWidth));
        rc.child.layout(childConstraints, parentUsesSize: true);

        final top = textChunks.first.rect.top;
        rect = Rect.fromLTWH(
            0, top, childConstraints.maxWidth, top + rc.child.size.height);
        xPos = 0.0;
      } else {
        // Calculate `xPos` based on alignment and available space.
        xPos = _xPosForChildWithWidth(rc.child.size.width,
            _alignment(wt.textAlign), rect.left, rect.right);
      }

      remaining = null;

      (rc.child.parentData! as FloatColumnParentData).offset =
          Offset(xPos, rect.top);

      yPosNext = rect.top + rc.child.size.height;
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
  _RenderCursor(this.rfc, this.maybeChild);

  RenderFloatColumn rfc;

  int index = 0;
  RenderBox? previousChild;
  RenderBox? maybeChild;
  double y = 0.0;

  // The rectangles of widgets that are floated to the left or right.
  final floatL = <Rect>[];
  final floatR = <Rect>[];

  RenderBox get child => maybeChild!;

  /// Moves to the next child.
  void moveNext() {
    previousChild = child;
    maybeChild = (child.parentData! as FloatColumnParentData).nextSibling;
    index++;
  }

  /// Moves to the previous child.
  void movePrevious() {
    maybeChild = previousChild;
    previousChild =
        (previousChild!.parentData! as FloatColumnParentData).previousSibling;
    index--;
  }

  /// Updates the current child's widget and associated element.
  void updateCurrentChildsWidget(Widget widget) {
    rfc.childManager.childWidgets[index] = widget;
    maybeChild = rfc._addOrUpdateChild(index, after: previousChild);
  }
}

@immutable
class _TextChunk {
  const _TextChunk(this.rect, this.text);
  final Rect rect;
  final WrappableText text;
}

extension on List<_TextChunk> {
  Widget toWidget(double width) {
    // dmPrint('widgets:');
    // for (final t in this) {
    //   dmPrint('object: ${t.x}, ${t.width}, ${t.text.toWidget()}');
    // }
    // dmPrint('------------------------------------');
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
            child: SizedBox(
              width: t.rect.width,
              child: t.text.toWidget(),
            ),
          ),
      ],
    );
  }
}

extension on TextSpan {
  List<TextSpan> splitAt(int index) {
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
          if (text.codeUnitAt(i) == 0x0a) {
            final s2 = split.last
                .splitAtCharacterIndex(1, ignoreFloatedWidgetSpans: true);
            if (s2.length == 2) {
              assert(
                  s2.first.toPlainText(includeSemanticsLabels: false) == '\n');
              split[1] = s2.last;
            }
          }

          return [split.first as TextSpan, split.last as TextSpan];
        }
      }
    }

    return [this];
  }
}
