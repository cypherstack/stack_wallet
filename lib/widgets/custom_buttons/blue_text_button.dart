import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class _CustomTextButton extends StatefulWidget {
  const _CustomTextButton({
    Key? key,
    required this.text,
    required this.enabledColor,
    required this.disabledColor,
    this.onTap,
    this.enabled = true,
    this.textSize,
  }) : super(key: key);

  final String text;
  final VoidCallback? onTap;
  final bool enabled;
  final double? textSize;
  final Color enabledColor;
  final Color disabledColor;

  @override
  State<_CustomTextButton> createState() => _CustomTextButtonState();
}

class _CustomTextButtonState extends State<_CustomTextButton>
    with SingleTickerProviderStateMixin {
  AnimationController? controller;
  Animation<dynamic>? animation;
  late Color color;

  bool _hovering = false;

  @override
  void initState() {
    if (widget.enabled) {
      color = widget.enabledColor;
      controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
      );
      animation = ColorTween(
        begin: widget.enabledColor,
        end: widget.enabledColor.withOpacity(0.4),
      ).animate(controller!);

      animation!.addListener(() {
        setState(() {
          color = animation!.value as Color;
        });
      });
    } else {
      color = widget.disabledColor;
    }

    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: RoundedContainer(
              radiusMultiplier: 20,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .highlight
                  .withOpacity(_hovering ? 0.3 : 0),
              child: child,
            ),
          ),
        );
      },
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: widget.text,
          style: widget.textSize == null
              ? STextStyles.link2(context).copyWith(
                  color: color,
                )
              : STextStyles.link2(context).copyWith(
                  color: color,
                  fontSize: widget.textSize,
                ),
          recognizer: widget.enabled
              ? (TapGestureRecognizer()
                ..onTap = () {
                  widget.onTap?.call();
                  controller?.forward().then((value) => controller?.reverse());
                })
              : null,
        ),
      ),
    );
  }
}

class CustomTextButton extends StatelessWidget {
  const CustomTextButton({
    Key? key,
    required this.text,
    this.onTap,
    this.enabled = true,
    this.textSize,
  }) : super(key: key);

  final String text;
  final VoidCallback? onTap;
  final bool enabled;
  final double? textSize;

  @override
  Widget build(BuildContext context) {
    return _CustomTextButton(
      key: UniqueKey(),
      text: text,
      enabledColor:
          Theme.of(context).extension<StackColors>()!.buttonTextBorderless,
      disabledColor: Theme.of(context).extension<StackColors>()!.textSubtitle1,
      enabled: enabled,
      textSize: textSize,
      onTap: onTap,
    );
  }
}
