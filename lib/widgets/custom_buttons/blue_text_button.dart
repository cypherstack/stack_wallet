import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/ui/color_theme_provider.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class BlueTextButton extends ConsumerStatefulWidget {
  const BlueTextButton({Key? key, required this.text, this.onTap})
      : super(key: key);

  final String text;
  final VoidCallback? onTap;

  @override
  ConsumerState<BlueTextButton> createState() => _BlueTextButtonState();
}

class _BlueTextButtonState extends ConsumerState<BlueTextButton>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<dynamic> animation;
  late Color color;

  @override
  void initState() {
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
    ).animate(controller);

    animation.addListener(() {
      setState(() {
        color = animation.value as Color;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: widget.text,
        style: STextStyles.link2(context).copyWith(color: color),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            widget.onTap?.call();
            controller.forward().then((value) => controller.reverse());
          },
      ),
    );
  }
}
