# float_column

[![Pub](https://img.shields.io/pub/v/flutter_widget_from_html_core.svg)](https://pub.dev/packages/float_column)

A Flutter package for building a vertical column of widgets and text with the ability to "float" child widgets to the left or right, allowing the text to wrap around them — similar to the functionality of the CSS `float` and `clear` properties.

## Example

![Example with left-to-right text](https://raw.githubusercontent.com/ronjb/float_column/main/example/example_ltr.png)

## Example with right-to-left text

![Example with right-to-left text](https://raw.githubusercontent.com/ronjb/float_column/main/example/example_rtl.png)

## FloatColumn widgets can be floated and nested

![Example with nested FloatColumn widgets](https://raw.githubusercontent.com/ronjb/float_column/main/example/example_nested.png)

## Getting Started

Add this to your app's `pubspec.yaml` file:

```yaml
dependencies:
  float_column: ^0.1.4
```

## Usage

Then you have to import the package with:

```dart
import 'package:float_column/float_column.dart';
```

And use `FloatColumn` where appropriate:

```dart
FloatColumn(
    // See the example app code for a detailed example.
),
```
