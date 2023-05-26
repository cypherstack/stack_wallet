import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomMaterialTextSelectionControls
    extends MaterialTextSelectionControls {
  CustomMaterialTextSelectionControls({required this.onPaste});
  ValueChanged<TextSelectionDelegate> onPaste;
  @override
  Future<void> handlePaste(final TextSelectionDelegate delegate) async {
    return onPaste(delegate);
  }
}

class CustomCupertinoTextSelectionControls
    extends CupertinoTextSelectionControls {
  CustomCupertinoTextSelectionControls({required this.onPaste});
  ValueChanged<TextSelectionDelegate> onPaste;
  @override
  Future<void> handlePaste(final TextSelectionDelegate delegate) async {
    return onPaste(delegate);
  }
}
