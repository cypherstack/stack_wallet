import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class WordTableItem extends ConsumerWidget {
  const WordTableItem({
    Key? key,
    required this.number,
    required this.word,
  }) : super(key: key);

  final int number;
  final String word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: $runtimeType");
    final selectedWord =
        ref.watch(verifyMnemonicSelectedWordStateProvider.state).state;
    return Container(
      decoration: BoxDecoration(
        color: selectedWord == word ? CFColors.selection : CFColors.white,
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius,
        ),
      ),
      child: MaterialButton(
        splashColor: CFColors.splashLight,
        key: Key("coinSelectItemButtonKey_$word"),
        padding: const EdgeInsets.all(12),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(Constants.size.circularBorderRadius),
        ),
        onPressed: () {
          ref.read(verifyMnemonicSelectedWordStateProvider.state).state = word;
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word,
              textAlign: TextAlign.center,
              style: STextStyles.baseXS,
            ),
          ],
        ),
      ),
    );
  }
}
