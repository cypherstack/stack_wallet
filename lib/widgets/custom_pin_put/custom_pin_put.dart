import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stackwallet/widgets/custom_pin_put/custom_pin_put_state.dart';
import 'package:stackwallet/widgets/custom_pin_put/pin_keyboard.dart';

class CustomPinPut extends StatefulWidget {
  const CustomPinPut({
    Key? key,
    required this.fieldsCount,
    required this.isRandom,
    this.height,
    this.width,
    this.onSubmit,
    this.onSaved,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.separator = const SizedBox(width: 15.0),
    this.textStyle,
    this.submittedFieldDecoration,
    this.selectedFieldDecoration,
    this.followingFieldDecoration,
    this.disabledDecoration,
    this.eachFieldWidth,
    this.eachFieldHeight,
    this.fieldsAlignment = MainAxisAlignment.spaceBetween,
    this.eachFieldAlignment = Alignment.center,
    this.eachFieldMargin,
    this.eachFieldPadding,
    this.eachFieldConstraints =
        const BoxConstraints(minHeight: 10.0, minWidth: 10.0),
    this.inputDecoration = const InputDecoration(
      contentPadding: EdgeInsets.zero,
      border: InputBorder.none,
      counterText: '',
    ),
    this.animationCurve = Curves.linear,
    this.animationDuration = const Duration(milliseconds: 160),
    this.pinAnimationType = PinAnimationType.slide,
    this.slideTransitionBeginOffset,
    this.enabled = true,
    this.useNativeKeyboard = true,
    this.autofocus = false,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.keyboardAppearance,
    this.inputFormatters,
    this.validator,
    this.keyboardType = TextInputType.number,
    this.obscureText,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.toolbarOptions,
    this.mainAxisSize = MainAxisSize.max,
    this.autofillHints,
    this.customKey,
    this.onPinLengthChanged,
  }) : super(key: key);

  final void Function(int)? onPinLengthChanged;

  final double? width;
  final double? height;

  final CustomKey? customKey;

  final bool isRandom;

  /// Displayed fields count. PIN code length.
  final int fieldsCount;

  /// Same as FormField onFieldSubmitted, called when PinPut submitted.
  final ValueChanged<String>? onSubmit;

  /// Signature for being notified when a form field changes value.
  final FormFieldSetter<String>? onSaved;

  /// Called every time input value changes.
  final ValueChanged<String>? onChanged;

  /// Used to get, modify PinPut value and more.
  final TextEditingController? controller;

  /// Defines the keyboard focus for this widget.
  /// To give the keyboard focus to this widget, provide a [focusNode] and then
  /// use the current [FocusScope] to request the focus:
  final FocusNode? focusNode;

  /// Builds a PinPut separator
  final Widget? separator;

  /// The style to use for PinPut
  /// If null, defaults to the `subhead` text style from the current [Theme].
  final TextStyle? textStyle;

  ///  Box decoration of following properties of [CustomPinPut]
  ///  [submittedFieldDecoration] [selectedFieldDecoration] [followingFieldDecoration] [disabledDecoration]
  ///  You can customize every pixel with it
  ///  properties are being animated implicitly when value changes
  ///  ```dart
  ///  this.color,
  ///  this.image,
  ///  this.border,
  ///  this.borderRadius,
  ///  this.boxShadow,
  ///  this.gradient,
  ///  this.backgroundBlendMode,
  ///  this.shape = BoxShape.rectangle,
  ///  ```

  /// The decoration of each [CustomPinPut] submitted field
  final BoxDecoration? submittedFieldDecoration;

  /// The decoration of [CustomPinPut] currently selected field
  final BoxDecoration? selectedFieldDecoration;

  /// The decoration of each [CustomPinPut] following field
  final BoxDecoration? followingFieldDecoration;

  /// The decoration of each [CustomPinPut] field when [CustomPinPut] ise disabled
  final BoxDecoration? disabledDecoration;

  /// width of each [CustomPinPut] field
  final double? eachFieldWidth;

  /// height of each [CustomPinPut] field
  final double? eachFieldHeight;

  /// Defines how [CustomPinPut] fields are being placed inside [Row]
  final MainAxisAlignment fieldsAlignment;

