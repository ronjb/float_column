# float_column

[![Pub](https://img.shields.io/pub/v/float_column.svg)](https://pub.dev/packages/float_column)

Flutter FloatColumn widget for building a vertical column of widgets and text where the text wraps around floated widgets, similar to how CSS float works.

Try it out at: [https://ronjb.github.io/float_column](https://ronjb.github.io/float_column)

## Example

You can use it for drop caps and so much more:

![Example with left-to-right text](https://raw.githubusercontent.com/ronjb/float_column/main/example/example_ltr_v2.png)

## Example with right-to-left text

![Example with right-to-left text](https://raw.githubusercontent.com/ronjb/float_column/main/example/example_rtl.png)

## FloatColumn widgets can be floated and nested

![Example with nested FloatColumn widgets](https://raw.githubusercontent.com/ronjb/float_column/main/example/example_nested.png)

## Getting Started

Add this to your app's `pubspec.yaml` file:

```yaml
dependencies:
  float_column: ^2.1.2
```

## Usage

Then you have to import the package with:

```dart
import 'package:float_column/float_column.dart';
```

And use `FloatColumn` where appropriate. For example:

```dart
FloatColumn(
  children: const [
    Floatable(
      float: FCFloat.start,
      padding: EdgeInsets.only(right: 8),
      child: _Box(Text('Box 1')),
    ),
    Floatable(
      float: FCFloat.end,
      clear: FCClear.both,
      clearMinSpacing: 20,
      padding: EdgeInsets.only(left: 8),
      child: _Box(Text('Box 2')),
    ),
    WrappableText(text: 'This text will wrap around the floated widgets...'),
  ],
),
```
