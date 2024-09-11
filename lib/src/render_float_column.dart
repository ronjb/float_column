// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'float_column_semantics_tag.dart';
import 'float_data.dart';
import 'inline_span_ext.dart';
import 'render_object_ext.dart';
import 'render_text.dart';
import 'shared.dart';
import 'util.dart';
import 'wrappable_text.dart';

part 'render_float_column_ext.dart';
part 'render_float_column_semantics.dart';

/// Parent data for use with [RenderFloatColumn].
class FloatColumnParentData extends ContainerBoxParentData<RenderBox> {}

/// A render object that displays a vertical list of widgets and paragraphs of
/// text.
///
/// ## Layout algorithm
///
/// _This section describes how [RenderFloatColumn] positions its children._
/// _See [BoxConstraints] for an introduction to box layout models._
///
/// Layout for a [RenderFloatColumn] proceeds in six steps:
///
/// 1. Layout each child with unbounded main axis constraints and the incoming
///    cross axis constraints. If the [crossAxisAlignment] is
///    [CrossAxisAlignment.stretch], instead use tight cross axis constraints
///    that match the incoming max extent in the cross axis.
///
/// 2. The cross axis extent of the [RenderFloatColumn] is the maximum cross
///    axis extent of the children (which will always satisfy the incoming
///    constraints).
///
/// 3. The main axis extent of the [RenderFloatColumn] is the sum of the main
///    axis extents of the children (subject to the incoming constraints).
class RenderFloatColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FloatColumnParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FloatColumnParentData>,
        DebugOverflowIndicatorMixin,
        VisitChildrenOfAnyTypeMixin {
  /// Creates a FloatColumn render object.
  ///
  /// By default, the children are aligned to the start of the cross axis.
  RenderFloatColumn(
    this._textAndWidgets, {
    required CrossAxisAlignment crossAxisAlignment,
    required TextDirection textDirection,
    required DefaultTextStyle defaultTextStyle,
    required TextScaler defaultTextScaler,
    Clip clipBehavior = Clip.none,
    SelectionRegistrar? registrar,
    Color? selectionColor,
    List<RenderBox>? widgets,
  })  : _crossAxisAlignment = crossAxisAlignment,
        _textDirection = textDirection,
        _defaultTextStyle = defaultTextStyle,
        _defaultTextScaler = defaultTextScaler,
        _clipBehavior = clipBehavior,
        _selectionColor = selectionColor {
    addAll(widgets);
    _updateCache();
    this.registrar = registrar;
  }

  List<Object> get textAndWidgets => _textAndWidgets;
  List<Object> _textAndWidgets;
  set textAndWidgets(List<Object> value) {
    if (_textAndWidgets != value) {
      _textAndWidgets = value;
      _updateCache();
      markNeedsLayout();
    }
  }

  /// Cache of [WrappableTextRenderer]s.
  final _cache = <WrappableTextRenderer>[];

  /// Clears the `_cache`, calling `dispose()` on each renderer in it.
  /// This MUST be called in this object's `dispose()` method.
  void _clearAndDisposeOfCache() {
    for (final value in _cache) {
      value.dispose();
    }
    _cache.clear();
  }

  /// Updates every [TextRenderer] with [registrar].
  void _updateEveryTextRendererWith(SelectionRegistrar? registrar) {
    // If `_needsLayout` just return. This is called again after layout.
    if (_needsLayout) return;

    for (final wtr in _cache) {
      if (wtr.subsLength == 0) {
        wtr.renderer.registrar = registrar;
      } else {
        wtr.renderer.registrar = null;
        for (final renderer in wtr.renderers) {
          renderer.registrar = registrar;
        }
      }
    }
  }

  void _didChangeParagraphLayout() {
    // If `_isUpdatingCache` just return. This is called again afterwards.
    if (_isUpdatingCache) return;

    for (final wtr in _cache) {
      for (final renderer in wtr.renderers) {
        renderer.didChangeParagraphLayout();
      }
    }
  }

  var _isUpdatingCache = false;

  /// Updates the cached renderers.
  void _updateCache() {
    _isUpdatingCache = true;

    var cacheIndex = 0;
    var needsSemanticsUpdate = false;
    for (var i = 0; i < _textAndWidgets.length; i++) {
      final el = _textAndWidgets[i];
      if (el is WrappableText) {
        final wtr = cacheIndex < _cache.length ? _cache[cacheIndex] : null;
        cacheIndex++;

        if (wtr == null) {
          _cache.add(WrappableTextRenderer(
              this, el, textDirection, defaultTextStyle, selectionColor));
        } else {
          final comparison = wtr.updateWith(
              el, this, textDirection, defaultTextStyle, selectionColor);

          // If any text renderers need to layout or paint, clear some
          // semantic related caches.
          if (comparison == RenderComparison.layout ||
              comparison == RenderComparison.paint) {
            _cachedAttributedLabel = null;
            _cachedCombinedSemanticsInfos = null;
            if (comparison == RenderComparison.paint) {
              needsSemanticsUpdate = true;
            }
          }
        }
      }
    }

    // Dispose of and remove unused renderers from the cache.
    while (_cache.length > cacheIndex) {
      _cache.removeLast().dispose();
    }

    _isUpdatingCache = false;

    if (_needsLayout) {
      _didChangeParagraphLayout();
    }

    if (needsSemanticsUpdate) {
      // Calling `markNeedsSemanticsUpdate` can immediately result in a call to
      // `describeSemanticsConfiguration`, so it needs to be outside of the
      // `for` loop above.
      markNeedsSemanticsUpdate();
    }
  }

  /// How the children should be placed along the cross axis.
  ///
  /// If the [crossAxisAlignment] is either [CrossAxisAlignment.start] or
  /// [CrossAxisAlignment.end], then the [textDirection] must not be null.
  CrossAxisAlignment get crossAxisAlignment => _crossAxisAlignment;
  CrossAxisAlignment _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    if (_crossAxisAlignment != value) {
      _crossAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// Controls the meaning of the [crossAxisAlignment] property's
  /// [CrossAxisAlignment.start] and [CrossAxisAlignment.end] values.
  ///
  /// If the [crossAxisAlignment] is either [CrossAxisAlignment.start] or
  /// [CrossAxisAlignment.end], then the [textDirection] must not be null.
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      _updateCache();
    }
  }

  DefaultTextStyle get defaultTextStyle => _defaultTextStyle;
  DefaultTextStyle _defaultTextStyle;
  set defaultTextStyle(DefaultTextStyle value) {
    if (_defaultTextStyle != value) {
      _defaultTextStyle = value;
      _updateCache();
    }
  }

  TextScaler get defaultTextScaler => _defaultTextScaler;
  TextScaler _defaultTextScaler;
  set defaultTextScaler(TextScaler value) {
    if (_defaultTextScaler != value) {
      _defaultTextScaler = value;
      _updateCache();
    }
  }

  /// The [SelectionRegistrar] this paragraph will be, or is, registered to.
  SelectionRegistrar? get registrar => _registrar;
  SelectionRegistrar? _registrar;
  set registrar(SelectionRegistrar? value) {
    if (value == _registrar) {
      return;
    }
    _registrar = value;
    _updateEveryTextRendererWith(registrar);
  }

  /// The color to use when painting the selection.
  ///
  /// Ignored if the text is not selectable (e.g. if [registrar] is null).
  Color? get selectionColor => _selectionColor;
  Color? _selectionColor;
  set selectionColor(Color? value) {
    if (_selectionColor == value) {
      return;
    }
    _selectionColor = value;
    _updateCache();
  }

  // Set during layout if overflow occurred on the main axis.
  double _overflow = 0.0;

  // Check whether any meaningful overflow is present. Values below an epsilon
  // are treated as not overflowing.
  bool get _hasOverflow => _overflow > precisionErrorTolerance;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.none;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  var _needsLayout = true;

  @override
  bool get alwaysNeedsCompositing =>
      _cache.any((wtr) => wtr.alwaysNeedsCompositing);

  @override
  void markNeedsLayout() {
    _needsLayout = true;
    _overflow = 0.0;
    _didChangeParagraphLayout();
    super.markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FloatColumnParentData) {
      child.parentData = FloatColumnParentData();
    }
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var didHitChild = false;

    // First, hit test text renderers.
    visitTextRendererChildren((tr) {
      final rect = tr.textRect;
      if (rect.contains(position)) {
        final textPosition = tr.getPositionForOffset(position - tr.offset);
        final span = tr.text.getSpanForPosition(textPosition);
        if (span != null && span is HitTestTarget) {
          result.add(HitTestEntry(span as HitTestTarget));
          didHitChild = true;
        }
      }

      return true; // Keep walking the list of text renderers...
    });

    // Finally, hit test render object children.
    var child = firstChild;
    while (child != null) {
      final textParentData = child.parentData! as FloatColumnParentData;
      final transform = Matrix4.translationValues(
        textParentData.offset.dx,
        textParentData.offset.dy,
        0.0,
      );
      if (result.addWithPaintTransform(
          transform: transform,
          position: position,
          hitTest: (result, transformed) =>
              child!.hitTest(result, position: transformed))) {
        didHitChild = true;

        // Stop at the first child hit.
        break;
      }

      child = childAfter(child);
    }

    return didHitChild;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    assert(debugCannotComputeDryLayout(
        reason: 'Dry layout cannot be efficiently computed.'));
    return Size.zero;
  }

  @override
  void performLayout() {
    size = _performLayout();
  }

  void _paintFloatColumn(PaintingContext context, Offset offset) {
    var child = firstChild;
    var textIndex = 0;
    var i = 0;
    for (final el in _textAndWidgets) {
      //---------------------------------------------------------------------
      // If it is a Widget
      //
      if (el is Widget) {
        final floatData = child!.floatData;
        assert(floatData.index == i && floatData.placeholderIndex == 0);

        final childParentData = child.parentData! as FloatColumnParentData;
        context.paintChild(child, childParentData.offset + offset);
        child = childParentData.nextSibling;
      }

      //---------------------------------------------------------------------
      // Else, if it is a WrappableText
      //
      else if (el is WrappableText) {
        final wtr = _cache[textIndex];
        textIndex++;

        for (final textRenderer in wtr.renderers) {
          textRenderer.paint(context, offset);
        }

        // dmPrint('painted $i, text at ${wtr.offset! + offset}');

        // If this paragraph DOES have inline widget children...
        if (child != null && child.floatData.index == i) {
          var widgetIndex = 0;
          while (child != null && child.floatData.index == i) {
            assert(child.floatData.placeholderIndex == widgetIndex);
            final childParentData = child.parentData! as FloatColumnParentData;

            if (child.floatData.float != FCFloat.none) {
              // Floated inline widget children are rendered like normal
              // children.
              context.paintChild(child, childParentData.offset + offset);
            } else {
              // Non-floated inline widget children are scaled with the text.
              context.pushTransform(
                needsCompositing,
                offset + childParentData.offset,
                Matrix4.diagonal3Values(1.0, 1.0, 1.0),
                (context, offset) => context.paintChild(child!, offset),
              );
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
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasOverflow) {
      _paintFloatColumn(context, offset);
      return;
    }

    // There's no point in drawing the children if we're empty.
    if (size.isEmpty) return;

    _clipRectLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      _paintFloatColumn,
      clipBehavior: clipBehavior,
      oldLayer: _clipRectLayer.layer,
    );

    assert(() {
      final debugOverflowHints = <DiagnosticsNode>[
        ErrorDescription(
          'The edge of the $runtimeType that is overflowing has been marked '
          'in the rendering with a yellow and black striped pattern. This is '
          'usually caused by the contents being too big for the constraints.',
        ),
        ErrorHint(
          'This is considered an error condition because it indicates that '
          'there  is content that cannot be seen. If the content is '
          'legitimately bigger  than the available space, consider clipping '
          'it with a ClipRect widget  before putting it in the FloatColumn.',
        ),
      ];

      // Simulate a child rect that overflows by the right amount. This child
      // rect is never used for drawing, just for determining the overflow
      // location and amount.
      final overflowChildRect =
          Rect.fromLTWH(0.0, 0.0, 0.0, size.height + _overflow);
      paintOverflowIndicator(
          context, offset, Offset.zero & size, overflowChildRect,
          overflowHints: debugOverflowHints);
      return true;
    }());
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer =
      LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clearAndDisposeOfCache();
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    switch (clipBehavior) {
      case Clip.none:
        return null;
      case Clip.hardEdge:
      case Clip.antiAlias:
      case Clip.antiAliasWithSaveLayer:
        return _hasOverflow ? Offset.zero & size : null;
    }
  }

  @override
  String toStringShort() {
    var header = super.toStringShort();
    if (!kReleaseMode && _hasOverflow) header += ' OVERFLOWING';
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<CrossAxisAlignment>(
          'crossAxisAlignment', crossAxisAlignment))
      ..add(EnumProperty<TextDirection>('textDirection', textDirection,
          defaultValue: null));
  }

  //
  // Semantics related:
  //

  /// Collected during [describeSemanticsConfiguration], used by
  /// [assembleSemanticsNode].
  AttributedString? _cachedAttributedLabel;

  // Caches [SemanticsNode]s created during [assembleSemanticsNode] so they
  // can be re-used when [assembleSemanticsNode] is called again. This ensures
  // stable ids for the [SemanticsNode]s of [TextSpan]s across
  // [assembleSemanticsNode] invocations.
  LinkedHashMap<Key, SemanticsNode>? _cachedChildNodes;

  Map<int, List<List<InlineSpanSemanticsInformation>>>?
      _cachedCombinedSemanticsInfos;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    _describeSemanticsConfiguration(config);
  }

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    _assembleSemanticsNode(node, config, children);
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _cachedChildNodes = null;
  }

  //
  // Utility functions:
  //

  Map<int, List<List<InlineSpanSemanticsInformation>>> getSemanticsInfo({
    bool combined = false,
  }) {
    final semanticsInfo = <int, List<List<InlineSpanSemanticsInformation>>>{};

    var textIndex = 0;

    var i = 0;
    for (final el in _textAndWidgets) {
      if (el is Widget) {
        // Add a placeholder for each regular child widget.
        semanticsInfo[i] = [
          [InlineSpanSemanticsInformation.placeholder]
        ];
      } else if (el is WrappableText) {
        final wtr = _cache[textIndex++];
        semanticsInfo[i] = [
          for (final textRenderer in wtr.renderers)
            textRenderer.getSemanticsInfo(combined: combined)
        ];
      } else {
        assert(false);
      }

      i++;
    }

    return semanticsInfo;
  }

  @override
  bool visitChildrenOfAnyType(CancelableObjectVisitor visitor) {
    var child = firstChild;
    var textIndex = 0;
    var i = 0;

    for (final el in _textAndWidgets) {
      if (el is Widget) {
        final floatData = child!.floatData;
        assert(floatData.index == i && floatData.placeholderIndex == 0);

        // Visit the child widget's render object.
        if (!visitor(child)) return false; //------------------------------->
        child = childAfter(child);
      } else if (el is WrappableText) {
        final wtr = _cache[textIndex++];
        assert(wtr.renderer.placeholderSpans.isEmpty ||
            (child != null && child.floatData.index == i));

        // Visit all the text renderers.
        for (final textRenderer in wtr.renderers) {
          if (!visitor(textRenderer)) return false; //---------------------->
        }

        // Visit all the child render objects embedded in the text.
        var widgetIndex = 0;
        while (child != null && child.floatData.index == i) {
          assert(child.floatData.placeholderIndex == widgetIndex);
          if (!visitor(child)) return false; //----------------------------->
          child = childAfter(child);
          widgetIndex++;
        }
      } else {
        assert(false);
      }

      i++;
    }
    return true;
  }

  /// Walks [InlineSpan] children and each [InlineSpan]s descendants in
  /// pre-order and calls [visitor] for each span that has content.
  ///
  /// When [visitor] returns true, the walk continues. When [visitor]
  /// returns false, the walk ends.
  bool visitInlineSpanChildren(InlineSpanVisitor visitor) {
    var textIndex = 0;
    for (final el in _textAndWidgets) {
      if (el is WrappableText) {
        final wtr = _cache[textIndex++];
        for (final textRenderer in wtr.renderers) {
          if (!textRenderer.text.visitChildren(visitor)) return false;
        }
      }
    }
    return true;
  }

  /// Walks [TextRenderer] children and calls [visitor] for each.
  ///
  /// When [visitor] returns true, the walk continues. When [visitor]
  /// returns false, the walk ends.
  bool visitTextRendererChildren(
      bool Function(TextRenderer textRenderer) visitor) {
    var textIndex = 0;
    for (final el in _textAndWidgets) {
      if (el is WrappableText) {
        final wtr = _cache[textIndex++];
        for (final textRenderer in wtr.renderers) {
          if (!visitor(textRenderer)) return false;
        }
      }
    }
    return true;
  }
}

extension on RenderBox {
  FloatData get floatData => ((this as RenderMetaData).metaData as FloatData);
}

extension _PrivateExtOnMapOfListOfList<S, T> on Map<S, List<List<T>>> {
  bool anyItem(bool Function(T) test) {
    for (final entry in entries) {
      for (final list in entry.value) {
        if (list.any(test)) return true;
      }
    }
    return false;
  }
}
