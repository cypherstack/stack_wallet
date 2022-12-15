import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:epicpay/widgets/custom_pin_put/pin_keyboard.dart';
import 'package:flutter/material.dart';

class CustomPinPutState extends State<CustomPinPut>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late ValueNotifier<String> _textControllerValue;

  int get selectedIndex => _controller.value.text.length;

  @override
  void initState() {
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _textControllerValue = ValueNotifier<String>(_controller.value.text);
    _controller.addListener(_textChangeListener);
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  void _textChangeListener() {
    final pin = _controller.value.text;
    if (pin != _textControllerValue.value) {
      try {
        _textControllerValue.value = pin;
      } catch (e) {
        _textControllerValue = ValueNotifier(_controller.value.text);
      }
      if (pin.length == widget.fieldsCount) {
        widget.onSubmit?.call(pin);
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();

    _textControllerValue.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Column(
        children: [
          SizedBox(
            width: (56 * widget.fieldsCount) - 36,
            child: Stack(
              children: [
                _hiddenTextField,
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _fields,
                ),
              ],
            ),
          ),
          if (MediaQuery.of(context).size.height > 600)
            const SizedBox(
              height: 32,
            ),
          Center(
            child: PinKeyboard(
              onNumberKeyPressed: (number) {
                if (_controller.text.length < widget.fieldsCount) {
                  _controller.text += number;
                }
              },
              onBackPressed: () {
                final text = _controller.text;
                if (text.isNotEmpty) {
                  _controller.text = text.substring(0, text.length - 1);
                }
              },
              onSubmitPressed: () {
                final pin = _controller.value.text;
                widget.onSubmit?.call(pin);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget get _hiddenTextField {
    return TextFormField(
      controller: _controller,
      onSaved: widget.onSaved,
      onChanged: widget.onChanged,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      textInputAction: widget.textInputAction,
      focusNode: _focusNode,
      enabled: widget.enabled,
      enableSuggestions: false,
      autofocus: widget.autofocus,
      readOnly: true,
      obscureText: widget.obscureText != null,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      keyboardAppearance: widget.keyboardAppearance,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      enableInteractiveSelection: false,
      maxLength: widget.fieldsCount,
      showCursor: false,
      scrollPadding: EdgeInsets.zero,
      decoration: widget.inputDecoration,
      style: widget.textStyle != null
          ? widget.textStyle!.copyWith(color: Colors.transparent)
          : const TextStyle(color: Colors.transparent),
    );
  }

  Widget get _fields {
    return ValueListenableBuilder<String>(
      valueListenable: _textControllerValue,
      builder: (BuildContext context, value, Widget? child) {
        return Row(
          mainAxisSize: widget.mainAxisSize,
          mainAxisAlignment: widget.fieldsAlignment,
          children: _buildFieldsWithSeparator(),
        );
      },
    );
  }

  List<Widget> _buildFieldsWithSeparator() {
    final fields = Iterable<int>.generate(widget.fieldsCount).map((index) {
      return _getField(index);
    }).toList();

    return fields;
  }

  double _size(int index) {
    if (!widget.enabled) return 0;
    if (index < selectedIndex &&
        (_focusNode.hasFocus || !widget.useNativeKeyboard)) {
      return 0;
    }
    if (index == selectedIndex &&
        (_focusNode.hasFocus || !widget.useNativeKeyboard)) {
      return 16;
    }
    return 16;
  }

  Color _getColor(int index) {
    if (!widget.enabled) {
      return Colors.transparent;
    }
    if (index < selectedIndex &&
        (_focusNode.hasFocus || !widget.useNativeKeyboard)) {
      return Colors.transparent;
    }
    if (index == selectedIndex &&
        (_focusNode.hasFocus || !widget.useNativeKeyboard)) {
      return Theme.of(context).extension<StackColors>()!.textLight;
    }
    return Theme.of(context).extension<StackColors>()!.textLight;
  }

  Widget _getField(int index) {
    final String pin = _controller.value.text;
    return Column(
      children: [
        AnimatedContainer(
          width: 16,
          height: 16,
          alignment: widget.eachFieldAlignment,
          duration: widget.animationDuration,
          curve: widget.animationCurve,
          padding: widget.eachFieldPadding,
          margin: widget.eachFieldMargin,
          constraints: widget.eachFieldConstraints,
          decoration: _fieldDecoration(index),
          child: AnimatedSwitcher(
            switchInCurve: widget.animationCurve,
            switchOutCurve: widget.animationCurve,
            duration: widget.animationDuration,
            transitionBuilder: (child, animation) {
              return _getTransition(child, animation);
            },
            child: _buildFieldContent(index, pin),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        AnimatedContainer(
          width: _size(index),
          color: _getColor(index),
          height: 1,
          alignment: widget.eachFieldAlignment,
          duration: widget.animationDuration,
          curve: widget.animationCurve,
        ),
      ],
    );
  }

  Widget _buildFieldContent(int index, String pin) {
    if (index < pin.length) {
      return Text(
        widget.obscureText ?? pin[index],
        key: ValueKey<String>(index < pin.length ? pin[index] : ''),
        style: widget.textStyle,
      );
    }

    return Text(
      '',
      key: ValueKey<String>(index < pin.length ? pin[index] : ''),
      style: widget.textStyle,
    );
  }

  BoxDecoration? _fieldDecoration(int index) {
    if (!widget.enabled) return widget.disabledDecoration;
    if (index < selectedIndex &&
        (_focusNode.hasFocus || !widget.useNativeKeyboard)) {
      return widget.submittedFieldDecoration;
    }
    if (index == selectedIndex &&
        (_focusNode.hasFocus || !widget.useNativeKeyboard)) {
      return widget.selectedFieldDecoration;
    }
    return widget.followingFieldDecoration;
  }

  Widget _getTransition(Widget child, Animation<dynamic> animation) {
    switch (widget.pinAnimationType) {
      case PinAnimationType.none:
        return child;
      case PinAnimationType.fade:
        return FadeTransition(
          opacity: animation as Animation<double>,
          child: child,
        );
      case PinAnimationType.scale:
        return ScaleTransition(
          scale: animation as Animation<double>,
          child: child,
        );
      case PinAnimationType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: widget.slideTransitionBeginOffset ?? const Offset(0.8, 0),
            end: Offset.zero,
          ).animate(animation as Animation<double>),
          child: child,
        );
      case PinAnimationType.rotation:
        return RotationTransition(
          turns: animation as Animation<double>,
          child: child,
        );
    }
  }
}
