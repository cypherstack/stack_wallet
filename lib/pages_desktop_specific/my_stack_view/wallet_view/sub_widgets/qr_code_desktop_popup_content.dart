import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog_close_button.dart';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              DesktopDialogCloseButton(),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          QrImage(
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
