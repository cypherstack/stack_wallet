import 'package:flutter/cupertino.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class NoTokensFound extends StatelessWidget {
  const NoTokensFound({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoundedWhiteContainer(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "You do not have any tokens",
              style: STextStyles.itemSubtitle(context),
            ),
          ),
        ),
      ],
    );
  }
}
