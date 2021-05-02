import 'package:flutter/rendering.dart';

/// Signature for a function that takes an [Object] and returns `true` to continue,
/// or `false` to cancel.
///
/// The `child` argument must not be null.
typedef CancelableObjectVisitor = bool Function(Object child);

/// Extensions on RenderObject.
extension FloatColumnExtOnRenderObject on RenderObject {
  ///
  /// Walks this [RenderObject] tree in a depth-first pre-order traversal, calling [visitor]
  /// for each child.
  ///
  /// If [visitor] returns true, the walk continues, otherwise it is canceled.
  ///
  bool visitChildrenAndTextRenderers(CancelableObjectVisitor visitor) {
    var canceled = false;
    var firstTime = true;

    // Local render object visitor function.
    void renderObjectVisitor(RenderObject ro) {
      if (canceled) return; //----------------------------------->

      if (ro is VisitChildrenOfAnyTypeMixin) {
        if (firstTime) firstTime = false;
        canceled = !(ro as VisitChildrenOfAnyTypeMixin).visitChildrenOfAnyType(visitor);
      } else {
        if (firstTime) {
          firstTime = false;
        } else {
          canceled = !visitor(ro);
        }
        if (!canceled) ro.visitChildren(renderObjectVisitor);
      }
    }

    renderObjectVisitor(this);
    return !canceled;
  }
}

///
/// Mix this into classes that should implement `visitChildrenOfAnyType`.
///
mixin VisitChildrenOfAnyTypeMixin {
  ///
  /// The implementation should call [visitor] for each immediate child of this object.
  ///
  /// If [visitor] returns `false` it should return `false` immediately, canceling
  /// the iteration over its children.
  ///
  bool visitChildrenOfAnyType(CancelableObjectVisitor visitor);
}
