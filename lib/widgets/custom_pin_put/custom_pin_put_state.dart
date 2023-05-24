import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stackwallet/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:stackwallet/widgets/custom_pin_put/pin_keyboard.dart';

class CustomPinPutState extends State<CustomPinPut>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late ValueNotifier<String> _textControllerValue;

  int get selectedIndex => _controller.value.text.length;

  int _pinCount = 0;
  int get pinCount => _pinCount;
  set pinCount(int newCount) {
    _pinCount = newCount;
    widget.onPinLengthChanged?.call(newCount);
  }

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
      // if (pin.length == widget.fieldsCount) {
      // widget.onSubmit?.call(pin);
      // }
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
            width: max((30 * pinCount) - 18, 1),
            child: Stack(
              children: [
                _hiddenTextField,
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _fields(pinCount),
                ),
              ],
            ),
          ),
          Center(
            child: PinKeyboard(
              isRandom: widget.isRandom,
              customKey: widget.customKey,
              onNumberKeyPressed: (number) {
                _controller.text += number;

                // add a set state and have the counter increment
                setState(() {
                  pinCount = _controller.text.length;
                });
              },
              onBackPressed: () {
                final text = _controller.text;
                if (text.isNotEmpty) {
                  _controller.text = text.substring(0, text.length - 1);
                  setState(() {
                    pinCount = _controller.text.length;
                  });
                }
                // decrement counter here
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
      maxLength: 10,
      showCursor: false,
      scrollPadding: EdgeInsets.zero,
      decoration: widget.inputDecoration,
      style: widget.textStyle != null
          ? widget.textStyle!.copyWith(color: Colors.transparent)
          : const TextStyle(color: Colors.transparent),
    );
  }

  // have it include an int as a param
  Widget _fields(int count) {
    return ValueListenableBuilder<String>(
      valueListenable: _textControllerValue,
      builder: (BuildContext context, value, Widget? child) {
        return Row(
          mainAxisSize: widget.mainAxisSize,
          mainAxisAlignment: widget.fieldsAlignment,
          children: _buildFieldsWithSeparator(count),
        );
      },
    );
  }

  List<Widget> _buildFieldsWithSeparator(int count) {
    final fields = Iterable<int>.generate(count).map((index) {
      return _getField(index);
    }).toList();

    return fields;
  }

  Widget _getField(int index) {
    final String pin = _controller.value.text;
    return AnimatedContainer(
      width: widget.eachFieldWidth,
      height: widget.eachFieldHeight,
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