  /// Defines how each [CustomPinPut] field are being placed within the container
  final AlignmentGeometry eachFieldAlignment;

  /// Empty space to surround the [CustomPinPut] field container.
  final EdgeInsetsGeometry? eachFieldMargin;

  /// Empty space to inscribe the [CustomPinPut] field container.
  /// For example space between border and text
  final EdgeInsetsGeometry? eachFieldPadding;

  /// Additional constraints to apply to the each field container.
  /// properties
  /// ```dart
  ///  this.minWidth = 0.0,
  ///  this.maxWidth = double.infinity,
  ///  this.minHeight = 0.0,
  ///  this.maxHeight = double.infinity,
  ///  ```
  final BoxConstraints eachFieldConstraints;

  /// The decoration to show around the text [CustomPinPut].
  ///
  /// can be configured to show an icon, border,counter, label, hint text, and error text.
  /// set counterText to '' to remove bottom padding entirely
  final InputDecoration inputDecoration;

  /// curve of every [CustomPinPut] Animation
  final Curve animationCurve;

  /// Duration of every [CustomPinPut] Animation
  final Duration animationDuration;

  /// Animation Type of each [CustomPinPut] field
  /// options:
  /// none, scale, fade, slide, rotation
  final PinAnimationType pinAnimationType;

  /// Begin Offset of ever [CustomPinPut] field when [pinAnimationType] is slide
  final Offset? slideTransitionBeginOffset;

  /// Defines [CustomPinPut] state
  final bool enabled;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// Whether we use Native keyboard or custom `Numpad`
  /// when flag is set to false [CustomPinPut] wont be focusable anymore
  /// so you should set value of [CustomPinPut]'s [TextEditingController] programmatically
  final bool useNativeKeyboard;

  /// If true [validator] function is called when [CustomPinPut] value changes
  /// alternatively you can use [GlobalKey]
  /// ```dart
  ///   final _formKey = GlobalKey<FormState>();
  ///   _formKey.currentState.validate()
  /// ```
  final AutovalidateMode autovalidateMode;

  /// The appearance of the keyboard.
  /// This setting is only honored on iOS devices.
  final Brightness? keyboardAppearance;

  /// {@macro flutter.widgets.editableText.inputFormatters}
  final List<TextInputFormatter>? inputFormatters;

  /// An optional method that validates an input. Returns an error string to
  /// display if the input is invalid, or null otherwise.
  ///
  /// The returned value is exposed by the [FormFieldState.errorText] property.
  /// The [TextFormField] uses this to override the [InputDecoration.errorText]
  /// value.
  ///
  /// Alternating between error and normal state can cause the height of the
  /// [TextFormField] to change if no other subtext decoration is set on the
  /// field. To create a field whose height is fixed regardless of whether or
  /// not an error is displayed, either wrap the  [TextFormField] in a fixed
  /// height parent like [SizedBox], or set the [TextFormField.helperText]
  /// parameter to a space.
  final FormFieldValidator<String>? validator;

  /// {@macro flutter.widgets.editableText.keyboardType}
  final TextInputType keyboardType;

  /// Provide any symbol to obscure each [CustomPinPut] field
  /// Recommended ●
  final String? obscureText;

  /// {@macro flutter.widgets.editableText.textCapitalization}
  final TextCapitalization textCapitalization;

  /// The type of action button to use for the keyboard.
  ///
  /// Defaults to [TextInputAction.newline] if [keyboardType] is
  /// [TextInputType.multiline] and [TextInputAction.done] otherwise.
  final TextInputAction? textInputAction;

  /// Configuration of toolbar options.
  ///
  /// If not set, select all and paste will default to be enabled. Copy and cut
  /// will be disabled if [obscureText] is true. If [readOnly] is true,
  /// paste and cut will be disabled regardless.
  final ToolbarOptions? toolbarOptions;

  /// Maximize the amount of free space along the main axis.
  final MainAxisSize mainAxisSize;

  /// lists of auto fill hints
  final Iterable<String>? autofillHints;

  @override
  CustomPinPutState createState() => CustomPinPutState();
}

enum PinAnimationType {
  none,
  scale,
  fade,
  slide,
  rotation,
}
