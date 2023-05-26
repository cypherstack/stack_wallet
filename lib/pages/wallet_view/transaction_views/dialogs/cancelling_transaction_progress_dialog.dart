import 'package:flutter/material.dart';
import 'package:stackwallet/widgets/animated_widgets/rotating_arrows.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class CancellingTransactionProgressDialog extends StatefulWidget {
  const CancellingTransactionProgressDialog({Key? key}) : super(key: key);

  @override
  State<CancellingTransactionProgressDialog> createState() =>
      _CancellingTransactionProgressDialogState();
}

class _CancellingTransactionProgressDialogState
    extends State<CancellingTransactionProgressDialog> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: const StackDialog(
        title: "Cancelling transaction",
        message: "This may take a while. Please do not exit this screen.",
        icon: RotatingArrows(
          width: 24,
          height: 24,
        ),
        // rightButton: TextButton(
        //   style: Theme.of(context).textButtonTheme.style?.copyWith(
        //     backgroundColor: MaterialStateProperty.all<Color>(
        //       CFColors.buttonGray,
        //     ),
        //   ),
        //   child: Text(
        //     "Cancel",
        //     style: STextStyles.itemSubtitle12(context),
        //   ),
        //   onPressed: () {
        //     Navigator.of(context).pop();
        //     onCancel.call();
        //   },
        // ),
      ),
    );
  }
}
