part of 'render_float_column.dart';

extension on RenderFloatColumn {
  bool get isLTR => textDirection == TextDirection.ltr;
  bool get isRTL => textDirection == TextDirection.rtl;

  Size _performLayout() {
    _cachedCombinedSemanticsInfos = null;

    final constraints = this.constraints;
    final maxWidth = constraints.maxWidth;

    final BoxConstraints childConstraints;
    if (crossAxisAlignment == CrossAxisAlignment.stretch) {
      childConstraints = BoxConstraints.tightFor(width: maxWidth);
    } else {
      childConstraints = BoxConstraints(maxWidth: maxWidth);
    }

    // These will hold the rectangles of widgets that are floated to the left
    // or right.
    final floatL = <Rect>[];
    final floatR = <Rect>[];

    var child = firstChild;
    var textIndex = 0;

    // This gets updated to the y position for the next child.
    var yPosNext = 0.0;

    // This gets updated to the previous non-floated child's bottom margin.
    var prevBottomMargin = 0.0;

    var i = 0;
    for (final el in _textAndWidgets) {
      // If it is a Widget...
      if (el is Widget) {
        final floatData = child!.floatData;
        assert(floatData.index == i && floatData.placeholderIndex == 0);

        // If not floated, resolve the margin and update `yPosNext` and
        // `prevBottomMargin`.
        if (floatData.float == FCFloat.none) {
          final margin = floatData.margin.resolve(textDirection);
          final topMargin = math.max(prevBottomMargin, margin.top);
          yPosNext += topMargin;
          prevBottomMargin = margin.bottom;
        }

        final childParentData = child.parentData! as FloatColumnParentData;

        yPosNext = _layoutWidget(child, childParentData, childConstraints,
            yPosNext, maxWidth, floatData, floatL, floatR);

        assert(child.parentData == childParentData);
        child = childParentData.nextSibling;
      }

      // Else, if it is a WrappableText...
      else if (el is WrappableText) {
        final wtr = _cache[textIndex];
        textIndex++;
        assert(wtr.renderer.placeholderSpans.isEmpty ||
            (child != null && child.floatData.index == i));

        // Resolve the margin and update `yPosNext` and `prevBottomMargin`.
        final margin = el.margin.resolve(wtr.textDirection);
        final topMargin = math.max(prevBottomMargin, margin.top);
        yPosNext += topMargin;
        prevBottomMargin = margin.bottom;

        yPosNext = _layoutWrappableText(el, wtr, child, childConstraints,
            yPosNext, maxWidth, floatL, floatR);

        // If this paragraph has inline widget children, set the `offset` and
        // `scale` for each.
        if (child != null && child.floatData.index == i) {
          var widgetIndex = 0;
          while (child != null && child.floatData.index == i) {
            assert(child.floatData.placeholderIndex == widgetIndex);
            final childParentData = child.parentData! as FloatColumnParentData;
            if (child.floatData.float == FCFloat.none) {
              final renderer = wtr.rendererWithPlaceholder(widgetIndex);
              final box = renderer.placeholderBoxForWidgetIndex(widgetIndex);
              childParentData.offset = Offset(
                  box.left + renderer.offset.dx, box.top + renderer.offset.dy);
            }
            child = childParentData.nextSibling;
            widgetIndex++;
          }
        }
      } else {
        assert(false);
      }

      i++;
    }

    yPosNext += prevBottomMargin;
    final totalHeight =
        math.max(floatL.maxYBelow(yPosNext), floatR.maxYBelow(yPosNext));
    _overflow = totalHeight > constraints.maxHeight
        ? totalHeight - constraints.maxHeight
        : 0.0;
    final newSize = constraints.constrain(Size(maxWidth, totalHeight));

    // Now that `performLayout` is finished...
    _needsLayout = false;
    _updateEveryTextRendererWith(registrar);

    return newSize;
  }

