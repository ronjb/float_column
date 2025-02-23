# RenderParagraph Public Interface

## Properties

| **Property**                      | **Description**                                                                               |
|-----------------------------------|-----------------------------------------------------------------------------------------------|
| **text**                          | The [InlineSpan] representing the text content.                                               |
| **textAlign**                     | The horizontal alignment setting for the text.                                                |
| **textDirection**                 | The text direction (LTR or RTL).                                                              |
| **softWrap**                      | Boolean flag indicating if the text should wrap at soft line breaks.                          |
| **overflow**                      | Specifies how to handle text that exceeds available space (e.g., clip, ellipsis, fade).       |
| **textScaleFactor / textScaler**  | Controls the scaling of the text (*textScaleFactor* is deprecated in favor of *textScaler*).  |
| **maxLines**                      | Maximum number of lines before the text is truncated.                                         |
| **locale**                        | The locale used for selecting locale-specific fonts and layout.                               |
| **strutStyle**                    | Provides style information (like line height) for vertical text layout.                       |
| **textWidthBasis**                | Determines whether width is based on the parent's constraints or intrinsic text size.         |
| **textHeightBehavior**            | Configures how the text's height is computed, affecting line spacing.                         |
| **selectionColor**                | Color used for text selection (when selection is enabled).                                    |
| **preferredLineHeight**           | An estimate of the height of a single line of text.                                           |
| **textSize**                      | The actual size of the laid-out text, as computed by the internal TextPainter.                |
| **didExceedMaxLines**             | Boolean indicating if the text was truncated or ellipsized due to exceeding max lines.        |

## Methods

| **Method**                                                                 | **Description**                                                                                                               |
|----------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|
| **getOffsetForCaret(TextPosition, Rect)**                                  | Returns the offset at which to paint the caret for a given text position.                                                     |
| **getFullHeightForCaret(TextPosition)**                                    | Provides the full height (including extra spacing) for the caret at the specified position.                                   |
| **getBoxesForSelection(TextSelection, { boxHeightStyle, boxWidthStyle })** | Returns a list of [TextBox]es that bound the given selection, useful when the selection spans multiple lines or inline spans. |
| **getPositionForOffset(Offset)**                                           | Determines the [TextPosition] within the text corresponding to a given pixel offset.                                          |
| **getWordBoundary(TextPosition)**                                          | Returns a [TextRange] representing the boundaries of the word at the given text position.                                     |

Additionally, RenderParagraph inherits intrinsic measurement methods from RenderBox (such as `computeMinIntrinsicWidth` and `computeMaxIntrinsicWidth`) which can be used to understand its sizing behavior.