import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/desktop/primary_button.dart';
import 'package:flutter/material.dart';

class StackDialogBase extends StatelessWidget {
  const StackDialogBase({
    Key? key,
    this.child,
    this.padding = const EdgeInsets.all(24),
    this.mainAxisAlignment = MainAxisAlignment.end,
  }) : super(key: key);

  final EdgeInsets padding;
  final Widget? child;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(
              20,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).extension<StackColors>()!.popupBG,
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

class OkDialog extends StatelessWidget {
  const OkDialog({
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
      mainAxisAlignment: MainAxisAlignment.center,
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
                child: PrimaryButton(
                  label: "OK",
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOkPressed?.call("OK");
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
