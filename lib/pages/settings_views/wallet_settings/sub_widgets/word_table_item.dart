import 'package:epicpay/utilities/constants.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:flutter/material.dart';

class WordTableItem extends StatelessWidget {
  const WordTableItem({
    Key? key,
    required this.number,
    required this.word,
    this.onPressed,
  }) : super(key: key);

  final int number;
  final String word;
  final void Function(String)? onPressed;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).extension<StackColors>()!.coal,
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius,
        ),
      ),
      child: MaterialButton(
        splashColor: Theme.of(context).extension<StackColors>()!.highlight,
        key: Key("coinSelectItemButtonKey_$word"),
        padding: const EdgeInsets.all(8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(Constants.size.circularBorderRadius),
        ),
        onPressed: () {
          onPressed?.call(word);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word,
              textAlign: TextAlign.center,
              style: STextStyles.bodySmallBold(context),
            ),
          ],
        ),
      ),
    );
  }
}
