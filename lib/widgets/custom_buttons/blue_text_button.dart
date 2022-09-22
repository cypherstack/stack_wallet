import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';

class BlueTextButton extends StatefulWidget {
  const BlueTextButton({Key? key, required this.text, this.onTap})
      : super(key: key);

  final String text;
  final VoidCallback? onTap;

  @override
  State<BlueTextButton> createState() => _BlueTextButtonState();
}

class _BlueTextButtonState extends State<BlueTextButton>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<dynamic> animation;
  late Color color;

  @override
  void initState() {
    color = StackTheme.instance.color.buttonTextBorderless;
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    animation = ColorTween(
      begin: StackTheme.instance.color.buttonTextBorderless,
      end: StackTheme.instance.color.buttonTextBorderless.withOpacity(0.4),
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
