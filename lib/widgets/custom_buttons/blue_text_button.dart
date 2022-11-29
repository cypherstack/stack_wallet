import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/providers/ui/color_theme_provider.dart';
import 'package:epicmobile/utilities/text_styles.dart';

class BlueTextButton extends ConsumerStatefulWidget {
  const BlueTextButton({
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
  ConsumerState<BlueTextButton> createState() => _BlueTextButtonState();
}

class _BlueTextButtonState extends ConsumerState<BlueTextButton>
    with SingleTickerProviderStateMixin {
  AnimationController? controller;
  Animation<dynamic>? animation;
  late Color color;

  @override
  void initState() {
    if (widget.enabled) {
      color = ref.read(colorThemeProvider.state).state.buttonTextBorderless;
      controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
      );
      animation = ColorTween(
        begin: ref.read(colorThemeProvider.state).state.buttonTextBorderless,
        end: ref
            .read(colorThemeProvider.state)
            .state
            .buttonTextBorderless
            .withOpacity(0.4),
      ).animate(controller!);

      animation!.addListener(() {
        setState(() {
          color = animation!.value as Color;
        });
      });
    } else {
      color = ref.read(colorThemeProvider.state).state.textSubtitle1;
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
    return RichText(
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
    );
  }
}
