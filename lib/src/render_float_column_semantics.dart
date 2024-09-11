part of 'render_float_column.dart';

extension on RenderFloatColumn {
  void _describeSemanticsConfiguration(SemanticsConfiguration config) {
    final semanticsInfo = getSemanticsInfo();

    if (semanticsInfo.anyItem((info) => info.recognizer != null)) {
      config
        ..explicitChildNodes = true
        ..isSemanticBoundary = true;
    } else {
      if (_cachedAttributedLabel == null) {
        final buffer = StringBuffer();
        var offset = 0;
        final attributes = <StringAttribute>[];
        for (final entry in semanticsInfo.entries) {
          for (final list in entry.value) {
            for (final info in list) {
              final label = info.semanticsLabel ?? info.text;
              for (final infoAttribute in info.stringAttributes) {
                final originalRange = infoAttribute.range;
                attributes.add(
                  infoAttribute.copy(
                      range: TextRange(
                          start: offset + originalRange.start,
                          end: offset + originalRange.end)),
                );
              }
              buffer.write(label);
              offset += label.length;
            }
          }
        }
        _cachedAttributedLabel =
            AttributedString(buffer.toString(), attributes: attributes);
      }
      config
        ..attributedLabel = _cachedAttributedLabel!
        ..textDirection = textDirection;
    }
  }

  void _assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    final semanticsChildren = children;
    final newSemanticsChildren = <SemanticsNode>[];

    var renderChild = firstChild;
    var textIndex = 0;

    var currentDirection = textDirection;
    var ordinal = 0.0;
    var semanticsChildIndex = 0;

    // We need a LinkedHashMap.
    // ignore: prefer_collection_literals
    final newChildCache = LinkedHashMap<Key, SemanticsNode>();

    _cachedCombinedSemanticsInfos ??= getSemanticsInfo(combined: true);

    // dmPrint('\n\n************ assembleSemanticsNode *************');

