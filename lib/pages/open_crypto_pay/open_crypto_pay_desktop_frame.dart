import 'package:flutter/material.dart';

import '../../utilities/text_styles.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';

class OpenCryptoPayDesktopFrame extends StatelessWidget {
  const OpenCryptoPayDesktopFrame({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height - 64,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(title, style: STextStyles.desktopH3(context)),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}
