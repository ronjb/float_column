# CHANGELOG

## [1.3.3] - January 17, 2023

* Added a `copyWithTextSpan` parameter to the `defaultSplitSpanAtIndex` extension method on the `InlineSpan` class.

## [1.3.2] - January 17, 2023

* Added optional an `bool ignoreFloatedWidgetSpans = false` parameter to the `splitAt` and `splitAtIndex` methods of `SplittableMixin`.

## [1.3.1] - December 10, 2022

* Updated to remove warnings related to latest Flutter version.

## [1.3.0] - July 7, 2022

* Updated `FloatColumn` to support children of type `TextSpan`, `Text`, and `RichText`.

## [1.2.4] - July 6, 2022

* Added `TextOverflow overflow` and `int? maxLines` to `WrappableText` class.

## [1.2.3] - June 28, 2022

* Fixed bug in the RenderObject extension method `visitChildrenAndTextRenderers`. It would not recursively visit children with `VisitChildrenOfAnyTypeMixin`. Now it does.

## [1.2.2] - June 2, 2022

* Code updates to fix warnings related to Flutter 3.0 release.
* Fixed bug related to when `markNeedsSemanticsUpdate` is called. Since it can immediately result in a call to `describeSemanticsConfiguration`, it needed to be moved outside of the loop updating the cached WrappableTextRenderer list.

## [1.2.1] - November 15, 2021

* Fixed bug in RenderFloatColumn assembleSemanticsNode, it was using the `[]` operator of WrappableTextRenderer, when it should have been using the `renderers` getter.

## [1.2.0] - November 15, 2021

* Fixed #3 "WrappableText objects that contain TextSpans that have a recognizer (e.g. TapGestureRecognizer) aren't handled correctly, i.e. the recognizer is ignored for hit tests."
* Updated RenderFloatColumn to support standard `describeSemanticsConfiguration` and `assembleSemanticsNode` methods.

## [1.1.2] - November 13, 2021

* Fixed bug in RenderFloatColumn `visitChildrenOfAnyType`.
* Added example Mac app, and updated examples.

## [1.1.1] - September 9, 2021

* Updated to use `flutter_lints_plus` package and fix Flutter 2.5 lint warnings.

## [1.1.0] - July 5, 2021

* Added support for floated inline widgets using WidgetSpan with Floatable child.

## [1.0.2] - July 4, 2021

* Added code that shows overflow area and size in case of height overflow.

## [1.0.1] - July 4, 2021

* Fixed bug where the layout was incorrect in some cases if line-feed characters were in the text.

## [1.0.0] - June 27, 2021

* Updated README.md and released 1.0.0 version.

## [0.1.5] - May 7, 2021

* Updated so the `textAlign` parameter of WrappableText works correctly.

## [0.1.4] - May 7, 2021

* Updated so negative indent values work correctly.

## [0.1.3] - May 2, 2021

* Added `RenderBox get renderBox` and `Offset get offset` to RenderTextMixin.

## [0.1.2] - May 2, 2021

* Added support for visiting the children (render objects and text renderers) of a RenderFloatColumn, via the `visitChildrenOfAnyType` function.
* Added support for getting detailed info about each text renderer child (via the `RenderTextMixin`), similar to RenderParagraph.
* Fixed a bug relating to WrappableText and unique keys.

## [0.1.1] - May 1, 2021

* Added support for margins and padding to WrappableText and Floatable.

## [0.1.0] - April 26, 2021

* Removed debug print statements, added more examples to readme file.

## [0.1.0-dev.3] - April 26, 2021

* Fixed a bug where a child widget with a width of zero would cause an exception.

## [0.1.0-dev.2] - April 26, 2021

* Fixed a bug where a child widget with an unconstrained width would cause an exception.

## [0.1.0-dev.1] - April 25, 2021

* Prerelease version with basic functionality, and probably a lot of bugs.