    for (final entry in _cachedCombinedSemanticsInfos!.entries) {
      final floatColumnChildIndex = entry.key;
      var placeholderIndex = 0;

      final el = _textAndWidgets[floatColumnChildIndex];

      final wtr = (el is WrappableText) ? _cache[textIndex++] : null;
      assert(wtr == null ||
          wtr.renderer.placeholderSpans.isEmpty ||
          (renderChild != null &&
              renderChild.floatData.index == floatColumnChildIndex));

      var textRendererIndex = 0;

      for (final list in entry.value) {
        var textRangeStart = 0;
        for (final info in list) {
          if (info.isPlaceholder) {
            // A placeholder span may have 0 to multiple semantics nodes.
            while (semanticsChildren.length > semanticsChildIndex &&
                semanticsChildren.elementAt(semanticsChildIndex).isTagged(
                    FloatColumnPlaceholderSpanSemanticsTag(
                        floatColumnChildIndex, placeholderIndex))) {
              final semanticsChildNode =
                  semanticsChildren.elementAt(semanticsChildIndex);
              // dmPrint('Adding semantics node for widget '
              //     '$floatColumnChildIndex with rect $rect');
              newSemanticsChildren.add(semanticsChildNode);
              semanticsChildIndex += 1;
            }
            renderChild = childAfter(renderChild!);
            placeholderIndex += 1;
          } else {
            if (wtr == null || textRendererIndex >= wtr.renderers.length) {
              assert(false);
            } else {
              final textRenderer = wtr.renderers[textRendererIndex];

              final selection = TextSelection(
                baseOffset: textRangeStart,
                extentOffset: textRangeStart + info.text.length,
              );
              textRangeStart += info.text.length;

              // dmPrint('\n\ncalling getBoxes for '
              //     '[${selection.baseOffset}, ${selection.extentOffset}] '
              //     'substring '
              //     '[${info.text}] in [${textRenderer.toPlainText()}]\n');

              final initialDirection = currentDirection;
              final rects = textRenderer.getBoxesForSelection(selection);
              if (rects.isNotEmpty) {
                var rect = rects.first.toRect();
                currentDirection = rects.first.direction;
                for (final textBox in rects.skip(1)) {
                  rect = rect.expandToInclude(textBox.toRect());
                  currentDirection = textBox.direction;
                }

                // Any of the text boxes may have had infinite dimensions.
                // We shouldn't pass infinite dimensions up to the bridges.
                rect = Rect.fromLTWH(
                  math.max(0.0, rect.left + textRenderer.offset.dx),
                  math.max(0.0, rect.top + textRenderer.offset.dy),
                  math.min(rect.width, constraints.maxWidth),
                  math.min(rect.height, constraints.maxHeight),
                );

                // Round the current rectangle to make this API testable and
                // add some padding so that the accessibility rects do not
                // overlap with the text.
                final currentRect = Rect.fromLTRB(
                  rect.left.floorToDouble() - 4.0,
                  rect.top.floorToDouble() - 4.0,
                  rect.right.ceilToDouble() + 4.0,
                  rect.bottom.ceilToDouble() + 4.0,
                );

                final configuration = SemanticsConfiguration()
                  ..sortKey = OrdinalSortKey(ordinal++)
                  ..textDirection = initialDirection
                  ..attributedLabel = AttributedString(
                      info.semanticsLabel ?? info.text,
                      attributes: info.stringAttributes);

                final recognizer = info.recognizer;
                if (recognizer != null) {
                  if (recognizer is TapGestureRecognizer) {
                    if (recognizer.onTap != null) {
                      configuration
                        ..onTap = recognizer.onTap
                        ..isLink = true;
                    }
                  } else if (recognizer is DoubleTapGestureRecognizer) {
                    if (recognizer.onDoubleTap != null) {
                      configuration
                        ..onTap = recognizer.onDoubleTap
                        ..isLink = true;
                    }
                  } else if (recognizer is LongPressGestureRecognizer) {
                    if (recognizer.onLongPress != null) {
                      configuration.onLongPress = recognizer.onLongPress;
                    }
                  } else {
                    assert(
                        false, '${recognizer.runtimeType} is not supported.');
                  }
                }

                // dmPrint('Adding semantics node for span '
                //     '$floatColumnChildIndex:'
                //     '$textRendererIndex with rect $rect '
                //     '${recognizer == null ? '' : 'WITH RECOGNIZER '}'
                //     'for text "${info.text}" ');

                if (node.parentPaintClipRect != null) {
                  final paintRect =
                      node.parentPaintClipRect!.intersect(currentRect);
                  configuration.isHidden =
                      paintRect.isEmpty && !currentRect.isEmpty;
                }
                final SemanticsNode newChild;
                if (_cachedChildNodes?.isNotEmpty ?? false) {
                  newChild =
                      _cachedChildNodes!.remove(_cachedChildNodes!.keys.first)!;
                } else {
                  final key = UniqueKey();
                  newChild = SemanticsNode(
                    key: key,
                    showOnScreen: _createShowOnScreenFor(key),
                  );
                }
                newChild
                  ..updateWith(config: configuration)
                  ..rect = currentRect;
                newChildCache[newChild.key!] = newChild;
                newSemanticsChildren.add(newChild);
              }
            }
          }
        }
        textRendererIndex++;
      }
    }

    // Make sure we annotated all of the semantics children.
    assert(semanticsChildIndex == semanticsChildren.length);
    assert(renderChild == null);

    _cachedChildNodes = newChildCache;
    node.updateWith(
        config: config, childrenInInversePaintOrder: newSemanticsChildren);
  }

  VoidCallback? _createShowOnScreenFor(Key key) {
    return () {
      final node = _cachedChildNodes![key]!;
      showOnScreen(descendant: this, rect: node.rect);
    };
  }
}
