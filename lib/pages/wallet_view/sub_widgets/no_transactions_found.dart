import 'package:flutter/cupertino.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/widgets/rounded_white_container.dart';

class NoTransActionsFound extends StatelessWidget {
  const NoTransActionsFound({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoundedWhiteContainer(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "Transactions will appear here",
              style: STextStyles.itemSubtitle(context),
            ),
          ),
        ),
      ],
    );
  }
}
