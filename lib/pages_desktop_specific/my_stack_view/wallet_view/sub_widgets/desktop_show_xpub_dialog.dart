import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

class DesktopShowXpubDialog extends ConsumerStatefulWidget {
  const DesktopShowXpubDialog({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  static const String routeName = "/desktopShowXpubDialog";

  @override
  ConsumerState<DesktopShowXpubDialog> createState() =>
      _DesktopShowXpubDialog();
}

class _DesktopShowXpubDialog extends ConsumerState<DesktopShowXpubDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxWidth: 580,
      maxHeight: double.infinity,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DesktopDialogCloseButton(
                onPressedOverride: Navigator.of(
                  context,
                  rootNavigator: true,
                ).pop,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  "Wallet Xpub",
                  style: STextStyles.desktopH2(context),
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PrimaryButton(
                        width: 250,
                        buttonHeight: ButtonHeight.xl,
                        label: "Continue",
                        onPressed: Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
