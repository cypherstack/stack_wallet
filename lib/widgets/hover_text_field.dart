import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';

class HoverTextField extends StatefulWidget {
  const HoverTextField({
    Key? key,
    this.controller,
    this.focusNode,
    this.readOnly = false,
    this.enabled,
    this.onTap,
    this.onChanged,
    this.onEditingComplete,
    this.style,
    this.onDone,
  }) : super(key: key);

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool readOnly;
  final bool? enabled;
  final GestureTapCallback? onTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final TextStyle? style;
  final VoidCallback? onDone;

  @override
  State<HoverTextField> createState() => _HoverTextFieldState();
}

class _HoverTextFieldState extends State<HoverTextField> {
  late final TextEditingController? controller;
  late final FocusNode? focusNode;
  late bool readOnly;
  late bool? enabled;
  late final GestureTapCallback? onTap;
  late final ValueChanged<String>? onChanged;
  late final VoidCallback? onEditingComplete;
  late final TextStyle? style;
  late final VoidCallback? onDone;

  final InputBorder inputBorder = OutlineInputBorder(
    borderSide: const BorderSide(
      width: 0,
      color: Colors.transparent,
    ),
    borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
  );

  @override
  void initState() {
    controller = widget.controller;
    focusNode = widget.focusNode ?? FocusNode();
    readOnly = widget.readOnly;
    enabled = widget.enabled;
    onChanged = widget.onChanged;
    style = widget.style;
    onTap = widget.onTap;
    onEditingComplete = widget.onEditingComplete;
    onDone = widget.onDone;

    focusNode!.addListener(() {
      if (!focusNode!.hasPrimaryFocus && !readOnly) {
        setState(() {
          readOnly = true;
        });
        onDone?.call();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    focusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      autocorrect: !Util.isDesktop,
      enableSuggestions: !Util.isDesktop,
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      enabled: enabled,
      onTap: () {
        setState(() {
          readOnly = false;
        });
        onTap?.call();
      },
      onChanged: onChanged,
      onEditingComplete: () {
        setState(() {
          readOnly = true;
        });
        onEditingComplete?.call();
        onDone?.call();
      },
      style: style,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 12,
        ),
        border: inputBorder,
        focusedBorder: inputBorder,
        disabledBorder: inputBorder,
        enabledBorder: inputBorder,
        errorBorder: inputBorder,
        fillColor: readOnly
            ? Colors.transparent
            : Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
      ),
    );
  }
}