  /// Lays out the given [child] widget, and returns the y position for the
  /// next child.
  double _layoutWidget(
    RenderBox child,
    FloatColumnParentData parentData,
    BoxConstraints childConstraints,
    double yPos,
    double maxWidth,
    FloatData floatData,
    List<Rect> floatL,
    List<Rect> floatR,
  ) {
    final margin = floatData.margin.resolve(textDirection);
    final padding = floatData.padding.resolve(textDirection);

    final maxWidthMinusPadding = math.max(0.0,
        maxWidth - margin.left - margin.right - padding.left - padding.right);
    final childMaxWidth =
        math.min(maxWidthMinusPadding, maxWidth * floatData.maxWidthPercentage);

    var layoutConstraints = childConstraints;
    if (childMaxWidth != childConstraints.maxWidth) {
      layoutConstraints = childConstraints.copyWith(
        maxWidth: childMaxWidth,
        minWidth: math.min(layoutConstraints.minWidth, childMaxWidth),
      );
    }

    child.layout(layoutConstraints, parentUsesSize: true);

    var alignment = crossAxisAlignment;

    // Should this child widget be floated to the left or right?
    List<Rect>? addToFloatRects;
    if (floatData.float != FCFloat.none) {
      final float = resolveFloat(floatData.float, withDir: textDirection);
      assert(float == FCFloat.left || float == FCFloat.right);
      if (float == FCFloat.left) {
        addToFloatRects = floatL;
        alignment = isLTR ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      } else {
        addToFloatRects = floatR;
        alignment = isRTL ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      }
    }

    var yPosNext = yPos;

    // Check for `clear` and adjust `yPosNext` accordingly.
    final clear = resolveClear(floatData.clear, withDir: textDirection);
    final spacing = floatData.clearMinSpacing;
    if (clear == FCClear.left || clear == FCClear.both) {
      yPosNext = floatL.nextY(yPosNext, spacing);
    }
    if (clear == FCClear.right || clear == FCClear.both) {
      yPosNext = floatR.nextY(yPosNext, spacing);
    }

    final totalMinWidth = child.size.width + padding.left + padding.right;
    final minX = margin.left;
    final maxX = math.max(minX + totalMinWidth, maxWidth - margin.right);

    // Find space for this widget...
    var rect = findSpaceFor(
      startY: yPosNext,
      width: math.min(maxWidth, totalMinWidth),
      height: child.size.height + padding.top + padding.bottom,
      minX: minX,
      maxX: maxX,
      floatL: floatL,
      floatR: floatR,
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
    final xPos = xPosForChildWithWidth(
        child.size.width, alignment, rect.left, rect.right);
    parentData.offset = Offset(xPos, rect.top);

    if (addToFloatRects != null) {
      // Include padding for the floated rect.
      addToFloatRects.add(Rect.fromLTRB(
        xPos - padding.left,
        rect.top - padding.top,
        xPos + child.size.width + padding.right,
        rect.top + child.size.height + padding.bottom,
      ));
      // This widget was floated, so set `yPosNext` back to `yPos`.
      yPosNext = yPos;
    } else {
      yPosNext = rect.top + child.size.height + padding.bottom;
    }

    return yPosNext;
  }

  /// Lays out the given WrappableText object, and returns the y position for
  /// the next child.
  double _layoutWrappableText(
    WrappableText wt,
    WrappableTextRenderer wtr,
    RenderBox? child,
    BoxConstraints childConstraints,
    double yPos,
    double maxWidth,
    List<Rect> floatL,
    List<Rect> floatR,
  ) {
    final margin = wt.margin.resolve(wtr.textDirection);
    final padding = wt.padding.resolve(wtr.textDirection);

    var yPosNext = yPos + padding.top;

    // Check for `clear` and adjust `yPosNext` accordingly.
    final clear = resolveClear(wt.clear, withDir: wtr.textDirection);
    if (clear == FCClear.left || clear == FCClear.both) {
      yPosNext = floatL.maxYBelow(yPosNext);
    }
    if (clear == FCClear.right || clear == FCClear.both) {
      yPosNext = floatR.maxYBelow(yPosNext);
    }

    // Clear the sub-paragraph renderers for wrapping text.
    wtr.subsClearAndDispose();

    // Keep track of the indices of the floated inline widget children that
    // have already been laid out, because they can only be laid out once.
    final laidOutFloaterIndices = <int>{};

    TextRenderer? rendererBeforeSplit;
    TextRenderer? removedSubTextRenderer;

    // Loop over this WrappableText's renderers. It starts out with the default
    // text renderer which includes all the text, but if the text needs to be
    // split because the available width and/or x position changes (because of
    // floated widgets), the text is split into two new renderers that replace
    // the current renderer, and the loop is run again. This continues until
    // all the text is laid out, using as many renderers as necessary to wrap
    // around floated widgets.

    var subIndex = -1;
    while (subIndex < wtr.subsLength) {
      // Get the estimated line height for the first line. We want to find
      // space for at least the first line of text.
      final estLineHeight = wtr[subIndex].initialLineHeight();

      // If the text starts with a line feed, remove the line feed, add the
      // line height to `yPosNext`, and re-run the loop.
      final initialText = wtr[subIndex].text.initialText();
      if (initialText.isNotEmpty &&
          initialText.codeUnitAt(0) == 0x0a &&
          (wtr[subIndex].maxLines == null || wtr[subIndex].maxLines! > 1)) {
        final textRenderer = wtr[subIndex];
        final split = textRenderer.text
            .splitAtCharacterIndex(1, ignoreFloatedWidgetSpans: true);
        if (split.length == 2) {
          TextRenderer? removedSub;
          if (subIndex == -1) {
            subIndex = 0;
          } else {
            removedSub = wtr.subsRemoveAt(subIndex, dispose: false);
          }

          final maxLines =
              textRenderer.maxLines == null ? null : textRenderer.maxLines! - 1;

          wtr.subsAdd(textRenderer.copyWith(
              split.last,
              subIndex == 0 ? 0 : wtr[subIndex - 1].nextPlaceholderIndex,
              maxLines));

          removedSub?.dispose();

          yPosNext += estLineHeight;

          // Re-run the loop, keeping the index the same.
          continue; //-------------------------------------------->
        }
      }

      final estScaledFontSize = wtr[subIndex].initialScaledFontSize();

      // Adjust the left padding based on indent value.
      final paddingLeft = padding.left + (subIndex <= 0 ? wt.indent : 0.0);

      final lineMinWidth =
          estScaledFontSize * 4.0 + paddingLeft + padding.right;
      final lineMinX = margin.left;
      final lineMaxX =
          math.max(lineMinX + lineMinWidth, maxWidth - margin.right);

      // Find space for a width of at least `estLineHeight * 4.0`. This may
      // need to be tweaked, or it could be an option passed in, or we could
      // layout the text and find the actual width of the first word, and that
      // could be the minimum width?
      var rect = findSpaceFor(
          startY: yPosNext,
          width: lineMinWidth,
          height: estLineHeight,
          minX: lineMinX,
          maxX: lineMaxX,
          floatL: floatL,
          floatR: floatR);

      // Adjust rect for padding.
      rect = Rect.fromLTRB(
        rect.left + paddingLeft,
        rect.top,
        rect.right - padding.right,
        rect.bottom,
      );

      // dmPrint('findSpaceFor $yPosNext, estLineHeight $estLineHeight: $rect');

      final subConstraints = childConstraints.copyWith(
        maxWidth: rect.width,
        minWidth: math.min(childConstraints.minWidth, rect.width),
      );

      var hasFloatedChildren = false;

      // If the sub-renderer has inline widget children, set placeholder
      // dimensions, which MUST be done before `wtr[subIndex].layout` is
      // called.
      if (wtr[subIndex].placeholderSpans.isNotEmpty) {
        assert(child != null);
        hasFloatedChildren = wtr[subIndex]
            .setPlaceholderDimensions(child, subConstraints, wt.textScaler);
      }

      // Layout the text and inline widget children.
      wtr[subIndex].layout(subConstraints);

      // If this is the default (-1) or last renderer, check to see if it needs
      // to be split.
      if (subIndex == -1 || subIndex == wtr.subsLength - 1) {
        // TODO(ron): It is possible that the estimated line height is less
        // than the actual first line height, which could cause the text in the
        // line to overlap floated widgets below it. This could be fixed by
        // using `painter.computeLineMetrics` to check, and then call
        // `findSpaceFor` again, if necessary, with the actual first line
        // height.

        // If this is the first line of the paragraph, and the indent value is
        // not zero, the second line has a different left padding, so it needs
        // to be laid out separately, so set the `bottom` value accordingly.
        final bottom = math.min(
            rect.bottom,
            subIndex > 0 || wt.indent == 0.0
                ? rect.bottom
                : rect.top + estLineHeight / 2.0);

        // `findSpaceFor` just checked for space for the first line of text.
        // Now that the text has been laid out, we need to see if the available
        // space extends the full height of the text.
        final startY = rect.top + estLineHeight;
        final nextFloatTop = math.min(
          floatL.topOfTopMostRectAtOrBelow(startY),
          floatR.topOfTopMostRectAtOrBelow(startY),
        );
        final nextChangeY = math.min(bottom, nextFloatTop);

        // If the text extends past `nextChangeY`, we need to split the text,
        // and layout each part individually...
        if (rect.top + wtr[subIndex].height > nextChangeY) {
          final span = wtr[subIndex].text;
          if (span is TextSpan) {
            //
            // Calculate the approximate x, y to split the text at, which
            // depends on the text direction.
            //
            // ⦿ Shows the x, y offsets the text should be split at:
            //
            // RTL example:
            //  | This is what you   ┌──────────┐
            //  | shall do; Love the ⦿          │
            //  ├────────┐ earth and ⦿──────────┤
            //  │        │ sun and the animals, |
            //  ├────────┘ despise riches, give ⦿
            //  │ alms to every one that asks...|
            //
            // LTR example:
            //  |   you what is This ┌──────────┐
            //  ⦿ the Love ;do shall │          │
            //  ├────────⦿ and earth └──────────┤
            //  │        │ ,animals the and sun |
            //  ├────────⦿ give ,riches despise |
            //  │...asks that one every to alms |
            //
            final dir = wtr[subIndex].textDirection;
            final x = dir == TextDirection.ltr ? rect.width : 0.0;
            final y =
                math.min(nextChangeY, nextFloatTop - estLineHeight) - rect.top;

            // Get the character index in the text from the point offset.
            var charIndex =
                wtr[subIndex].getPositionForOffset(Offset(x, y)).offset;
            if (charIndex > 0) {
              final text = span.toPlainText(includeSemanticsLabels: false);
              if (charIndex < text.length - 1) {
                // Skip trailing spaces.
                final codeUnits = text.codeUnits;
                while (charIndex < codeUnits.length - 1 &&
                    codeUnits[charIndex] == 0x0020) {
                  charIndex++;
                }

                // final str1 = text.substring(0, charIndex);
                // dmPrint('Splitting at ${Offset(x, y)} after "$str1"');

                // Split the TextSpan at `charIndex`.
                final split = span.splitAtCharacterIndex(charIndex,
                    ignoreFloatedWidgetSpans: true);

                // If it was split into two spans...
                if (split.length == 2) {
                  //
                  // This fixes a bug where, if a span is split right before a
                  // line feed, and we don't remove the line feed, it is
                  // rendered like two line feeds.
                  //
                  // If the second span starts with a '\n' (line feed), remove
                  // the '\n'.
                  if (text.codeUnitAt(charIndex) == 0x0a) {
                    final s2 = split.last.splitAtCharacterIndex(1,
                        ignoreFloatedWidgetSpans: true);
                    if (s2.length == 2) {
                      assert(
                          s2.first.toPlainText(includeSemanticsLabels: false) ==
                              '\n');
                      split[1] = s2.last;
                    }
                  }

                  final textRenderer = rendererBeforeSplit = wtr[subIndex];

                  if (removedSubTextRenderer != null) {
                    if (removedSubTextRenderer == textRenderer) {
                      assert(false);
                    } else {
                      removedSubTextRenderer.dispose();
                    }
                    removedSubTextRenderer = null;
                  }

                  if (subIndex == -1) {
                    subIndex = 0;
                  } else {
                    removedSubTextRenderer = wtr.subsRemoveLast(dispose: false);
                  }

                  final part1 = textRenderer.copyWith(
                      split.first,
                      subIndex == 0
                          ? 0
                          : wtr[subIndex - 1].nextPlaceholderIndex,
                      textRenderer.maxLines);
                  wtr.subsAdd(part1);

                  // If [maxLines] was set, [remainingLines] needs to be set to
                  // [maxLines] minus the number of lines in [part1].
                  int? remainingLines;
                  if (textRenderer.maxLines != null) {
                    // Need to layout [part1] and call `computeLineMetrics` to
                    // know how many lines it has.
                    part1.layout(subConstraints);
                    final lineMetrics = part1.textPainter.computeLineMetrics();
                    remainingLines =
                        textRenderer.maxLines! - lineMetrics.length;
                  }

                  // Only add [part2] if [remainingLines] is null or greater
                  // than zero.
                  if (remainingLines == null || remainingLines > 0) {
                    wtr.subsAdd(textRenderer.copyWith(split.last,
                        wtr[subIndex].nextPlaceholderIndex, remainingLines));
                  }

                  // Re-run the loop, keeping the index the same.
                  continue; //------------------------------------>
                }
              }
            }
          }
        }
      }

      // At this point renderer wtr[subIndex] has gone through its final
      // layout, so we can now layout its floated widget children, if any.

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

          // Re-run the loop, keeping the index the same.
          continue; //-------------------------------------------->
        }
      }

      // Clear these before the next loop.
      rendererBeforeSplit = null;
      removedSubTextRenderer?.dispose();
      removedSubTextRenderer = null;

      CrossAxisAlignment alignment() {
        switch (wtr[subIndex].textAlign) {
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

      // Calculate `xPos` based on alignment and available space.
      final xPos = xPosForChildWithWidth(
          wtr[subIndex].width, alignment(), rect.left, rect.right);

      wtr[subIndex].offset = Offset(xPos, rect.top);
      yPosNext = rect.top + wtr[subIndex].height;

      subIndex++;
    } // while (subIndex < wtr.subs.length)

    return yPosNext + padding.bottom;
  }

  /// Given a child's [width] and [alignment], and the [minX] and [maxX],
  /// returns the x position for the child.
  double xPosForChildWithWidth(
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
}
