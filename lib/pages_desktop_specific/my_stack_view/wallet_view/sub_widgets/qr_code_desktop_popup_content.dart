import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';

class QRCodeDesktopPopupContent extends StatelessWidget {
  const QRCodeDesktopPopupContent({
    Key? key,
    required this.value,
  }) : super(key: key);

  final String value;

  static const String routeName = "qrCodeDesktopPopupContent";

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxWidth: 614,
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DesktopDialogCloseButton(),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          QrImageView(
            data: value,
            size: 300,
            foregroundColor:
                Theme.of(context).extension<StackColors>()!.accentColorDark,
          ),
        ],
      ),
    );
  }
}
