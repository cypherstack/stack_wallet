import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class MnemonicTableItem extends StatelessWidget {
  const MnemonicTableItem({
    Key? key,
    required this.number,
    required this.word,
  }) : super(key: key);

  final int number;
  final String word;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Container(
      decoration: BoxDecoration(
        color: CFColors.white,
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              number.toString(),
              style: STextStyles.baseXS.copyWith(
                color: CFColors.gray3,
                fontSize: 10,
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              word,
              style: STextStyles.baseXS,
            ),
          ],
        ),
      ),
    );
  }
}
