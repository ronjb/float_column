// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/rendering.dart';

/// Signature for a function that takes an [Object] and returns `true` to
/// continue, or `false` to cancel.
///
/// The `child` argument must not be null.
typedef CancelableObjectVisitor = bool Function(Object child);

/// Extensions on RenderObject.
extension FloatColumnExtOnRenderObject on RenderObject {
  /// Walks this [RenderObject] tree in a depth-first pre-order traversal,
  /// calling [visitor] for each child.
  ///
  /// If [visitor] returns true, the walk continues, otherwise it is canceled.
  bool visitChildrenAndTextRenderers(CancelableObjectVisitor visitor) {
    var canceled = false;

    late void Function(Object object) visitChildrenRecursively;

    void recursiveRenderObjectVisitor(RenderObject object) {
      // This is called for every child of the render object, even after the
      // [visitor] function may have returned `false` for one of the children,
      // so check if canceled before handling.
      if (!canceled) {
        canceled = !visitor(object);
        if (!canceled) visitChildrenRecursively(object);
      }
    }

    bool recursiveObjectVisitor(Object object) {
      canceled = !visitor(object);
      if (!canceled) visitChildrenRecursively(object);
      return !canceled;
    }

    visitChildrenRecursively = (object) {
      if (object is VisitChildrenOfAnyTypeMixin) {
        canceled = !object.visitChildrenOfAnyType(recursiveObjectVisitor);
      } else if (object is RenderObject) {
        object.visitChildren(recursiveRenderObjectVisitor);
      }
    };

    visitChildrenRecursively(this);
    return !canceled;
  }
}

/// Mix this into classes that should implement `visitChildrenOfAnyType`.
mixin VisitChildrenOfAnyTypeMixin {
  /// The implementation should call [visitor] for each immediate child of this
  /// object.
  ///
  /// If [visitor] returns `false` it should return `false` immediately,
  /// canceling the iteration over its children.
  bool visitChildrenOfAnyType(CancelableObjectVisitor visitor);
}
