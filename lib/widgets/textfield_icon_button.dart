import 'package:flutter/material.dart';

class TextFieldIconButton extends StatefulWidget {
  const TextFieldIconButton({
    Key? key,
    this.width = 40,
    this.height = 40,
    this.onTap,
    required this.child,
    this.color = Colors.transparent,
    this.label = "Button",
  }) : super(key: key);

  final double width;
  final double height;
  final VoidCallback? onTap;
  final Widget child;
  final Color color;
  final String label;

  @override
  State<TextFieldIconButton> createState() => _TextFieldIconButtonState();
}

class _TextFieldIconButtonState extends State<TextFieldIconButton> {
  late final VoidCallback? onTap;

  @override
  void initState() {
    onTap = widget.onTap;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Semantics(
          label: widget.label,
          excludeSemantics: true,
          child: RawMaterialButton(
            constraints: BoxConstraints(
              minWidth: widget.width,
              minHeight: widget.height,
            ),
            onPressed: onTap,
            child: Container(
              width: widget.width,
              height: widget.height,
              color: widget.color,
              child: Center(
                child: widget.child,
              ),
            ),
          ),
        )
      ),
    );
  }
}
