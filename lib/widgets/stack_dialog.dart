import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';

class StackDialogBase extends StatelessWidget {
  const StackDialogBase({
    Key? key,
    this.child,
    this.padding = const EdgeInsets.all(24),
  }) : super(key: key);

  final EdgeInsets padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Material(
            borderRadius: BorderRadius.circular(
              20,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: StackTheme.instance.color.popupBG,
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StackDialog extends StatelessWidget {
  const StackDialog({
    Key? key,
    this.leftButton,
    this.rightButton,
    this.icon,
    required this.title,
    this.message,
  }) : super(key: key);

  final Widget? leftButton;
  final Widget? rightButton;

  final Widget? icon;

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return StackDialogBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: STextStyles.pageTitleH2(context),
                ),
              ),
              icon != null ? icon! : Container(),
            ],
          ),
          if (message != null)
            const SizedBox(
              height: 8,
            ),
          if (message != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message!,
                  style: STextStyles.smallMed14(context),
                ),
              ],
            ),
          if (leftButton != null || rightButton != null)
            const SizedBox(
              height: 20,
            ),
          if (leftButton != null || rightButton != null)
            Row(
              children: [
                leftButton == null
                    ? const Spacer()
                    : Expanded(child: leftButton!),
                const SizedBox(
                  width: 8,
                ),
                rightButton == null
                    ? const Spacer()
                    : Expanded(child: rightButton!),
              ],
            )
        ],
      ),
    );
  }
}

class StackOkDialog extends StatelessWidget {
  const StackOkDialog({
    Key? key,
    this.leftButton,
    this.onOkPressed,
    this.icon,
    required this.title,
    this.message,
  }) : super(key: key);

  final Widget? leftButton;
  final void Function(String)? onOkPressed;

  final Widget? icon;

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return StackDialogBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: STextStyles.pageTitleH2(context),
                ),
              ),
              icon != null ? icon! : Container(),
            ],
          ),
          if (message != null)
            const SizedBox(
              height: 8,
            ),
          if (message != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message!,
                  style: STextStyles.smallMed14(context),
                ),
              ],
            ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              leftButton == null
                  ? const Spacer()
                  : Expanded(child: leftButton!),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOkPressed?.call("OK");
                  },
                  style:
                      StackTheme.instance.getPrimaryEnabledButtonColor(context),
                  child: Text(
                    "Ok",
                    style: STextStyles.button(context),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
