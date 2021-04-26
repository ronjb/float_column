# float_column

A Flutter package for building a vertical column of widgets and text with the ability to "float" child widgets to the left or right, allowing the text to wrap around them -- copying, as closely as possible, the functionality of the CSS `float` and `clear` properties.

![](https://raw.githubusercontent.com/ronjb/float_column/master/example/FloatColumnLTR.gif)

## Getting Started

Add this to your app's `pubspec.yaml` file:

```yaml
dependencies:
  float_column: ^0.1.0
```

## Usage

Then you have to import the package with:

```dart
import 'package:float_column/float_column.dart';
```

And use `FloatColumn` where appropriate:

```dart
FloatColumn(
    // ...
),
```
