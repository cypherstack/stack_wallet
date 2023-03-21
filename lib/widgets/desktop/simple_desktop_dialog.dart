import 'package:flutter/material.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackduo/widgets/desktop/primary_button.dart';

class SimpleDesktopDialog extends StatelessWidget {
  const SimpleDesktopDialog({
    Key? key,
    required this.title,
    required this.message,
  }) : super(key: key);

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxWidth: 500,
      maxHeight: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: STextStyles.desktopH3(context),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: STextStyles.desktopTextSmall(context),
            ),
          ),
          const Spacer(
            flex: 2,
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 32,
              right: 32,
              bottom: 32,
            ),
            child: Row(
              children: [
                const Spacer(),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: PrimaryButton(
                    label: "Ok",
                    buttonHeight: ButtonHeight.l,
                    onPressed: Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pop,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
