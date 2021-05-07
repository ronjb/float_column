# CHANGELOG

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
